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

  Map<String, dynamic> toJson() => {
        'teamId': teamId,
        'teamName': teamName,
        'player1': _playerToMap(player1),
        'player2': _playerToMap(player2),
      };

  factory TwoManTeamPlan.fromJson(Map<String, dynamic> json, [List<Player>? allPlayers]) {
    final p1Map = json['player1'] as Map<String, dynamic>? ?? {};
    final p2Map = json['player2'] as Map<String, dynamic>? ?? {};
    final p1Id = p1Map['id'] as String? ?? '';
    final p2Id = p2Map['id'] as String? ?? '';

    final player1 = (allPlayers != null && allPlayers.isNotEmpty)
        ? (allPlayers.where((p) => p.id == p1Id).firstOrNull ?? _playerFromMap(p1Map))
        : _playerFromMap(p1Map);
    final player2 = (allPlayers != null && allPlayers.isNotEmpty)
        ? (allPlayers.where((p) => p.id == p2Id).firstOrNull ?? _playerFromMap(p2Map))
        : _playerFromMap(p2Map);

    final n1 = player1.nickname.isNotEmpty ? player1.nickname : player1.fullName.split(' ').first;
    final n2 = player2.nickname.isNotEmpty ? player2.nickname : player2.fullName.split(' ').first;
    final dynamicTeamName = (allPlayers != null && allPlayers.isNotEmpty)
        ? '$n1 & $n2'
        : (json['teamName'] as String? ?? '$n1 & $n2');

    return TwoManTeamPlan(
      teamId: json['teamId'] as String? ?? 'T1',
      teamName: dynamicTeamName,
      player1: player1,
      player2: player2,
    );
  }
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

  Map<String, dynamic> toJson() => {
        'groupNumber': groupNumber,
        'teamA': teamA.toJson(),
        'teamB': teamB.toJson(),
      };

  factory FoursomePlan.fromJson(Map<String, dynamic> json, [List<Player>? allPlayers]) {
    return FoursomePlan(
      groupNumber: (json['groupNumber'] as num?)?.toInt() ?? 1,
      teamA: TwoManTeamPlan.fromJson(json['teamA'] as Map<String, dynamic>? ?? {}, allPlayers),
      teamB: TwoManTeamPlan.fromJson(json['teamB'] as Map<String, dynamic>? ?? {}, allPlayers),
    );
  }
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

  Map<String, dynamic> toJson() => {
        'roundNumber': roundNumber,
        'isFinalRound': isFinalRound,
        'foursome1': foursome1.toJson(),
        'foursome2': foursome2.toJson(),
      };

  factory RoundPairingPlan.fromJson(Map<String, dynamic> json, [List<Player>? allPlayers]) {
    return RoundPairingPlan(
      roundNumber: (json['roundNumber'] as num?)?.toInt() ?? 1,
      isFinalRound: json['isFinalRound'] as bool? ?? false,
      foursome1: FoursomePlan.fromJson(json['foursome1'] as Map<String, dynamic>? ?? {}, allPlayers),
      foursome2: FoursomePlan.fromJson(json['foursome2'] as Map<String, dynamic>? ?? {}, allPlayers),
    );
  }

  RoundPairingPlan withLatestPlayers(List<Player> latestPlayers) {
    return RoundPairingPlan.fromJson(toJson(), latestPlayers);
  }
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

class ScheduledRoundInfo {
  final int roundNumber;
  final DateTime date;
  final RoundPairingPlan? pairingPlan;

  const ScheduledRoundInfo({
    required this.roundNumber,
    required this.date,
    this.pairingPlan,
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
  /// Examines past team pairings and tries to avoid pairing people who've been paired up before.
  RoundPairingPlan generatePreliminaryPairings({
    required List<Player> players,
    required List<ActiveRoundSession> pastRounds,
    required int roundNumber,
  }) {
    return generateSchedulePairingsForDate(
      players: players,
      roundDate: DateTime.now(),
      roundNumber: roundNumber,
      pastCompletedRounds: pastRounds,
      priorScheduledRounds: [],
    );
  }

  /// Looks at all team pairings prior to [roundDate] (from both completed rounds and scheduled rounds)
  /// and strictly avoids pairing people who have been paired up before as 2-man teammates.
  /// Also rotates foursomes and balances team handicaps.
  RoundPairingPlan generateSchedulePairingsForDate({
    required List<Player> players,
    required DateTime roundDate,
    required int roundNumber,
    List<ActiveRoundSession> pastCompletedRounds = const [],
    List<ScheduledRoundInfo> priorScheduledRounds = const [],
  }) {
    if (players.length < 8) {
      return _generateFallback(players, roundNumber);
    }

    final playerList = List<Player>.from(players.take(8));
    final idToIndex = {for (var i = 0; i < 8; i++) playerList[i].id: i};

    // Co-play matrix: coplay[i][j] = number of times players i & j played in same 4-some
    final coplay = List.generate(8, (_) => List.filled(8, 0));
    // Teammate matrix: teammate[i][j] = number of times players i & j were 2-man partners
    final teammate = List.generate(8, (_) => List.filled(8, 0));

    // 1. Gather pairings from completed rounds played prior to roundDate
    for (final r in pastCompletedRounds) {
      final roundTime = r.datePlayed;
      if (roundTime.isAfter(roundDate) && !isSameDay(roundTime, roundDate)) {
        continue;
      }
      if (isSameDay(roundTime, roundDate) && r.roundNumber >= roundNumber) {
        continue;
      }

      // Track foursomes
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

      // Track 2-man teammates
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

    // 2. Gather pairings from already scheduled rounds occurring prior to roundDate
    for (final sched in priorScheduledRounds) {
      if (sched.date.isAfter(roundDate) && !isSameDay(sched.date, roundDate)) {
        continue;
      }
      if (isSameDay(sched.date, roundDate) && sched.roundNumber >= roundNumber) {
        continue;
      }

      final plan = sched.pairingPlan;
      if (plan == null) continue;

      // Track 2-man teammates
      for (final team in plan.allTeams) {
        final idx1 = idToIndex[team.player1.id];
        final idx2 = idToIndex[team.player2.id];
        if (idx1 != null && idx2 != null) {
          teammate[idx1][idx2]++;
          teammate[idx2][idx1]++;
        }
      }

      // Track foursomes
      for (final f in plan.foursomes) {
        final allP = f.allPlayers;
        for (var i = 0; i < allP.length; i++) {
          for (var j = i + 1; j < allP.length; j++) {
            final idx1 = idToIndex[allP[i].id];
            final idx2 = idToIndex[allP[j].id];
            if (idx1 != null && idx2 != null) {
              coplay[idx1][idx2]++;
              coplay[idx2][idx1]++;
            }
          }
        }
      }
    }

    // 3. Evaluate all 315 configurations (105 pair partitions x 3 foursome splits)
    // To strictly avoid pairing people who have been paired up before, any repeat teammate
    // receives a massive 50,000+ penalty, guaranteeing zero repeat teammates whenever mathematically possible.
    final allFourPairings = _generateAll105PartitionsOf8();
    var minScore = double.infinity;
    List<_CandidateAssignment> bestAssignments = [];

    for (final pairs in allFourPairings) {
      // 4 pairs: pairs[0], pairs[1], pairs[2], pairs[3]
      // 3 ways to assign them into two foursomes:
      // Split 1: (pair0, pair1) vs (pair2, pair3)
      // Split 2: (pair0, pair2) vs (pair1, pair3)
      // Split 3: (pair0, pair3) vs (pair1, pair2)
      final splits = [
        [
          [pairs[0], pairs[1]],
          [pairs[2], pairs[3]]
        ],
        [
          [pairs[0], pairs[2]],
          [pairs[1], pairs[3]]
        ],
        [
          [pairs[0], pairs[3]],
          [pairs[1], pairs[2]]
        ],
      ];

      for (final split in splits) {
        final f1Pairs = split[0];
        final f2Pairs = split[1];

        // 1. Partner repeat penalty (Primary Objective: AVOID REPEATS)
        var partnerPenalty = 0.0;
        for (final p in pairs) {
          final repeatCount = teammate[p[0]][p[1]];
          if (repeatCount > 0) {
            // Massive penalty ensures zero repeat partners if any combination without repeats exists
            partnerPenalty += repeatCount * 25000.0 + pow(repeatCount, 2) * 100000.0;
          }
        }

        // 2. Foursome co-play penalty (Secondary Objective: rotate opponents across rounds)
        var coplayPenalty = 0.0;
        final f1Indices = [f1Pairs[0][0], f1Pairs[0][1], f1Pairs[1][0], f1Pairs[1][1]];
        final f2Indices = [f2Pairs[0][0], f2Pairs[0][1], f2Pairs[1][0], f2Pairs[1][1]];

        for (final group in [f1Indices, f2Indices]) {
          for (var i = 0; i < group.length; i++) {
            for (var j = i + 1; j < group.length; j++) {
              coplayPenalty += pow(coplay[group[i]][group[j]], 2) * 15.0;
            }
          }
        }

        // 3. Handicap Balance (Tertiary Objective: competitive matches)
        final t1Hcp = playerList[f1Pairs[0][0]].handicapIndex + playerList[f1Pairs[0][1]].handicapIndex;
        final t2Hcp = playerList[f1Pairs[1][0]].handicapIndex + playerList[f1Pairs[1][1]].handicapIndex;
        final t3Hcp = playerList[f2Pairs[0][0]].handicapIndex + playerList[f2Pairs[0][1]].handicapIndex;
        final t4Hcp = playerList[f2Pairs[1][0]].handicapIndex + playerList[f2Pairs[1][1]].handicapIndex;

        final balanceDiff = (t1Hcp - t2Hcp).abs() +
            (t3Hcp - t4Hcp).abs() +
            ((t1Hcp + t2Hcp) - (t3Hcp + t4Hcp)).abs() * 0.5;
        final handicapPenalty = balanceDiff * 2.0;

        final totalScore = partnerPenalty + coplayPenalty + handicapPenalty;

        final candidate = _CandidateAssignment(
          f1Pairs: f1Pairs,
          f2Pairs: f2Pairs,
          score: totalScore,
        );

        if (totalScore < minScore) {
          minScore = totalScore;
          bestAssignments = [candidate];
        } else if ((totalScore - minScore).abs() < 0.001) {
          bestAssignments.add(candidate);
        }
      }
    }

    // Pick randomly among best assignments for variety
    final chosen = bestAssignments.isNotEmpty
        ? bestAssignments[_random.nextInt(bestAssignments.length)]
        : bestAssignments.first;

    final t1P1 = playerList[chosen.f1Pairs[0][0]];
    final t1P2 = playerList[chosen.f1Pairs[0][1]];
    final t2P1 = playerList[chosen.f1Pairs[1][0]];
    final t2P2 = playerList[chosen.f1Pairs[1][1]];

    final t3P1 = playerList[chosen.f2Pairs[0][0]];
    final t3P2 = playerList[chosen.f2Pairs[0][1]];
    final t4P1 = playerList[chosen.f2Pairs[1][0]];
    final t4P2 = playerList[chosen.f2Pairs[1][1]];

    return RoundPairingPlan(
      roundNumber: roundNumber,
      isFinalRound: false,
      foursome1: FoursomePlan(
        groupNumber: 1,
        teamA: TwoManTeamPlan(
          teamId: 'T1',
          teamName: '${_shortName(t1P1)} & ${_shortName(t1P2)}',
          player1: t1P1,
          player2: t1P2,
        ),
        teamB: TwoManTeamPlan(
          teamId: 'T2',
          teamName: '${_shortName(t2P1)} & ${_shortName(t2P2)}',
          player1: t2P1,
          player2: t2P2,
        ),
      ),
      foursome2: FoursomePlan(
        groupNumber: 2,
        teamA: TwoManTeamPlan(
          teamId: 'T3',
          teamName: '${_shortName(t3P1)} & ${_shortName(t3P2)}',
          player1: t3P1,
          player2: t3P2,
        ),
        teamB: TwoManTeamPlan(
          teamId: 'T4',
          teamName: '${_shortName(t4P1)} & ${_shortName(t4P2)}',
          player1: t4P1,
          player2: t4P2,
        ),
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
        final nameA = _shortName(captain.player);
        final nameB = _shortName(partner);
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
        final nameA = _shortName(captain.player);
        final nameB = _shortName(partner.player);
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

  /// Generates all 105 ways to partition 8 elements into four 2-man pairs.
  List<List<List<int>>> _generateAll105PartitionsOf8() {
    final results = <List<List<int>>>[];

    void recurse(List<int> remaining, List<List<int>> currentPairs) {
      if (remaining.isEmpty) {
        results.add(List.from(currentPairs));
        return;
      }
      final first = remaining[0];
      for (var i = 1; i < remaining.length; i++) {
        final second = remaining[i];
        final nextRemaining = <int>[];
        for (var j = 1; j < remaining.length; j++) {
          if (j != i) nextRemaining.add(remaining[j]);
        }
        currentPairs.add([first, second]);
        recurse(nextRemaining, currentPairs);
        currentPairs.removeLast();
      }
    }

    recurse([0, 1, 2, 3, 4, 5, 6, 7], []);
    return results;
  }

  RoundPairingPlan _generateFallback(List<Player> players, int roundNumber, {bool isFinal = false}) {
    final half = (players.length / 2).ceil();
    final g1 = players.sublist(0, min(4, half));
    final g2 = players.sublist(min(4, half));

    final t1 = TwoManTeamPlan(
      teamId: 'T1',
      teamName: g1.isNotEmpty ? _shortName(g1.first) : 'Team 1',
      player1: g1.isNotEmpty ? g1.first : players.first,
      player2: g1.length > 1 ? g1[1] : players.first,
    );
    final t2 = TwoManTeamPlan(
      teamId: 'T2',
      teamName: g1.length > 2 ? _shortName(g1[2]) : 'Team 2',
      player1: g1.length > 2 ? g1[2] : players.first,
      player2: g1.length > 3 ? g1[3] : (g1.isNotEmpty ? g1.first : players.first),
    );

    final t3 = TwoManTeamPlan(
      teamId: 'T3',
      teamName: g2.isNotEmpty ? _shortName(g2.first) : 'Team 3',
      player1: g2.isNotEmpty ? g2.first : players.first,
      player2: g2.length > 1 ? g2[1] : players.first,
    );
    final t4 = TwoManTeamPlan(
      teamId: 'T4',
      teamName: g2.length > 2 ? _shortName(g2[2]) : 'Team 4',
      player1: g2.length > 2 ? g2[2] : players.first,
      player2: g2.length > 3 ? g2[3] : (g2.isNotEmpty ? g2.first : players.first),
    );

    return RoundPairingPlan(
      roundNumber: roundNumber,
      isFinalRound: isFinal,
      foursome1: FoursomePlan(groupNumber: 1, teamA: t1, teamB: t2),
      foursome2: FoursomePlan(groupNumber: 2, teamA: t3, teamB: t4),
    );
  }

  static String _shortName(Player p) {
    if (p.nickname.isNotEmpty) return p.nickname;
    final parts = p.fullName.trim().split(' ');
    return parts.first;
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _CandidateAssignment {
  final List<List<int>> f1Pairs;
  final List<List<int>> f2Pairs;
  final double score;

  _CandidateAssignment({
    required this.f1Pairs,
    required this.f2Pairs,
    required this.score,
  });
}

Map<String, dynamic> _playerToMap(Player p) => {
      'id': p.id,
      'fullName': p.fullName,
      'nickname': p.nickname,
      'initials': p.initials,
      'handicapIndex': p.handicapIndex,
      'preferredTee': p.preferredTee,
      'phoneNumber': p.phoneNumber,
      'photoPath': p.photoPath,
    };

Player _playerFromMap(Map<String, dynamic> map) => Player(
      id: map['id'] as String? ?? '',
      fullName: map['fullName'] as String? ?? 'Golfer',
      nickname: map['nickname'] as String? ?? '',
      initials: map['initials'] as String? ?? 'G',
      handicapIndex: (map['handicapIndex'] as num?)?.toDouble() ?? 10.0,
      preferredTee: map['preferredTee'] as String? ?? 'White',
      phoneNumber: map['phoneNumber'] as String?,
      photoPath: map['photoPath'] as String?,
      isActive: true,
      createdAt: 0,
    );
