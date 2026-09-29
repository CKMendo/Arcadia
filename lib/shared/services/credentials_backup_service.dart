import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for multi-layer persistent backup and self-healing restoration
/// of all API keys, GitHub tokens, and custom website URLs.
///
/// Storage layers:
/// 1. SharedPreferences (fast in-memory / cache layer)
/// 2. Application Documents Directory (`arcadia_credentials_backup.json`)
/// 3. External App Storage Directory (`${extDir.path}/arcadia_credentials_backup.json`)
/// 4. Android Download Directory (`/sdcard/Download/arcadia_credentials_backup.json`, survives full app uninstalls)
class CredentialsBackupService {
  static const String backupFileName = 'arcadia_credentials_backup.json';

  // Supported keys
  static const String keyGitHubToken = 'github_personal_access_token';
  static const String keyGeminiApiKey = 'gemini_api_key';
  static const String keyGeminiSecondaryApiKey = 'gemini_secondary_api_key';
  static const String keyWebsiteUrl = 'website_url';
  static const String keyTinyUrl = 'tiny_url';

  static const List<String> allManagedKeys = [
    keyGitHubToken,
    keyGeminiApiKey,
    keyGeminiSecondaryApiKey,
    keyWebsiteUrl,
    keyTinyUrl,
  ];

  static Map<String, String>? _testMemoryCredentials;

  static bool get _isTestEnv => Platform.environment['FLUTTER_TEST'] == 'true';

  @visibleForTesting
  static void resetTestMemory() {
    _testMemoryCredentials = null;
  }

  static Future<SharedPreferences?> _getPrefsSafely() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  /// Saves a single credential to SharedPreferences and updates the persistent
  /// backup files across all available device storage layers.
  static Future<bool> setCredential(String key, String? value) async {
    final clean = value?.trim();

    // In-memory test environment fast-path
    if (_isTestEnv) {
      _testMemoryCredentials ??= {};
      if (clean == null || clean.isEmpty) {
        _testMemoryCredentials!.remove(key);
      } else {
        _testMemoryCredentials![key] = clean;
      }
      final prefs = await _getPrefsSafely();
      if (prefs != null) {
        if (clean == null || clean.isEmpty) {
          await prefs.remove(key);
        } else {
          await prefs.setString(key, clean);
        }
      }
      return true;
    }

    try {
      // 1. SharedPreferences
      final prefs = await _getPrefsSafely();
      if (prefs != null) {
        if (clean == null || clean.isEmpty) {
          await prefs.remove(key);
        } else {
          await prefs.setString(key, clean);
        }
      }

      // 2. Load existing backup from file layers to preserve other credentials
      final existing = await _loadRawBackupFromFileLayers() ?? {};
      final creds = Map<String, dynamic>.from(
        (existing['credentials'] as Map<dynamic, dynamic>?) ?? {},
      );

      if (clean == null || clean.isEmpty) {
        creds.remove(key);
      } else {
        creds[key] = clean;
      }

      // Re-populate from prefs for any keys not in file
      if (prefs != null) {
        for (final k in allManagedKeys) {
          final pVal = prefs.getString(k)?.trim();
          if (pVal != null && pVal.isNotEmpty && !creds.containsKey(k)) {
            creds[k] = pVal;
          }
        }
      }

      final now = DateTime.now();
      final payload = {
        'version': 1,
        'timestamp': now.millisecondsSinceEpoch,
        'updatedAt': now.toIso8601String(),
        'credentials': creds,
      };

      final jsonStr = jsonEncode(payload);

      // Write to multi-layer persistent files
      await _writeToAllStorageLayers(jsonStr);
      return true;
    } catch (e) {
      debugPrint('[CredentialsBackupService] Error saving credential $key: $e');
      return false;
    }
  }

  /// Retrieves a credential. If missing in SharedPreferences (e.g. after an app update/reinstall),
  /// it automatically self-heals by loading from the persistent device backup files and restoring
  /// them into SharedPreferences.
  static Future<String?> getCredential(String key) async {
    // In-memory test environment fast-path
    if (_isTestEnv) {
      final prefs = await _getPrefsSafely();
      final pVal = prefs?.getString(key)?.trim();
      if (pVal != null && pVal.isNotEmpty) {
        return pVal;
      }
      if (_testMemoryCredentials != null && _testMemoryCredentials!.containsKey(key)) {
        return _testMemoryCredentials![key];
      }
      return null;
    }

    // 1. Try SharedPreferences
    final prefs = await _getPrefsSafely();
    if (prefs != null) {
      final saved = prefs.getString(key)?.trim();
      if (saved != null && saved.isNotEmpty) {
        return saved;
      }
    }

    // 2. Self-healing fallback: Check file layers
    final backup = await _loadRawBackupFromFileLayers();
    if (backup != null) {
      final creds = (backup['credentials'] as Map<dynamic, dynamic>?) ?? {};
      final restoredVal = creds[key]?.toString().trim();

      // Self-heal: push all found credentials back into SharedPreferences
      if (prefs != null) {
        for (final entry in creds.entries) {
          final k = entry.key.toString();
          final v = entry.value?.toString().trim();
          if (v != null && v.isNotEmpty) {
            await prefs.setString(k, v);
          }
        }
        debugPrint('[CredentialsBackupService] Self-healed credentials into SharedPreferences.');
      }

      if (restoredVal != null && restoredVal.isNotEmpty) {
        return restoredVal;
      }
    }

    return null;
  }

  /// Reads raw backup payload from disk, prioritizing Documents dir, then External App storage,
  /// then Android Download directory.
  static Future<Map<String, dynamic>?> _loadRawBackupFromFileLayers() async {
    if (_isTestEnv) {
      if (_testMemoryCredentials != null && _testMemoryCredentials!.isNotEmpty) {
        return {
          'version': 1,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'credentials': Map<String, dynamic>.from(_testMemoryCredentials!),
        };
      }
      return null;
    }

    // Layer 2: Application Documents Directory
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final docFile = File('${docsDir.path}/$backupFileName');
      if (await docFile.exists()) {
        final content = await docFile.readAsString();
        if (content.trim().isNotEmpty) {
          return jsonDecode(content) as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('[CredentialsBackupService] Error reading docs backup: $e');
    }

    // Layer 3: External App Storage Directory
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final extFile = File('${extDir.path}/$backupFileName');
        if (await extFile.exists()) {
          final content = await extFile.readAsString();
          if (content.trim().isNotEmpty) {
            return jsonDecode(content) as Map<String, dynamic>;
          }
        }
      }
    } catch (e) {
      debugPrint('[CredentialsBackupService] Error reading ext backup: $e');
    }

    // Layer 4: Android Public Download Directory (survives uninstalls)
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final downloadFile = File('/sdcard/Download/$backupFileName');
        if (await downloadFile.exists()) {
          final content = await downloadFile.readAsString();
          if (content.trim().isNotEmpty) {
            return jsonDecode(content) as Map<String, dynamic>;
          }
        }
      } catch (e) {
        debugPrint('[CredentialsBackupService] Error reading Download backup: $e');
      }

      try {
        final docsPublicFile = File('/sdcard/Documents/$backupFileName');
        if (await docsPublicFile.exists()) {
          final content = await docsPublicFile.readAsString();
          if (content.trim().isNotEmpty) {
            return jsonDecode(content) as Map<String, dynamic>;
          }
        }
      } catch (e) {
        debugPrint('[CredentialsBackupService] Error reading Public Docs backup: $e');
      }
    }

    return null;
  }

  /// Writes JSON payload to all storage layers.
  static Future<void> _writeToAllStorageLayers(String jsonStr) async {
    if (_isTestEnv) return;

    // Layer 2: Application Documents Directory
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final docFile = File('${docsDir.path}/$backupFileName');
      await docFile.writeAsString(jsonStr);
    } catch (e) {
      debugPrint('[CredentialsBackupService] Error writing docs backup: $e');
    }

    // Layer 3: External App Storage Directory
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final extFile = File('${extDir.path}/$backupFileName');
        await extFile.writeAsString(jsonStr);
      }
    } catch (e) {
      debugPrint('[CredentialsBackupService] Error writing ext backup: $e');
    }

    // Layer 4: Android Public Download Directory (survives uninstalls)
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final downloadDir = Directory('/sdcard/Download');
        if (await downloadDir.exists()) {
          final downloadFile = File('/sdcard/Download/$backupFileName');
          await downloadFile.writeAsString(jsonStr);
        }
      } catch (e) {
        debugPrint('[CredentialsBackupService] Error writing Download backup: $e');
      }
    }
  }

  /// Called on app startup to guarantee all credentials and tokens are preserved
  /// and restored into SharedPreferences if an update/reinstall wiped them.
  static Future<int> ensureCredentialsPreserved() async {
    try {
      final prefs = await _getPrefsSafely();
      final backup = await _loadRawBackupFromFileLayers();
      if (backup == null) return 0;

      final creds = (backup['credentials'] as Map<dynamic, dynamic>?) ?? {};
      int restoredCount = 0;

      if (prefs != null) {
        for (final entry in creds.entries) {
          final k = entry.key.toString();
          final v = entry.value?.toString().trim();
          if (v != null && v.isNotEmpty) {
            final current = prefs.getString(k)?.trim();
            if (current == null || current.isEmpty) {
              await prefs.setString(k, v);
              restoredCount++;
            }
          }
        }
      }

      if (restoredCount > 0) {
        debugPrint('[CredentialsBackupService] Preserved and restored $restoredCount credential(s) from persistent backup.');
      }
      return restoredCount;
    } catch (e) {
      debugPrint('[CredentialsBackupService] ensureCredentialsPreserved error: $e');
      return 0;
    }
  }
}
