import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'credentials_backup_service.dart';

class AppSettingsService {
  static const String _keyGeminiApiKey = CredentialsBackupService.keyGeminiApiKey;
  static const String _keyWebsiteUrl = CredentialsBackupService.keyWebsiteUrl;
  static const String _keyTinyUrl = CredentialsBackupService.keyTinyUrl;

  static const String defaultWebsiteUrl =
      'https://ckmendo.github.io/Arcadia/';
  static const String defaultTinyUrl = 'https://tinyurl.com/arcadia2027';

  static const String _keyGeminiSecondaryApiKey = CredentialsBackupService.keyGeminiSecondaryApiKey;

  /// Compile-time fallback key passed via --dart-define=GEMINI_API_KEY=...
  static const String _compileTimeGeminiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Retrieves the Primary Gemini API key (for Gemini 3.8 Flash).
  static Future<String?> getGeminiApiKey() async {
    return getGeminiPrimaryApiKey();
  }

  /// Retrieves the Primary Gemini API key, checking SharedPreferences and persistent backup.
  static Future<String?> getGeminiPrimaryApiKey() async {
    try {
      final saved = await CredentialsBackupService.getCredential(_keyGeminiApiKey);
      if (saved != null && saved.isNotEmpty) {
        return saved;
      }
    } catch (e) {
      debugPrint('Error reading Gemini primary key: $e');
    }
    if (_compileTimeGeminiKey.isNotEmpty) {
      return _compileTimeGeminiKey;
    }
    return null;
  }

  /// Retrieves the Secondary Gemini API key (for Gemini 3.7 Flash fallback).
  static Future<String?> getGeminiSecondaryApiKey() async {
    try {
      final saved = await CredentialsBackupService.getCredential(_keyGeminiSecondaryApiKey);
      if (saved != null && saved.isNotEmpty) {
        return saved;
      }
    } catch (e) {
      debugPrint('Error reading Gemini secondary key: $e');
    }
    return null;
  }

  /// Checks if either Primary or Secondary Gemini API key is configured.
  static Future<bool> hasAnyGeminiApiKey() async {
    final primary = await getGeminiPrimaryApiKey();
    if (primary != null && primary.isNotEmpty) return true;
    final secondary = await getGeminiSecondaryApiKey();
    return secondary != null && secondary.isNotEmpty;
  }

  /// Saves the Primary Gemini API key.
  static Future<void> setGeminiApiKey(String? key) async {
    return setGeminiPrimaryApiKey(key);
  }

  /// Saves the Primary Gemini API key to persistent multi-layer storage.
  static Future<void> setGeminiPrimaryApiKey(String? key) async {
    await CredentialsBackupService.setCredential(_keyGeminiApiKey, key);
  }

  /// Saves the Secondary Gemini API key to persistent multi-layer storage.
  static Future<void> setGeminiSecondaryApiKey(String? key) async {
    await CredentialsBackupService.setCredential(_keyGeminiSecondaryApiKey, key);
  }

  /// Retrieves the public website URL.
  static Future<String> getWebsiteUrl() async {
    try {
      final saved = await CredentialsBackupService.getCredential(_keyWebsiteUrl);
      if (saved != null && saved.isNotEmpty) {
        // Automatically migrate any legacy domains to the current GitHub Pages site
        if (saved.contains('chatgpt.site') ||
            saved.contains('trycloudflare.com') ||
            saved.contains('arcadia-golf-trip')) {
          await CredentialsBackupService.setCredential(_keyWebsiteUrl, defaultWebsiteUrl);
          await CredentialsBackupService.setCredential(_keyTinyUrl, defaultTinyUrl);
          return defaultWebsiteUrl;
        }
        return saved;
      }
    } catch (e) {
      debugPrint('Error reading website URL: $e');
    }
    return defaultWebsiteUrl;
  }

  /// Sets the public website URL and automatically regenerates the TinyURL shortlink.
  static Future<String> setWebsiteUrl(String url) async {
    final cleanUrl = url.trim().isEmpty ? defaultWebsiteUrl : url.trim();
    try {
      final tinyUrl = await shortenWithTinyUrl(cleanUrl);
      await updateWebsiteLinks(websiteUrl: cleanUrl, tinyUrl: tinyUrl);
      return tinyUrl;
    } catch (e) {
      debugPrint('Error saving website URL: $e');
      return defaultTinyUrl;
    }
  }

  /// Sets the custom TinyURL.
  static Future<void> setTinyUrl(String tinyUrl) async {
    try {
      await CredentialsBackupService.setCredential(_keyTinyUrl, tinyUrl);
    } catch (e) {
      debugPrint('Error saving custom TinyURL: $e');
    }
  }

  /// Sets both website URL and an optional custom TinyURL to persistent multi-layer storage.
  static Future<void> updateWebsiteLinks({
    required String websiteUrl,
    String? tinyUrl,
  }) async {
    try {
      final cleanWeb = websiteUrl.trim().isEmpty ? defaultWebsiteUrl : websiteUrl.trim();
      await CredentialsBackupService.setCredential(_keyWebsiteUrl, cleanWeb);

      if (tinyUrl != null && tinyUrl.trim().isNotEmpty) {
        await CredentialsBackupService.setCredential(_keyTinyUrl, tinyUrl.trim());
      } else {
        final autoTiny = await shortenWithTinyUrl(cleanWeb);
        await CredentialsBackupService.setCredential(_keyTinyUrl, autoTiny);
      }
    } catch (e) {
      debugPrint('Error updating website links: $e');
    }
  }

  /// Retrieves the shortened TinyURL.
  static Future<String> getTinyUrl() async {
    try {
      final saved = await CredentialsBackupService.getCredential(_keyTinyUrl);
      if (saved != null && saved.isNotEmpty) {
        if (saved.contains('2xnkqbrx') || saved.contains('arcadia2026')) {
          await CredentialsBackupService.setCredential(_keyTinyUrl, defaultTinyUrl);
          return defaultTinyUrl;
        }
        return saved;
      }
    } catch (e) {
      debugPrint('Error reading TinyURL: $e');
    }
    return defaultTinyUrl;
  }

  /// Calls the tinyurl.com API to create a short link.
  static Future<String> shortenWithTinyUrl(String longUrl) async {
    if (longUrl == defaultWebsiteUrl) {
      return defaultTinyUrl;
    }
    try {
      final apiUri = Uri.parse(
        'https://tinyurl.com/api-create.php?url=${Uri.encodeComponent(longUrl)}',
      );
      final response = await http.get(apiUri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 && response.body.trim().startsWith('http')) {
        return response.body.trim();
      }
    } catch (e) {
      debugPrint('TinyURL API request failed: $e');
    }
    return defaultTinyUrl;
  }

  /// Tests a Gemini API key by making a lightweight ping to a specified model
  /// (defaulting to Gemini 3.8 Flash, or specified model such as Gemini 3.7 Flash).
  static Future<bool> validateGeminiApiKey(
    String apiKey, {
    String model = 'gemini-3.8-flash',
  }) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) return false;

    final modelsToTry = [
      model,
      if (model != 'gemini-3.7-flash') 'gemini-3.7-flash',
      'gemini-3.6-flash',
    ];
    for (final m in modelsToTry) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$m:generateContent?key=$trimmedKey',
        );
        final payload = {
          'contents': [
            {
              'parts': [
                {'text': 'Ping'}
              ]
            }
          ]
        };
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          return true;
        }
        // A 503 or 429 indicates Google Cloud authenticated the API key and project,
        // but the specific model cluster is momentarily saturated.
        if (response.statusCode == 503 || response.statusCode == 429) {
          return true;
        }
      } catch (e) {
        debugPrint('Gemini key validation attempt on $m failed: $e');
      }
    }
    return false;
  }

  static const String _keyGitHubToken = CredentialsBackupService.keyGitHubToken;
  static const String defaultGitHubRepo = 'CKMendo/Arcadia';

  /// Retrieves the saved GitHub Personal Access Token from persistent multi-layer storage.
  static Future<String?> getGitHubToken() async {
    try {
      final saved = await CredentialsBackupService.getCredential(_keyGitHubToken);
      if (saved != null && saved.isNotEmpty) {
        return saved;
      }
    } catch (e) {
      debugPrint('Error reading GitHub token: $e');
    }
    const compileTime = String.fromEnvironment('GITHUB_TOKEN', defaultValue: '');
    if (compileTime.isNotEmpty) return compileTime;
    return null;
  }

  /// Saves or clears the GitHub Personal Access Token across persistent storage layers.
  static Future<bool> setGitHubToken(String? token) async {
    return CredentialsBackupService.setCredential(_keyGitHubToken, token);
  }

  /// Validates a GitHub Personal Access Token against the CKMendo/Arcadia repository.
  static Future<bool> validateGitHubToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return false;
    try {
      final url = Uri.parse('https://api.github.com/repos/$defaultGitHubRepo');
      final res = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $trimmed',
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'ArcadiaApp',
        },
      ).timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('GitHub token validation error: $e');
      return false;
    }
  }

  /// Guarantees that any tokens/keys saved in persistent device storage are restored
  /// to SharedPreferences upon app startup.
  static Future<int> ensureCredentialsPreserved() async {
    return CredentialsBackupService.ensureCredentialsPreserved();
  }
}
