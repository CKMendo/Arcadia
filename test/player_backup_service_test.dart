import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arcadia/database/app_database.dart';
import 'package:arcadia/features/players/services/player_backup_service.dart';
import 'package:arcadia/features/players/repository/player_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Player Roster Multi-Layer Auto-Backup & Self-Healing Tests', () {
    late AppDatabase db;
    late PlayerRepository repo;
    late PlayerBackupService backupService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase(NativeDatabase.memory());
      repo = PlayerRepository(db);
      backupService = PlayerBackupService();
    });

    tearDown(() async {
      await db.close();
    });

    test('PlayerBackupService saves and retrieves players across storage layers', () async {
      final testPlayers = [
        const Player(
          id: 'p_chet',
          fullName: 'Chet Mehta',
          nickname: 'Chet',
          initials: 'CM',
          handicapIndex: 8.7,
          preferredTee: 'Blue',
          phoneNumber: '(313) 555-0188',
          isActive: true,
          createdAt: 1727570000000,
        ),
        const Player(
          id: 'p_hiten',
          fullName: 'Hiten Amin',
          nickname: 'Hiten',
          initials: 'HA',
          handicapIndex: 8.2,
          preferredTee: 'Blue',
          phoneNumber: '(586) 555-0164',
          isActive: true,
          createdAt: 1727570000000,
        ),
      ];

      await backupService.saveBackup(testPlayers);

      final loaded = await backupService.loadBackup();
      expect(loaded, isNotNull);
      expect(loaded!.length, 2);
      expect(loaded[0].fullName, 'Chet Mehta');
      expect(loaded[0].phoneNumber, '(313) 555-0188');
      expect(loaded[1].fullName, 'Hiten Amin');
      expect(loaded[1].handicapIndex, 8.2);

      final info = await backupService.getBackupInfo();
      expect(info.exists, isTrue);
      expect(info.count, 2);
      expect(info.playerNames, containsAll(['Chet Mehta', 'Hiten Amin']));
    });

    test('Safety Protection: saveBackup([]) NEVER overwrites a good existing backup', () async {
      final testPlayers = [
        const Player(
          id: 'p_chet',
          fullName: 'Chet Mehta',
          nickname: 'Chet',
          initials: 'CM',
          handicapIndex: 8.7,
          preferredTee: 'Blue',
          phoneNumber: '(313) 555-0188',
          isActive: true,
          createdAt: 1727570000000,
        ),
      ];

      await backupService.saveBackup(testPlayers);

      // Attempt to save empty list
      await backupService.saveBackup([]);

      // Verify the backup was preserved and NOT wiped
      final loaded = await backupService.loadBackup();
      expect(loaded, isNotNull);
      expect(loaded!.length, 1);
      expect(loaded.first.fullName, 'Chet Mehta');
    });

    test('Self-Healing: PlayerRepository automatically restores roster if database was wiped by app update', () async {
      // 1. Initial run: seed sample 8 players
      await repo.seedSample8Players();
      final original = await repo.getAllPlayers();
      expect(original.length, 8);

      // Verify backup info was automatically created
      final backupInfo = await repo.getBackupInfo();
      expect(backupInfo.exists, isTrue);
      expect(backupInfo.count, 8);

      // 2. Simulate app update / database wipe: clear the database table completely
      await repo.clearAllPlayers();
      final wipedDbPlayers = await (db.select(db.players)).get();
      expect(wipedDbPlayers.isEmpty, isTrue);

      // 3. New launch / app startup: ensureRosterPreserved runs
      await repo.ensureRosterPreserved();

      // 4. Verify all 8 players were self-healed and restored to database
      final restored = await repo.getAllPlayers();
      expect(restored.length, 8);
      expect(restored.map((p) => p.fullName), containsAll([
        'Chet Mehta',
        'Hiten Amin',
        'Hitesh Patel',
        'Neal Patel',
        'Sushil Bhakta',
        'Vilmer Villaverde',
        'Vinodh Rapur',
        'Raudel Sandoval',
      ]));
    });

    test('Import Roster JSON adds players and updates persistent backup', () async {
      const jsonSnippet = '''
      {
        "players": [
          {
            "name": "Tiger Woods",
            "nick": "Tiger",
            "hcp": 0.0,
            "tee": "Black",
            "phone": "(555) 123-4567"
          }
        ]
      }
      ''';

      final count = await repo.importRosterFromJson(jsonSnippet);
      expect(count, 1);

      final players = await repo.getAllPlayers();
      expect(players.any((p) => p.fullName == 'Tiger Woods'), isTrue);

      final backup = await backupService.loadBackup();
      expect(backup!.any((p) => p.fullName == 'Tiger Woods'), isTrue);
    });
  });
}
