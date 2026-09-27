import 'package:flutter_test/flutter_test.dart';
import 'package:arcadia/features/rounds/models/scoring_calculator.dart';

void main() {
  group('ScoringCalculator Tests', () {
    test('Calculates Course Handicap accurately', () {
      // 8.7 index on 73.1 rating / 138 slope / 72 par
      // (8.7 * 138 / 113) + (73.1 - 72) = 10.62 + 1.1 = 11.72 -> 12
      final ch = ScoringCalculator.calculateCourseHandicap(
        handicapIndex: 8.7,
        slopeRating: 138,
        courseRating: 73.1,
        par: 72,
      );
      expect(ch, 12);
    });

    test('Strokes allocated based on hole stroke index', () {
      // 12 handicap receives 1 stroke on stroke index 1..12, 0 on 13..18
      expect(ScoringCalculator.strokesForHole(courseHandicap: 12, strokeIndex: 5), 1);
      expect(ScoringCalculator.strokesForHole(courseHandicap: 12, strokeIndex: 12), 1);
      expect(ScoringCalculator.strokesForHole(courseHandicap: 12, strokeIndex: 13), 0);

      // 20 handicap receives 2 strokes on stroke index 1..2, 1 on 3..18
      expect(ScoringCalculator.strokesForHole(courseHandicap: 20, strokeIndex: 2), 2);
      expect(ScoringCalculator.strokesForHole(courseHandicap: 20, strokeIndex: 3), 1);
    });

    test('Stableford points calculation', () {
      // Net Par (0 diff) = 2 pts
      expect(ScoringCalculator.stablefordPoints(netScore: 4, holePar: 4), 2);
      // Net Birdie (-1 diff) = 3 pts
      expect(ScoringCalculator.stablefordPoints(netScore: 3, holePar: 4), 3);
      // Net Eagle (-2 diff) = 4 pts
      expect(ScoringCalculator.stablefordPoints(netScore: 3, holePar: 5), 4);
      // Net Bogey (+1 diff) = 1 pt
      expect(ScoringCalculator.stablefordPoints(netScore: 5, holePar: 4), 1);
      // Net Double Bogey (+2 diff) = 0 pts
      expect(ScoringCalculator.stablefordPoints(netScore: 6, holePar: 4), 0);
    });

    test('Skins calculation with carryover', () {
      final scores = {
        'p1': {1: 4, 2: 4, 3: 3},
        'p2': {1: 4, 2: 5, 3: 4},
      };

      final skins = ScoringCalculator.calculateSkins(
        holeCount: 3,
        playerIds: ['p1', 'p2'],
        scoresByPlayer: scores,
        useCarryover: true,
      );

      // Hole 1: tied (4 vs 4) -> carryover
      expect(skins[1]!.isTied, true);
      expect(skins[1]!.winnerPlayerId, null);

      // Hole 2: p1 wins with 4 (was tied on hole 1, so 2 skins!)
      expect(skins[2]!.isTied, false);
      expect(skins[2]!.winnerPlayerId, 'p1');
      expect(skins[2]!.skinCount, 2);

      // Hole 3: p1 wins with 3 (1 skin)
      expect(skins[3]!.isTied, false);
      expect(skins[3]!.winnerPlayerId, 'p1');
      expect(skins[3]!.skinCount, 1);
    });
  });
}
