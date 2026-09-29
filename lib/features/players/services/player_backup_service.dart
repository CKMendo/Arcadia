import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../database/app_database.dart';
import '../../../shared/utils/player_initials_helper.dart';

class RosterBackupInfo {
  final bool exists;
  final int count;
  final DateTime? timestamp;
  final List<String> playerNames;

  const RosterBackupInfo({
    required this.exists,
    required this.count,
    this.timestamp,
    this.playerNames = const [],
  });

  static const empty = RosterBackupInfo(
    exists: false,
    count: 0,
    timestamp: null,
    playerNames: [],
  );
}

class PlayerBackupService {
  static const String _keyPrefsPayload = 'arcadia_player_roster_backup_payload_v1';
  static const String _keyPrefsTimestamp = 'arcadia_player_roster_backup_timestamp_v1';
  static const String _backupFileName = 'arcadia_roster_backup.json';

  static final PlayerBackupService _instance = PlayerBackupService._internal();
  factory PlayerBackupService() => _instance;
  PlayerBackupService._internal();

  static Map<String, dynamic>? _testMemoryBackup;
  static int? _testMemoryTimestamp;

  bool get _isTestEnv => Platform.environment['FLUTTER_TEST'] == 'true';

  /// Bundled fallback roster of the 8 Arcadia golfers
  static const List<Map<String, dynamic>> bundledArcadiaRoster = [
    {
      'name': 'Neal Patel',
      'nick': 'Neal',
      'hcp': 5.5,
      'tee': 'Blue',
      'phone': '(248) 555-0142',
    },
    {
      'name': 'Chet Mehta',
      'nick': 'Chet',
      'hcp': 8.7,
      'tee': 'Blue',
      'phone': '(313) 555-0188',
    },
    {
      'name': 'Raudel Sandoval',
      'nick': 'Raudel',
      'hcp': 12.0,
      'tee': 'White',
      'phone': '(734) 555-0193',
    },
    {
      'name': 'Vilmer Villaverde',
      'nick': 'Vilmer',
      'hcp': 16.5,
      'tee': 'White',
      'phone': '(616) 555-0125',
    },
    {
      'name': 'Sushil Bhakta',
      'nick': 'Hany',
      'hcp': 6.3,
      'tee': 'Blue',
      'phone': '(248) 555-0177',
    },
    {
      'name': 'Hiten Amin',
      'nick': 'Hiten',
      'hcp': 8.2,
      'tee': 'Blue',
      'phone': '(586) 555-0164',
    },
    {
      'name': 'Hitesh Patel',
      'nick': 'Hitesh',
      'hcp': 12.8,
      'tee': 'White',
      'phone': '(248) 555-0131',
    },
    {
      'name': 'Vinodh Rapur',
      'nick': 'Vinny',
      'hcp': 15.3,
      'tee': 'White',
      'phone': '(734) 555-0159',
    },
  ];

  Map<String, dynamic> playerToMap(Player p) {
    return {
      'id': p.id,
      'fullName': p.fullName,
      'nickname': p.nickname,
      'initials': p.initials,
      'handicapIndex': p.handicapIndex,
      'preferredTee': p.preferredTee,
      'ghinNumber': p.ghinNumber,
      'phoneNumber': p.phoneNumber,
      'email': p.email,
      'photoPath': p.photoPath,
      'isActive': p.isActive,
      'createdAt': p.createdAt,
    };
  }

  Player playerFromMap(Map<String, dynamic> m) {
    final fullName = (m['fullName'] ?? m['name'] ?? 'Player') as String;
    final initials = (m['initials'] as String?)?.isNotEmpty == true
        ? m['initials'] as String
        : PlayerInitialsHelper.compute(fullName);
    final nickname = (m['nickname'] ?? m['nick'] as String?)?.isNotEmpty == true
        ? (m['nickname'] ?? m['nick']) as String
        : fullName.split(' ').first;
    final hcp = (m['handicapIndex'] ?? m['handicap'] ?? m['hcp'] as num?)?.toDouble() ?? 0.0;
    final createdAt = (m['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;

    return Player(
      id: (m['id'] as String?)?.isNotEmpty == true ? m['id'] as String : 'p_${fullName.toLowerCase().replaceAll(' ', '_')}',
      fullName: fullName,
      nickname: nickname,
      initials: initials,
      handicapIndex: hcp,
      preferredTee: (m['preferredTee'] ?? m['tee']) as String? ?? 'White',
      ghinNumber: m['ghinNumber'] as String?,
      phoneNumber: (m['phoneNumber'] ?? m['phone']) as String?,
      email: m['email'] as String?,
      photoPath: m['photoPath'] as String?,
      isActive: (m['isActive'] as bool?) ?? true,
      createdAt: createdAt,
    );
  }

  Future<SharedPreferences?> _getPrefsSafely() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  /// Automatically backs up the given players across multi-layer persistent storage:
  /// 1. SharedPreferences (persists across standard app updates)
  /// 2. Documents file (app internal sandbox)
  /// 3. External app storage (survives certain app cache clears on Android)
  Future<void> saveBackup(List<Player> players) async {
    // Safety protection: NEVER overwrite a good backup of golfers with an empty list!
    if (players.isEmpty) return;

    try {
      final now = DateTime.now();
      final payload = {
        'version': 1,
        'timestamp': now.millisecondsSinceEpoch,
        'playerCount': players.length,
        'players': players.map(playerToMap).toList(),
      };

      if (_isTestEnv) {
        _testMemoryBackup = payload;
        _testMemoryTimestamp = now.millisecondsSinceEpoch;
        return;
      }

      final jsonStr = jsonEncode(payload);

      // Layer 1: SharedPreferences
      final prefs = await _getPrefsSafely();
      if (prefs != null) {
        await prefs.setString(_keyPrefsPayload, jsonStr);
        await prefs.setInt(_keyPrefsTimestamp, now.millisecondsSinceEpoch);
      }

      // Layer 2: Application Documents Directory File
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final docFile = File('${docsDir.path}/$_backupFileName');
        await docFile.writeAsString(jsonStr);
      } catch (e) {
        debugPrint('[PlayerBackupService] Could not write doc file: $e');
      }

        // Layer 3: External App Storage (if on Android/mobile)
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final extFile = File('${extDir.path}/$_backupFileName');
          await extFile.writeAsString(jsonStr);
        }
      } catch (e) {
        debugPrint('[PlayerBackupService] Could not write ext file: $e');
      }

      // Layer 4: Android Public Download Directory (survives uninstalls)
      if (!kIsWeb && Platform.isAndroid) {
        try {
          final downloadDir = Directory('/sdcard/Download');
          if (await downloadDir.exists()) {
            final downloadFile = File('/sdcard/Download/$_backupFileName');
            await downloadFile.writeAsString(jsonStr);
          }
        } catch (e) {
          debugPrint('[PlayerBackupService] Could not write Download file: $e');
        }
      }

      debugPrint('[PlayerBackupService] Successfully backed up ${players.length} players to multi-layer storage.');
    } catch (e) {
      debugPrint('[PlayerBackupService] saveBackup error: $e');
    }
  }

  /// Retrieves the latest backup from storage, checking SharedPreferences,
  /// documents directory, and external app storage.
  Future<List<Player>?> loadBackup() async {
    try {
      if (_isTestEnv && _testMemoryBackup != null) {
        final list = (_testMemoryBackup!['players'] as List<dynamic>?) ?? [];
        return list.map((item) => playerFromMap(item as Map<String, dynamic>)).toList();
      }

      // 1. Try SharedPreferences
      final prefs = await _getPrefsSafely();
      if (prefs != null) {
        final raw = prefs.getString(_keyPrefsPayload);
        if (raw != null && raw.isNotEmpty) {
          final parsed = _parsePlayersFromPayload(raw);
          if (parsed != null && parsed.isNotEmpty) {
            return parsed;
          }
        }
      }

      if (_isTestEnv) return null;

      // 2. Try App Documents File
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final docFile = File('${docsDir.path}/$_backupFileName');
        if (await docFile.exists()) {
          final content = await docFile.readAsString();
          final parsed = _parsePlayersFromPayload(content);
          if (parsed != null && parsed.isNotEmpty) {
            return parsed;
          }
        }
      } catch (_) {}

      // 3. Try External App Storage File
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final extFile = File('${extDir.path}/$_backupFileName');
          if (await extFile.exists()) {
            final content = await extFile.readAsString();
            final parsed = _parsePlayersFromPayload(content);
            if (parsed != null && parsed.isNotEmpty) {
              return parsed;
            }
          }
        }
      } catch (_) {}

      // 4. Try Android Public Download File
      if (!kIsWeb && Platform.isAndroid) {
        try {
          final downloadFile = File('/sdcard/Download/$_backupFileName');
          if (await downloadFile.exists()) {
            final content = await downloadFile.readAsString();
            final parsed = _parsePlayersFromPayload(content);
            if (parsed != null && parsed.isNotEmpty) {
              return parsed;
            }
          }
        } catch (_) {}
      }

      return null;
    } catch (e) {
      debugPrint('[PlayerBackupService] loadBackup error: $e');
      return null;
    }
  }

  /// Returns metadata about the current backup.
  Future<RosterBackupInfo> getBackupInfo() async {
    try {
      if (_isTestEnv && _testMemoryBackup != null) {
        final list = (_testMemoryBackup!['players'] as List<dynamic>?) ?? [];
        final names = list
            .map((p) => ((p as Map<String, dynamic>)['fullName'] ?? p['name'] ?? '') as String)
            .toList();
        return RosterBackupInfo(
          exists: true,
          count: list.length,
          timestamp: _testMemoryTimestamp != null ? DateTime.fromMillisecondsSinceEpoch(_testMemoryTimestamp!) : null,
          playerNames: names,
        );
      }

      final prefs = await _getPrefsSafely();
      final ts = prefs?.getInt(_keyPrefsTimestamp);
      final raw = prefs?.getString(_keyPrefsPayload);

      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final playersList = (map['players'] as List<dynamic>?) ?? [];
        final names = playersList
            .map((p) => ((p as Map<String, dynamic>)['fullName'] ?? p['name'] ?? '') as String)
            .toList();

        return RosterBackupInfo(
          exists: true,
          count: playersList.length,
          timestamp: ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null,
          playerNames: names,
        );
      }

      if (_isTestEnv) return RosterBackupInfo.empty;

      // Check file fallback
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final docFile = File('${docsDir.path}/$_backupFileName');
        if (await docFile.exists()) {
          final content = await docFile.readAsString();
          final map = jsonDecode(content) as Map<String, dynamic>;
          final playersList = (map['players'] as List<dynamic>?) ?? [];
          final names = playersList
              .map((p) => ((p as Map<String, dynamic>)['fullName'] ?? p['name'] ?? '') as String)
              .toList();
          final stat = await docFile.stat();

          return RosterBackupInfo(
            exists: true,
            count: playersList.length,
            timestamp: stat.modified,
            playerNames: names,
          );
        }
      } catch (_) {}

      return RosterBackupInfo.empty;
    } catch (_) {
      return RosterBackupInfo.empty;
    }
  }

  List<Player>? _parsePlayersFromPayload(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic> && decoded.containsKey('players')) {
        final list = decoded['players'] as List<dynamic>;
        return list.map((item) => playerFromMap(item as Map<String, dynamic>)).toList();
      } else if (decoded is List<dynamic>) {
        return decoded.map((item) => playerFromMap(item as Map<String, dynamic>)).toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Exports formatted JSON string of players.
  String exportJson(List<Player> players) {
    final payload = {
      'app': 'Arcadia Golf Trip',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'playerCount': players.length,
      'players': players.map(playerToMap).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Shares the roster backup via Android Share Sheet so the user can send
  /// it to themselves via text, WhatsApp, email, or save to Drive.
  Future<void> shareRosterBackup(List<Player> players) async {
    final buffer = StringBuffer();
    buffer.writeln('🏌️ ARCADIA GOLF TRIP – 8-PLAYER ROSTER BACKUP');
    buffer.writeln('Date: ${DateTime.now().toLocal()}');
    buffer.writeln('Total Golfers: ${players.length}');
    buffer.writeln('----------------------------------------');
    for (var i = 0; i < players.length; i++) {
      final p = players[i];
      buffer.writeln('${i + 1}. ${p.fullName} (HCP: ${p.handicapIndex}) • Tee: ${p.preferredTee ?? "White"} • Phone: ${p.phoneNumber ?? "N/A"}');
    }
    buffer.writeln('----------------------------------------');
    buffer.writeln('RESTORE JSON DATA:');
    buffer.writeln(exportJson(players));

    await Share.share(
      buffer.toString(),
      subject: '🏌️ Arcadia Golf Trip – Official Player Roster Backup',
    );
  }
}
