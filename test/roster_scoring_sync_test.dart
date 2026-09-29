import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:arcadia/database/app_database.dart';
import 'package:arcadia/features/players/repository/player_repository.dart';
import 'package:arcadia/features/rounds/models/active_round_session.dart';
import 'package:arcadia/features/rounds/repository/round_repository.dart';
import 'package:arcadia/features/courses/repository/trip_schedule_repository.dart';
import 'package:arcadia/features/tournaments/services/tournament_pairings_engine.dart';

void main() {
  late AppDatabase db;
  late PlayerRepository playerRepo;
  late RoundRepository roundRepo;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    db = AppDatabase(NativeDatabase.memory());
    playerRepo = PlayerRepository(db);
    roundRepo = RoundRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Roster & Scoring Synchronization Tests', () {
    test('ActiveRoundSession.syncWithRoster updates player names, nicknames, and handicaps', () {
      final initialPlayers = [
        const PlayerSessionInfo(
          playerId: 'p1',
          name: 'Old Name',
          nickname: 'Oldie',
          initials: 'ON',
          handicapIndex: 12.0,
          teeBoxId: 'blue',
          teeName: 'Blue',
          courseHandicap: 15,
          twoManTeamId: 'T1',
          twoManTeamName: 'Oldie & Bob',
        ),
        const PlayerSessionInfo(
          playerId: 'p2',
          name: 'Bob Jones',
          nickname: 'Bob',
          initials: 'BJ',
          handicapIndex: 10.0,
          teeBoxId: 'blue',
          teeName: 'Blue',
          courseHandicap: 13,
          twoManTeamId: 'T1',
          twoManTeamName: 'Oldie & Bob',
        ),
      ];

      final session = ActiveRoundSession(
        courseId: 'c1',
        courseName: 'Arcadia Bluffs (The Bluffs)',
        roundNumber: 1,
        holes: [
          const HoleSessionInfo(holeNumber: 1, par: 4, strokeIndex: 1),
        ],
        players: initialPlayers,
      );

      final updatedRoster = [
        Player(
          id: 'p1',
          fullName: 'New Name',
          nickname: 'Speedy',
          initials: 'NN',
          handicapIndex: 8.7,
          preferredTee: 'Blue',
          isActive: true,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
        Player(
          id: 'p2',
          fullName: 'Bob Jones',
          nickname: 'Bobby',
          initials: 'BJ',
          handicapIndex: 10.0,
          preferredTee: 'Blue',
          isActive: true,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      ];

      final changed = session.syncWithRoster(updatedRoster);

      expect(changed, isTrue);
      expect(session.players[0].name, 'New Name');
      expect(session.players[0].nickname, 'Speedy');
      expect(session.players[0].initials, 'NN');
      expect(session.players[0].handicapIndex, 8.7);
      // Course handicap should be recalculated for Arcadia Bluffs Blue tees (12 for 8.7)
      expect(session.players[0].courseHandicap, 12);
      // Team name should be refreshed with new nicknames
      expect(session.players[0].twoManTeamName, 'Speedy & Bobby');
      expect(session.players[1].twoManTeamName, 'Speedy & Bobby');
    });

    test('RoundPairingPlan.withLatestPlayers refreshes player references and team labels', () {
      final p1 = Player(
        id: 'p1',
        fullName: 'Chet Mehta',
        nickname: 'Chet',
        initials: 'CM',
        handicapIndex: 8.7,
        isActive: true,
        createdAt: 0,
      );
      final p2 = Player(
        id: 'p2',
        fullName: 'Raudel Sandoval',
        nickname: 'Raudel',
        initials: 'RS',
        handicapIndex: 12.0,
        isActive: true,
        createdAt: 0,
      );
      final p3 = Player(
        id: 'p3',
        fullName: 'Hiten Amin',
        nickname: 'Hiten',
        initials: 'HA',
        handicapIndex: 8.2,
        isActive: true,
        createdAt: 0,
      );
      final p4 = Player(
        id: 'p4',
        fullName: 'Hitesh Patel',
        nickname: 'Hitesh',
        initials: 'HP',
        handicapIndex: 12.8,
        isActive: true,
        createdAt: 0,
      );

      final plan = RoundPairingPlan(
        roundNumber: 1,
        isFinalRound: false,
        foursome1: FoursomePlan(
          groupNumber: 1,
          teamA: TwoManTeamPlan(teamId: 'T1', teamName: 'Chet & Raudel', player1: p1, player2: p2),
          teamB: TwoManTeamPlan(teamId: 'T2', teamName: 'Hiten & Hitesh', player1: p3, player2: p4),
        ),
        foursome2: FoursomePlan(
          groupNumber: 2,
          teamA: TwoManTeamPlan(teamId: 'T3', teamName: 'Chet & Raudel', player1: p1, player2: p2),
          teamB: TwoManTeamPlan(teamId: 'T4', teamName: 'Hiten & Hitesh', player1: p3, player2: p4),
        ),
      );

      final freshRoster = [
        p1.copyWith(nickname: 'Chester'),
        p2.copyWith(fullName: 'Raudel S.'),
        p3,
        p4,
      ];

      final updatedPlan = plan.withLatestPlayers(freshRoster);

      expect(updatedPlan.foursome1.teamA.teamName, 'Chester & Raudel');
      expect(updatedPlan.foursome1.teamA.player1.nickname, 'Chester');
      expect(updatedPlan.foursome1.teamA.player2.fullName, 'Raudel S.');
    });

    test('RoundRepository.syncPlayerProfiles updates active draft and saved rounds', () async {
      final initialPlayers = [
        const PlayerSessionInfo(
          playerId: 'p10',
          name: 'Original Name',
          nickname: 'Original',
          initials: 'ON',
          handicapIndex: 14.0,
          teeBoxId: 'blue',
          teeName: 'Blue',
          courseHandicap: 18,
        ),
      ];

      final session = ActiveRoundSession(
        courseId: 'c1',
        courseName: 'Arcadia Bluffs (The Bluffs)',
        roundNumber: 1,
        holes: [const HoleSessionInfo(holeNumber: 1, par: 4, strokeIndex: 1)],
        players: initialPlayers,
      );

      // Save draft
      await roundRepo.saveActiveDraft(session);

      // Update player profile
      final updatedRoster = [
        Player(
          id: 'p10',
          fullName: 'Updated Name',
          nickname: 'UpdatedNick',
          initials: 'UN',
          handicapIndex: 9.0,
          isActive: true,
          createdAt: 0,
        ),
      ];

      await roundRepo.syncPlayerProfiles(updatedRoster);

      final updatedDraft = await roundRepo.getActiveDraft();
      expect(updatedDraft, isNotNull);
      expect(updatedDraft!.players.first.name, 'Updated Name');
      expect(updatedDraft.players.first.nickname, 'UpdatedNick');
      expect(updatedDraft.players.first.handicapIndex, 9.0);
    });

    test('PlayerRepository invokes onRosterChanged on update, create, delete', () async {
      var callCount = 0;
      playerRepo.onRosterChanged = () => callCount++;

      await playerRepo.createPlayer(
        fullName: 'Test Player',
        handicapIndex: 10.0,
        autoBackup: false,
      );
      expect(callCount, 1);

      final players = await playerRepo.getAllPlayers();
      final p = players.firstWhere((x) => x.fullName == 'Test Player');

      await playerRepo.updatePlayer(p.copyWith(nickname: 'Tester'));
      expect(callCount, 2);

      await playerRepo.deletePlayer(p.id);
      expect(callCount, 3);
    });
  });
}
