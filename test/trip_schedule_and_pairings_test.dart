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
  });
}
