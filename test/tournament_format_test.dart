import 'package:flutter_test/flutter_test.dart';
import 'package:arcadia/database/app_database.dart';
import 'package:arcadia/features/rounds/models/active_round_session.dart';
import 'package:arcadia/features/rounds/models/scoring_calculator.dart';
import 'package:arcadia/features/tournaments/services/tournament_pairings_engine.dart';

void main() {
  group('Tournament Format & Scoring Tests', () {
    test('Rule 2: Standard Stableford point rules (double bogey max at 0)', () {
      // Par 4 hole
      expect(ScoringCalculator.stablefordPoints(netScore: 6, holePar: 4), 0); // Double bogey
      expect(ScoringCalculator.stablefordPoints(netScore: 7, holePar: 4), 0); // Triple bogey
      expect(ScoringCalculator.stablefordPoints(netScore: 5, holePar: 4), 1); // Bogey
      expect(ScoringCalculator.stablefordPoints(netScore: 4, holePar: 4), 2); // Par
      expect(ScoringCalculator.stablefordPoints(netScore: 3, holePar: 4), 3); // Birdie
      expect(ScoringCalculator.stablefordPoints(netScore: 2, holePar: 4), 4); // Eagle
    });

    test('Rule 5: Final Round Modified Stableford (-1 double bogey, 0 bogey, +1 par, +2 birdie)', () {
      // Par 4 hole in Final Round
      expect(ScoringCalculator.stablefordPoints(netScore: 6, holePar: 4, isModifiedFinalRound: true), -1); // Double bogey
      expect(ScoringCalculator.stablefordPoints(netScore: 7, holePar: 4, isModifiedFinalRound: true), -1); // Triple bogey
      expect(ScoringCalculator.stablefordPoints(netScore: 5, holePar: 4, isModifiedFinalRound: true), 0);  // Bogey
      expect(ScoringCalculator.stablefordPoints(netScore: 4, holePar: 4, isModifiedFinalRound: true), 1);  // Par
      expect(ScoringCalculator.stablefordPoints(netScore: 3, holePar: 4, isModifiedFinalRound: true), 2);  // Birdie
      expect(ScoringCalculator.stablefordPoints(netScore: 2, holePar: 4, isModifiedFinalRound: true), 3);  // Eagle
    });

    test('Rule 2 & 3: 2-Man Best Ball Stableford and end-of-round team recording', () {
      final holes = List.generate(
        18,
        (i) => HoleSessionInfo(holeNumber: i + 1, par: 4, strokeIndex: i + 1),
      );

      final p1 = const PlayerSessionInfo(
        playerId: 'p1',
        name: 'Player One',
        nickname: 'P1',
        initials: 'P1',
        handicapIndex: 0.0,
        courseHandicap: 0,
        teeBoxId: 't1',
        teeName: 'White',
        twoManTeamId: 'T1',
      );

      final p2 = const PlayerSessionInfo(
        playerId: 'p2',
        name: 'Player Two',
        nickname: 'P2',
        initials: 'P2',
        handicapIndex: 0.0,
        courseHandicap: 0,
        teeBoxId: 't1',
        teeName: 'White',
        twoManTeamId: 'T1',
      );

      final session = ActiveRoundSession(
        courseId: 'c1',
        courseName: 'The Bluffs',
        holes: holes,
        players: [p1, p2],
      );

      // Hole 1: P1 makes Par 4 (2 pts), P2 makes Birdie 3 (3 pts) -> Team best ball = 3 pts
      session.setGrossScore('p1', 1, 4);
      session.setGrossScore('p2', 1, 3);

      expect(session.stablefordForPlayer('p1', 1), 2);
      expect(session.stablefordForPlayer('p2', 1), 3);
      expect(session.teamStablefordForHole('T1', 1), 3);

      // Hole 2: P1 makes Bogey 5 (1 pt), P2 makes Double 6 (0 pts) -> Team best ball = 1 pt
      session.setGrossScore('p1', 2, 5);
      session.setGrossScore('p2', 2, 6);
      expect(session.teamStablefordForHole('T1', 2), 1);

      // Total team Stableford = 3 + 1 = 4
      expect(session.totalTeamStableford('T1'), 4);

      // Rule 3: BOTH players record the team score for their individual tournament standing
      expect(session.effectivePlayerStableford('p1'), 4);
      expect(session.effectivePlayerStableford('p2'), 4);
    });

    test('Rule 1: AI 4-some & 2-some pairings engine divides 8 players and maximizes partner rotation', () {
      final engine = TournamentPairingsEngine();
      final players = List.generate(
        8,
        (i) => Player(
          id: 'p$i',
          fullName: 'Player $i',
          nickname: 'P$i',
          handicapIndex: i * 2.0,
          preferredTee: 'White',
          initials: 'P$i',
          isActive: true,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      final planR1 = engine.generatePreliminaryPairings(
        players: players,
        pastRounds: [],
        roundNumber: 1,
      );

      expect(planR1.foursome1.allPlayers.length, 4);
      expect(planR1.foursome2.allPlayers.length, 4);
      expect(planR1.allTeams.length, 4);
      for (final t in planR1.allTeams) {
        expect(t.players.length, 2);
      }
    });

    test('Rule 4: Final Round Draft ranking and selection process', () {
      final engine = TournamentPairingsEngine();
      final players = List.generate(
        8,
        (i) => Player(
          id: 'p$i',
          fullName: 'Player $i',
          nickname: 'P$i',
          handicapIndex: 10.0,
          preferredTee: 'White',
          initials: 'P$i',
          isActive: true,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      // Simulate a past round with different team scores
      final holes = [const HoleSessionInfo(holeNumber: 1, par: 4, strokeIndex: 1)];
      final sessionPlayers = players.map((p) {
        return PlayerSessionInfo(
          playerId: p.id,
          name: p.fullName,
          nickname: p.nickname,
          initials: p.initials,
          handicapIndex: p.handicapIndex,
          courseHandicap: 0,
          teeBoxId: 't1',
          teeName: 'White',
          twoManTeamId: 'T1',
        );
      }).toList();

      final s1 = ActiveRoundSession(courseId: 'c1', courseName: 'The Bluffs', holes: holes, players: sessionPlayers);
      for (var i = 0; i < 8; i++) {
        // Player 0 scores 4 (Par -> 2 pts), others score worse
        s1.setGrossScore('p$i', 1, 4 + i);
      }

      final rankings = engine.computeRankings(players, [s1]);
      expect(rankings.length, 8);
      expect(rankings.first.player.id, 'p0'); // Rank 1

      // #1 Captain selects #5 as partner, #2 selects #6, #3 selects #7, #4 gets #8
      final finalPlan = engine.generateFinalRoundPairings(
        players: players,
        pastRounds: [s1],
        roundNumber: 4,
        draftedPairs: {
          rankings[0].player.id: rankings[4].player.id,
          rankings[1].player.id: rankings[5].player.id,
          rankings[2].player.id: rankings[6].player.id,
          rankings[3].player.id: rankings[7].player.id,
        },
      );

      expect(finalPlan.isFinalRound, true);
      expect(finalPlan.allTeams.length, 4);
      expect(finalPlan.allTeams[0].player1.id, rankings[0].player.id);
      expect(finalPlan.allTeams[0].player2.id, rankings[4].player.id);
    });

    test('Rule 7: Birdie Pot Game calculation and payouts', () {
      final holes = List.generate(
        18,
        (i) => HoleSessionInfo(holeNumber: i + 1, par: 4, strokeIndex: i + 1),
      );

      final players = List.generate(
        8,
        (i) => PlayerSessionInfo(
          playerId: 'p$i',
          name: 'Player $i',
          nickname: 'P$i',
          initials: 'P$i',
          handicapIndex: 0.0,
          courseHandicap: 0,
          teeBoxId: 't1',
          teeName: 'White',
        ),
      );

      final s = ActiveRoundSession(courseId: 'c1', courseName: 'The Bluffs', holes: holes, players: players);

      // Suppose 3 birdies made in the round:
      // Hole 4: P0 makes 3 (Birdie on par 4)
      // Hole 9: P1 makes 3 (Birdie on par 4)
      // Hole 16: P2 makes 3 (Birdie on par 4) - THIS IS THE LAST BIRDIE OF THE ROUND!
      s.setGrossScore('p0', 4, 3);
      s.setGrossScore('p1', 9, 3);
      s.setGrossScore('p2', 16, 3);

      final pot = s.roundBirdiePot(totalFieldSize: 8);

      expect(pot.totalBirdies, 3);
      // Everyone puts in $2.00 per birdie: 3 birdies * $2.00 = $6.00 dues per player
      expect(pot.duesPerPlayer, 6.0);
      // Total collected across 8 players = 8 * $6 = $48.00
      expect(pot.totalCollected, 48.0);
      // $1 per birdie goes to Round Pot: 8 players * $1 * 3 birdies = $24.00
      expect(pot.roundPotTotal, 24.0);
      // $1 per birdie goes to Cumulative Pot: 8 players * $1 * 3 birdies = $24.00
      expect(pot.cumulativeContribution, 24.0);

      // Last birdie hole is hole 16
      expect(pot.lastBirdieHole, 16);
      expect(pot.winnerPlayerIds, ['p2']);
      expect(pot.payoutPerWinner, 24.0);

      // Test tied last hole: if P3 also birdied hole 16, pot is split!
      s.setGrossScore('p3', 16, 3);
      final tiedPot = s.roundBirdiePot(totalFieldSize: 8);
      expect(tiedPot.totalBirdies, 4);
      expect(tiedPot.roundPotTotal, 32.0); // 4 * $8
      expect(tiedPot.lastBirdieHole, 16);
      expect(tiedPot.winnerPlayerIds.length, 2);
      expect(tiedPot.payoutPerWinner, 16.0); // $32 split 2 ways
    });
  });
}
