import 'package:flutter_test/flutter_test.dart';
import 'package:arcadia/database/app_database.dart';
import 'package:arcadia/features/courses/models/scheduled_round.dart';
import 'package:arcadia/features/tournaments/services/tournament_pairings_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arcadia/features/courses/repository/trip_schedule_repository.dart';

void main() {
  group('Trip Schedule and Non-Repeating AI Pairings Engine Tests', () {
    late List<Player> testPlayers;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      testPlayers = List.generate(
        8,
        (i) => Player(
          id: 'p$i',
          fullName: 'Golfer $i',
          nickname: 'G$i',
          handicapIndex: i * 1.5,
          preferredTee: 'White',
          initials: 'G$i',
          isActive: true,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });

    test('3 consecutive rounds guarantee ZERO repeat 2-man partners', () {
      final engine = TournamentPairingsEngine();
      final rounds = [
        ScheduledRound(
          id: 'sr1',
          roundNumber: 1,
          courseId: 'c1',
          courseName: 'The Bluffs Course',
          date: DateTime(2026, 6, 10),
          teeTimeGroup1: '09:00 AM',
          teeTimeGroup2: '09:12 AM',
        ),
        ScheduledRound(
          id: 'sr2',
          roundNumber: 2,
          courseId: 'c2',
          courseName: 'The South Course',
          date: DateTime(2026, 6, 11),
          teeTimeGroup1: '09:30 AM',
          teeTimeGroup2: '09:42 AM',
        ),
        ScheduledRound(
          id: 'sr3',
          roundNumber: 3,
          courseId: 'c1',
          courseName: 'The Bluffs Course (Championship)',
          date: DateTime(2026, 6, 12),
          teeTimeGroup1: '10:00 AM',
          teeTimeGroup2: '10:12 AM',
        ),
      ];

      final partnerHistory = <String, Set<String>>{};
      final scheduledInfos = <ScheduledRoundInfo>[];

      for (int i = 0; i < rounds.length; i++) {
        final currentRound = rounds[i];

        final plan = engine.generateSchedulePairingsForDate(
          players: testPlayers,
          roundDate: currentRound.date,
          roundNumber: currentRound.roundNumber,
          priorScheduledRounds: List.from(scheduledInfos),
          pastCompletedRounds: const [],
        );

        rounds[i] = currentRound.copyWith(pairingPlan: plan);
        scheduledInfos.add(
          ScheduledRoundInfo(
            roundNumber: currentRound.roundNumber,
            date: currentRound.date,
            pairingPlan: plan,
          ),
        );

        // Verify each team in this round has 2 players
        expect(plan.foursome1.teamA.players.length, 2);
        expect(plan.foursome1.teamB.players.length, 2);
        expect(plan.foursome2.teamA.players.length, 2);
        expect(plan.foursome2.teamB.players.length, 2);

        final roundTeams = [
          plan.foursome1.teamA,
          plan.foursome1.teamB,
          plan.foursome2.teamA,
          plan.foursome2.teamB,
        ];

        for (final team in roundTeams) {
          final p1 = team.players[0].id;
          final p2 = team.players[1].id;

          // Check ZERO partner repetition
          final p1PastPartners = partnerHistory[p1] ?? {};
          final p2PastPartners = partnerHistory[p2] ?? {};

          expect(
            p1PastPartners.contains(p2),
            isFalse,
            reason: 'Player $p1 was paired with $p2 in round ${i + 1}, but they were already partners!',
          );
          expect(
            p2PastPartners.contains(p1),
            isFalse,
            reason: 'Player $p2 was paired with $p1 in round ${i + 1}, but they were already partners!',
          );

          // Record partnership
          partnerHistory.putIfAbsent(p1, () => {}).add(p2);
          partnerHistory.putIfAbsent(p2, () => {}).add(p1);
        }
      }

      // By round 3, each of the 8 players must have had 3 UNIQUE partners
      for (final p in testPlayers) {
        expect(partnerHistory[p.id]?.length, 3, reason: 'Player ${p.fullName} did not get 3 unique partners');
      }
    });

    test('TripScheduleRepository finalizes schedule and attaches non-repeating pairings', () async {
      final repo = TripScheduleRepository();

      // Initially empty or unfinalized
      expect(await repo.isScheduleFinalized(), isFalse);

      // Seed default Arcadia schedule
      await repo.seedDefaultArcadiaSchedule([]);
      final rounds = await repo.getSchedule();
      expect(rounds.length, 3);

      // Finalize schedule with players
      await repo.finalizeScheduleAndGeneratePairings(
        players: testPlayers,
        pastSavedRounds: const [],
      );
      expect(await repo.isScheduleFinalized(), isTrue);

      final finalizedRounds = await repo.getSchedule();
      // Verify all rounds have valid pairing plans
      for (final r in finalizedRounds) {
        expect(r.pairingPlan, isNotNull);
        expect(r.pairingPlan!.foursome1.teamA.players.length, 2);
        expect(r.pairingPlan!.foursome1.teamB.players.length, 2);
        expect(r.pairingPlan!.foursome2.teamA.players.length, 2);
        expect(r.pairingPlan!.foursome2.teamB.players.length, 2);
      }

      // Unlocking schedule
      await repo.unlockSchedule();
      expect(await repo.isScheduleFinalized(), isFalse);
    });

    test('generateFullSchedulePairings produces optimal 1-factorization across 7 rounds with ZERO partner repeats and rotating lead golfer', () {
      final engine = TournamentPairingsEngine();
      final fullRounds = List.generate(
        7,
        (i) => ScheduledRoundInfo(
          roundNumber: i + 1,
          date: DateTime(2026, 6, 10 + i),
        ),
      );

      final pairedPlans = engine.generateFullSchedulePairings(
        players: testPlayers,
        scheduledRounds: fullRounds,
      );

      expect(pairedPlans.length, 7);

      final partnerMatrix = <String, Set<String>>{};
      for (final p in testPlayers) {
        partnerMatrix[p.id] = <String>{};
      }

      final foursomeSets = <Set<String>>[];
      final leadOffGolfers = <String>[];

      for (int r = 0; r < pairedPlans.length; r++) {
        final plan = pairedPlans[r];
        leadOffGolfers.add(plan.foursome1.teamA.player1.id);

        final f1Players = <String>{
          plan.foursome1.teamA.player1.id,
          plan.foursome1.teamA.player2.id,
          plan.foursome1.teamB.player1.id,
          plan.foursome1.teamB.player2.id,
        };
        final f2Players = <String>{
          plan.foursome2.teamA.player1.id,
          plan.foursome2.teamA.player2.id,
          plan.foursome2.teamB.player1.id,
          plan.foursome2.teamB.player2.id,
        };

        expect(f1Players.length, 4);
        expect(f2Players.length, 4);
        expect(f1Players.intersection(f2Players).isEmpty, isTrue);

        // Record partners
        final teams = [
          plan.foursome1.teamA,
          plan.foursome1.teamB,
          plan.foursome2.teamA,
          plan.foursome2.teamB,
        ];
        for (final t in teams) {
          final p1 = t.player1.id;
          final p2 = t.player2.id;
          expect(partnerMatrix[p1]!.contains(p2), isFalse, reason: 'Duplicate partner in round ${r + 1}');
          expect(partnerMatrix[p2]!.contains(p1), isFalse, reason: 'Duplicate partner in round ${r + 1}');
          partnerMatrix[p1]!.add(p2);
          partnerMatrix[p2]!.add(p1);
        }

        foursomeSets.add(f1Players);
        foursomeSets.add(f2Players);
      }

      // Check all 8 players have partnered with all 7 other players exactly once
      for (final p in testPlayers) {
        expect(partnerMatrix[p.id]!.length, 7);
      }

      // Check lead-off golfer is NOT the same golfer in every round
      final uniqueLeadGolfers = leadOffGolfers.toSet();
      expect(uniqueLeadGolfers.length, greaterThan(1), reason: 'Lead golfer should vary across rounds');

      // Check all 14 foursomes are distinct
      for (int i = 0; i < foursomeSets.length; i++) {
        for (int j = i + 1; j < foursomeSets.length; j++) {
          final isSame = foursomeSets[i].length == foursomeSets[j].length &&
              foursomeSets[i].containsAll(foursomeSets[j]);
          expect(isSame, isFalse, reason: 'Duplicate foursome found between groups');
        }
      }
    });

    test('Choose pairings generates proposed pairings WITHOUT finalizing or locking', () async {
      final repo = TripScheduleRepository();
      await repo.seedDefaultArcadiaSchedule([]);

      expect(await repo.isScheduleFinalized(), isFalse);

      // 1. Choose pairings (generates proposed plan, but leaves unlocked)
      await repo.generatePairingsForSchedule(
        players: testPlayers,
        pastSavedRounds: const [],
      );

      final scheduleWithPairings = await repo.getSchedule();
      expect(scheduleWithPairings.length, 3);
      for (final r in scheduleWithPairings) {
        expect(r.pairingPlan, isNotNull);
      }
      // Schedule is NOT yet finalized
      expect(await repo.isScheduleFinalized(), isFalse);

      // 2. Finalize & lock pairings
      await repo.finalizeScheduleAndLock();
      expect(await repo.isScheduleFinalized(), isTrue);

      // 3. Undo / unlock pairings
      await repo.unlockSchedule();
      expect(await repo.isScheduleFinalized(), isFalse);
    });

    test('Short courses (<18 holes) are excluded from pairings and Stableford scoring', () async {
      final repo = TripScheduleRepository();
      final scheduleWithShortCourse = [
        ScheduledRound(
          id: 'sr1',
          roundNumber: 1,
          courseId: 'c_bootlegger',
          courseName: 'Forest Dunes (The Bootlegger)',
          holeCount: 10,
          date: DateTime(2026, 6, 10),
          teeTimeGroup1: '11:00 AM',
          teeTimeGroup2: '11:11 AM',
        ),
        ScheduledRound(
          id: 'sr2',
          roundNumber: 2,
          courseId: 'c_original',
          courseName: 'Forest Dunes (Original)',
          holeCount: 18,
          date: DateTime(2026, 6, 11),
          teeTimeGroup1: '09:00 AM',
          teeTimeGroup2: '09:12 AM',
        ),
      ];

      await repo.saveSchedule(scheduleWithShortCourse);

      // Generate pairings for the schedule
      final updated = await repo.generatePairingsForSchedule(
        players: testPlayers,
        pastSavedRounds: const [],
      );

      // Bootlegger (10 holes) has balanced 2 Low HC + 2 High HC notation foursomes and is Birdie Pot Only
      final bootlegger = updated.firstWhere((r) => r.courseId == 'c_bootlegger');
      expect(bootlegger.isShortCourse, isTrue);
      expect(bootlegger.format, contains('Birdie Pot Only'));
      expect(bootlegger.pairingPlan, isNotNull);
      expect(bootlegger.pairingPlan!.foursome1.allPlayers.length, equals(4));
      expect(bootlegger.pairingPlan!.foursome2.allPlayers.length, equals(4));

      // Check handicap balance in short course notation foursome: 2 Low + 2 High
      final sortedHcs = testPlayers.map((p) => p.handicapIndex).toList()..sort();
      final medianHc = sortedHcs[3]; // threshold between low and high 4
      final g1Low = bootlegger.pairingPlan!.foursome1.allPlayers
          .where((p) => p.handicapIndex <= medianHc)
          .length;
      final g1High = bootlegger.pairingPlan!.foursome1.allPlayers
          .where((p) => p.handicapIndex > medianHc)
          .length;
      expect(g1Low, equals(2));
      expect(g1High, equals(2));

      // Original (18 holes) MUST have a regulation pairingPlan
      final original = updated.firstWhere((r) => r.courseId == 'c_original');
      expect(original.isShortCourse, isFalse);
      expect(original.pairingPlan, isNotNull);
    });
  });
}

