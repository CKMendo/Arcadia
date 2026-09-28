import 'dart:math';
import '../../../database/app_database.dart';
import '../../rounds/models/active_round_session.dart';

class TwoManTeamPlan {
  final String teamId; // e.g. 'T1', 'T2', 'T3', 'T4'
  final String teamName;
  final Player player1;
  final Player player2;

  const TwoManTeamPlan({
    required this.teamId,
    required this.teamName,
    required this.player1,
    required this.player2,
  });

  List<Player> get players => [player1, player2];
}

class FoursomePlan {
  final int groupNumber; // 1 or 2
  final TwoManTeamPlan teamA;
  final TwoManTeamPlan teamB;

  const FoursomePlan({
    required this.groupNumber,
    required this.teamA,
    required this.teamB,
  });

  List<Player> get allPlayers => [...teamA.players, ...teamB.players];
}

class RoundPairingPlan {
  final int roundNumber;
  final bool isFinalRound;
  final FoursomePlan foursome1;
  final FoursomePlan foursome2;

  const RoundPairingPlan({
    required this.roundNumber,
    required this.isFinalRound,
    required this.foursome1,
    required this.foursome2,
  });

  List<FoursomePlan> get foursomes => [foursome1, foursome2];
  List<TwoManTeamPlan> get allTeams => [
        foursome1.teamA,
        foursome1.teamB,
        foursome2.teamA,
        foursome2.teamB,
      ];
}

class PlayerStandingSeed {
  final int rank; // 1 to 8
  final Player player;
  final int totalStablefordPoints;

  const PlayerStandingSeed({
    required this.rank,
    required this.player,
    required this.totalStablefordPoints,
  });
}

class TournamentPairingsEngine {
  final Random _random;

  TournamentPairingsEngine([Random? random]) : _random = random ?? Random();

  /// Calculates cumulative Stableford points for all players from previous rounds
  /// and ranks them #1 through #8.
  List<PlayerStandingSeed> computeRankings(
    List<Player> players,
    List<ActiveRoundSession> pastRounds,
  ) {
    final pointsMap = {for (final p in players) p.id: 0};

    for (final session in pastRounds) {
      for (final p in players) {
        pointsMap[p.id] = (pointsMap[p.id] ?? 0) + session.effectivePlayerStableford(p.id);
      }
    }

    final sortedPlayers = List<Player>.from(players)
      ..sort((a, b) {
        final ptsA = pointsMap[a.id] ?? 0;
        final ptsB = pointsMap[b.id] ?? 0;
        if (ptsB != ptsA) return ptsB.compareTo(ptsA); // Higher points first
        return a.handicapIndex.compareTo(b.handicapIndex); // Lower handicap tiebreaker
      });

    final results = <PlayerStandingSeed>[];
    for (var i = 0; i < sortedPlayers.length; i++) {
      final p = sortedPlayers[i];
      results.add(PlayerStandingSeed(
        rank: i + 1,
        player: p,
        totalStablefordPoints: pointsMap[p.id] ?? 0,
      ));
    }
    return results;
  }

  /// AI-Driven 4-somes and 2-man team generator.
  /// Maximizes randomness while guaranteeing equal playing time with all other 7 golfers.
  RoundPairingPlan generatePreliminaryPairings({
    required List<Player> players,
    required List<ActiveRoundSession> pastRounds,
    required int roundNumber,
  }) {
    if (players.length < 8) {
      return _generateFallback(players, roundNumber);
    }

    final playerList = List<Player>.from(players.take(8));
    final idToIndex = {for (var i = 0; i < 8; i++) playerList[i].id: i};

    // Co-play matrix: C[i][j] = number of times players i & j played in same 4-some
    final coplay = List.generate(8, (_) => List.filled(8, 0));
    // Teammate matrix: T[i][j] = number of times players i & j were 2-man partners
    final teammate = List.generate(8, (_) => List.filled(8, 0));

    for (final r in pastRounds) {
      // Group by foursome
      final g1 = r.players.where((p) => p.foursomeGroup == 1).map((p) => p.playerId).toList();
      final g2 = r.players.where((p) => p.foursomeGroup == 2).map((p) => p.playerId).toList();

      for (final g in [g1, g2]) {
        for (var i = 0; i < g.length; i++) {
          for (var j = i + 1; j < g.length; j++) {
            final idx1 = idToIndex[g[i]];
            final idx2 = idToIndex[g[j]];
            if (idx1 != null && idx2 != null) {
              coplay[idx1][idx2]++;
              coplay[idx2][idx1]++;
            }
          }
        }
      }

      // Group by 2-man team
      final teams = <String, List<String>>{};
      for (final p in r.players) {
        final tId = p.twoManTeamId != 'none' ? p.twoManTeamId : p.teamId;
        if (tId != 'none') {
          teams.putIfAbsent(tId, () => []).add(p.playerId);
        }
      }
      for (final tPlayers in teams.values) {
        if (tPlayers.length == 2) {
          final idx1 = idToIndex[tPlayers[0]];
          final idx2 = idToIndex[tPlayers[1]];
          if (idx1 != null && idx2 != null) {
            teammate[idx1][idx2]++;
            teammate[idx2][idx1]++;
          }
        }
      }
    }

    // Evaluate all 35 combinations of 8 choose 4 (fixing player 0 to group 1 avoids symmetry)
    final splits = _allUniquePartitionsOf8();
    var minScore = double.infinity;
    List<List<List<int>>> bestSplits = [];

    for (final split in splits) {
      final g1 = split[0];
      final g2 = split[1];

      // Penalize repeat co-play heavily using quadratic penalty
      var score = 0.0;
      for (var i = 0; i < g1.length; i++) {
        for (var j = i + 1; j < g1.length; j++) {
          score += pow(coplay[g1[i]][g1[j]], 2);
        }
      }
      for (var i = 0; i < g2.length; i++) {
        for (var j = i + 1; j < g2.length; j++) {
          score += pow(coplay[g2[i]][g2[j]], 2);
        }
      }

      if (score < minScore) {
        minScore = score;
        bestSplits = [split];
      } else if (score == minScore) {
        bestSplits.add(split);
      }
    }

    // Pick randomly among best splits for freshness
    final chosenSplit = bestSplits[_random.nextInt(bestSplits.length)];
    final g1Indices = chosenSplit[0];
    final g2Indices = chosenSplit[1];

    // Form 2-man teams within each 4-some, minimizing repeat teammates
    final g1Teams = _bestTwoManPairing(g1Indices, teammate, playerList, 'T1', 'T2');
    final g2Teams = _bestTwoManPairing(g2Indices, teammate, playerList, 'T3', 'T4');

    return RoundPairingPlan(
      roundNumber: roundNumber,
      isFinalRound: false,
      foursome1: FoursomePlan(
        groupNumber: 1,
        teamA: g1Teams[0],
        teamB: g1Teams[1],
      ),
      foursome2: FoursomePlan(
        groupNumber: 2,
        teamA: g2Teams[0],
        teamB: g2Teams[1],
      ),
    );
  }

  /// Draft-based pairings for the Final Championship Round.
  /// Top 4 pick partners from bottom 4 (#1 picks first from #5-#8, #2 next, #3 next, #4 paired with remaining).
  RoundPairingPlan generateFinalRoundPairings({
    required List<Player> players,
    required List<ActiveRoundSession> pastRounds,
    required int roundNumber,
    Map<String, String>? draftedPairs, // captainPlayerId -> chosenPartnerPlayerId
  }) {
    final rankings = computeRankings(players, pastRounds);
    if (rankings.length < 8) {
      return _generateFallback(players, roundNumber, isFinal: true);
    }

    final top4 = rankings.sublist(0, 4);
    final bottom4 = rankings.sublist(4, 8);

    final finalTeams = <TwoManTeamPlan>[];
    final remainingPool = List<PlayerStandingSeed>.from(bottom4);

    if (draftedPairs != null && draftedPairs.isNotEmpty) {
      // Use user selection
      for (var i = 0; i < top4.length; i++) {
        final captain = top4[i];
        final chosenPartnerId = draftedPairs[captain.player.id];
        Player? partner;
        if (chosenPartnerId != null) {
          final found = remainingPool.where((p) => p.player.id == chosenPartnerId).firstOrNull;
          if (found != null) {
            partner = found.player;
            remainingPool.remove(found);
          }
        }
        partner ??= remainingPool.removeAt(0).player;

        final tNum = i + 1;
        final nameA = captain.player.nickname.isNotEmpty ? captain.player.nickname : captain.player.fullName.split(' ').first;
        final nameB = partner.nickname.isNotEmpty ? partner.nickname : partner.fullName.split(' ').first;
        finalTeams.add(TwoManTeamPlan(
          teamId: 'T$tNum',
          teamName: 'Team $tNum ($nameA & $nameB)',
          player1: captain.player,
          player2: partner,
        ));
      }
    } else {
      // Default auto-draft: #1 picks #5, #2 picks #6, #3 picks #7, #4 picks #8
      for (var i = 0; i < 4; i++) {
        final captain = top4[i];
        final partner = bottom4[i];
        final tNum = i + 1;
        final nameA = captain.player.nickname.isNotEmpty ? captain.player.nickname : captain.player.fullName.split(' ').first;
        final nameB = partner.player.nickname.isNotEmpty ? partner.player.nickname : partner.player.fullName.split(' ').first;
        finalTeams.add(TwoManTeamPlan(
          teamId: 'T$tNum',
          teamName: 'Team $tNum ($nameA & $nameB)',
          player1: captain.player,
          player2: partner.player,
        ));
      }
    }

    // Championship matches: Team 1 & Team 4 in Foursome 1, Team 2 & Team 3 in Foursome 2
    return RoundPairingPlan(
      roundNumber: roundNumber,
      isFinalRound: true,
      foursome1: FoursomePlan(
        groupNumber: 1,
        teamA: finalTeams[0], // Seed 1 team
        teamB: finalTeams[3], // Seed 4 team
      ),
      foursome2: FoursomePlan(
        groupNumber: 2,
        teamA: finalTeams[1], // Seed 2 team
        teamB: finalTeams[2], // Seed 3 team
      ),
    );
  }

  List<TwoManTeamPlan> _bestTwoManPairing(
    List<int> groupIndices,
    List<List<int>> teammateHistory,
    List<Player> allPlayers,
    String teamIdA,
    String teamIdB,
  ) {
    final a = groupIndices[0];
    final b = groupIndices[1];
    final c = groupIndices[2];
    final d = groupIndices[3];

    // 3 options:
    // Option 1: (a,b) & (c,d)
    final cost1 = teammateHistory[a][b] + teammateHistory[c][d];
    // Option 2: (a,c) & (b,d)
    final cost2 = teammateHistory[a][c] + teammateHistory[b][d];
    // Option 3: (a,d) & (b,c)
    final cost3 = teammateHistory[a][d] + teammateHistory[b][c];

    List<List<int>> chosen;
    final minCost = [cost1, cost2, cost3].reduce(min);
    final candidates = <List<List<int>>>[];
    if (cost1 == minCost) candidates.add([[a, b], [c, d]]);
    if (cost2 == minCost) candidates.add([[a, c], [b, d]]);
    if (cost3 == minCost) candidates.add([[a, d], [b, c]]);

    chosen = candidates[_random.nextInt(candidates.length)];

    final p1 = allPlayers[chosen[0][0]];
    final p2 = allPlayers[chosen[0][1]];
    final p3 = allPlayers[chosen[1][0]];
    final p4 = allPlayers[chosen[1][1]];

    final n1 = p1.nickname.isNotEmpty ? p1.nickname : p1.fullName.split(' ').first;
    final n2 = p2.nickname.isNotEmpty ? p2.nickname : p2.fullName.split(' ').first;
    final n3 = p3.nickname.isNotEmpty ? p3.nickname : p3.fullName.split(' ').first;
    final n4 = p4.nickname.isNotEmpty ? p4.nickname : p4.fullName.split(' ').first;

    return [
      TwoManTeamPlan(
        teamId: teamIdA,
        teamName: '$n1 & $n2',
        player1: p1,
        player2: p2,
      ),
      TwoManTeamPlan(
        teamId: teamIdB,
        teamName: '$n3 & $n4',
        player1: p3,
        player2: p4,
      ),
    ];
  }

  List<List<List<int>>> _allUniquePartitionsOf8() {
    // There are 35 distinct ways to partition {0..7} into two groups of 4.
    // By fixing 0 to group 1, we choose 3 from {1..7} for group 1: (7 choose 3 = 35).
    final pool = [1, 2, 3, 4, 5, 6, 7];
    final partitions = <List<List<int>>>[];

    for (var i = 0; i < pool.length; i++) {
      for (var j = i + 1; j < pool.length; j++) {
        for (var k = j + 1; k < pool.length; k++) {
          final g1 = [0, pool[i], pool[j], pool[k]];
          final g2 = [for (var x = 0; x < 8; x++) if (!g1.contains(x)) x];
          partitions.add([g1, g2]);
        }
      }
    }
    return partitions;
  }

  RoundPairingPlan _generateFallback(List<Player> players, int roundNumber, {bool isFinal = false}) {
    final half = (players.length / 2).ceil();
    final g1 = players.sublist(0, min(4, half));
    final g2 = players.sublist(min(4, half));

    final t1 = TwoManTeamPlan(
      teamId: 'T1',
      teamName: g1.isNotEmpty ? g1.first.fullName : 'Team 1',
      player1: g1.isNotEmpty ? g1.first : players.first,
      player2: g1.length > 1 ? g1[1] : players.first,
    );
    final t2 = TwoManTeamPlan(
      teamId: 'T2',
      teamName: g1.length > 2 ? g1[2].fullName : 'Team 2',
      player1: g1.length > 2 ? g1[2] : players.first,
      player2: g1.length > 3 ? g1[3] : players.first,
    );
    final t3 = TwoManTeamPlan(
      teamId: 'T3',
      teamName: g2.isNotEmpty ? g2.first.fullName : 'Team 3',
      player1: g2.isNotEmpty ? g2.first : players.first,
      player2: g2.length > 1 ? g2[1] : players.first,
    );
    final t4 = TwoManTeamPlan(
      teamId: 'T4',
      teamName: g2.length > 2 ? g2[2].fullName : 'Team 4',
      player1: g2.length > 2 ? g2[2] : players.first,
      player2: g2.length > 3 ? g2[3] : players.first,
    );

    return RoundPairingPlan(
      roundNumber: roundNumber,
      isFinalRound: isFinal,
      foursome1: FoursomePlan(groupNumber: 1, teamA: t1, teamB: t2),
      foursome2: FoursomePlan(groupNumber: 2, teamA: t3, teamB: t4),
    );
  }
}
