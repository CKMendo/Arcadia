class ScoringCalculator {
  ScoringCalculator._();

  /// Calculates USGA Course Handicap:
  /// Course Handicap = Handicap Index * (Slope / 113) + (Rating - Par)
  static int calculateCourseHandicap({
    required double handicapIndex,
    required int slopeRating,
    required double courseRating,
    required int par,
    double allowance = 1.0, // e.g. 100% or 0.8 for 80%
  }) {
    final unrounded = (handicapIndex * (slopeRating / 113.0) + (courseRating - par)) * allowance;
    return unrounded.round();
  }

  /// Calculates strokes received on a specific hole based on hole stroke index (1..18).
  static int strokesForHole({
    required int courseHandicap,
    required int strokeIndex,
  }) {
    if (courseHandicap >= 0) {
      final base = courseHandicap ~/ 18;
      final remainder = courseHandicap % 18;
      return base + (strokeIndex <= remainder ? 1 : 0);
    } else {
      // Plus handicap gives back strokes on hardest holes (stroke index 19 - x)
      final absHcp = courseHandicap.abs();
      final base = absHcp ~/ 18;
      final remainder = absHcp % 18;
      final losesStroke = (19 - strokeIndex) <= remainder;
      return -(base + (losesStroke ? 1 : 0));
    }
  }

  /// Calculates net score for a hole.
  static int netScore({
    required int grossScore,
    required int strokesReceived,
  }) {
    return grossScore - strokesReceived;
  }

  /// Calculates Stableford points based on net score vs hole par.
  /// Standard rounds:
  /// - Double Eagle / Albatross (-3): 5
  /// - Eagle (-2): 4
  /// - Birdie (-1): 3
  /// - Par (0): 2
  /// - Bogey (+1): 1
  /// - Double Bogey or worse (+2 or more): 0
  ///
  /// Final Round (Modified Stableford):
  /// - Double Eagle / Albatross (-3): 4
  /// - Eagle (-2): 3
  /// - Birdie (-1): 2
  /// - Par (0): 1
  /// - Bogey (+1): 0
  /// - Double Bogey or worse (+2 or more): -1
  static int stablefordPoints({
    required int netScore,
    required int holePar,
    bool isModifiedFinalRound = false,
  }) {
    final diff = netScore - holePar;
    if (isModifiedFinalRound) {
      if (diff <= -3) return 4;
      if (diff == -2) return 3;
      if (diff == -1) return 2;
      if (diff == 0) return 1;
      if (diff == 1) return 0;
      return -1; // double bogey or worse = -1
    } else {
      if (diff <= -3) return 5;
      if (diff == -2) return 4;
      if (diff == -1) return 3;
      if (diff == 0) return 2;
      if (diff == 1) return 1;
      return 0; // double bogey or worse = 0
    }
  }

  /// Calculates skins across players for completed holes.
  /// Returns a map of holeNumber -> SkinResult.
  static Map<int, SkinResult> calculateSkins({
    required int holeCount,
    required List<String> playerIds,
    required Map<String, Map<int, int>> scoresByPlayer, // playerId -> (holeNumber -> score)
    bool useCarryover = true,
  }) {
    final results = <int, SkinResult>{};
    var carriedSkins = 1;

    for (var hole = 1; hole <= holeCount; hole++) {
      // Collect valid scores on this hole
      final holeScores = <String, int>{};
      for (final pId in playerIds) {
        final score = scoresByPlayer[pId]?[hole];
        if (score != null && score > 0) {
          holeScores[pId] = score;
        }
      }

      // If not all players completed this hole, hole is not complete
      if (holeScores.length < playerIds.length || holeScores.isEmpty) {
        results[hole] = SkinResult(
          holeNumber: hole,
          isComplete: false,
          winnerPlayerId: null,
          winningScore: null,
          skinCount: carriedSkins,
          isTied: false,
        );
        continue;
      }

      // Find min score
      var minScore = 999;
      for (final score in holeScores.values) {
        if (score < minScore) minScore = score;
      }

      final lowPlayers = holeScores.entries
          .where((e) => e.value == minScore)
          .map((e) => e.key)
          .toList();

      if (lowPlayers.length == 1) {
        // Unique winner!
        results[hole] = SkinResult(
          holeNumber: hole,
          isComplete: true,
          winnerPlayerId: lowPlayers.first,
          winningScore: minScore,
          skinCount: carriedSkins,
          isTied: false,
        );
        carriedSkins = 1;
      } else {
        // Tied
        results[hole] = SkinResult(
          holeNumber: hole,
          isComplete: true,
          winnerPlayerId: null,
          winningScore: minScore,
          skinCount: carriedSkins,
          isTied: true,
        );
        if (useCarryover) {
          carriedSkins += 1;
        } else {
          carriedSkins = 1;
        }
      }
    }

    return results;
  }
}

class SkinResult {
  final int holeNumber;
  final bool isComplete;
  final String? winnerPlayerId;
  final int? winningScore;
  final int skinCount;
  final bool isTied;

  const SkinResult({
    required this.holeNumber,
    required this.isComplete,
    required this.winnerPlayerId,
    required this.winningScore,
    required this.skinCount,
    required this.isTied,
  });

  bool get hasWinner => isComplete && winnerPlayerId != null;
}
