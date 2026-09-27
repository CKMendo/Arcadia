import 'scoring_calculator.dart';

class PlayerSessionInfo {
  final String playerId;
  final String name;
  final String nickname;
  final String initials;
  final double handicapIndex;
  final String teeBoxId;
  final String teeName;
  final int courseHandicap;
  final String teamId; // 'a', 'b', 'none'

  const PlayerSessionInfo({
    required this.playerId,
    required this.name,
    required this.nickname,
    required this.initials,
    required this.handicapIndex,
    required this.teeBoxId,
    required this.teeName,
    required this.courseHandicap,
    this.teamId = 'none',
  });

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'name': name,
        'nickname': nickname,
        'initials': initials,
        'handicapIndex': handicapIndex,
        'teeBoxId': teeBoxId,
        'teeName': teeName,
        'courseHandicap': courseHandicap,
        'teamId': teamId,
      };

  factory PlayerSessionInfo.fromJson(Map<String, dynamic> json) =>
      PlayerSessionInfo(
        playerId: json['playerId'] as String,
        name: json['name'] as String,
        nickname: json['nickname'] as String? ?? json['name'] as String,
        initials: json['initials'] as String? ?? '??',
        handicapIndex: (json['handicapIndex'] as num).toDouble(),
        teeBoxId: json['teeBoxId'] as String,
        teeName: json['teeName'] as String,
        courseHandicap: (json['courseHandicap'] as num).toInt(),
        teamId: json['teamId'] as String? ?? 'none',
      );
}

class HoleSessionInfo {
  final int holeNumber;
  final int par;
  final int strokeIndex;
  final int yardage;

  const HoleSessionInfo({
    required this.holeNumber,
    required this.par,
    required this.strokeIndex,
    this.yardage = 0,
  });

  Map<String, dynamic> toJson() => {
        'holeNumber': holeNumber,
        'par': par,
        'strokeIndex': strokeIndex,
        'yardage': yardage,
      };

  factory HoleSessionInfo.fromJson(Map<String, dynamic> json) =>
      HoleSessionInfo(
        holeNumber: (json['holeNumber'] as num).toInt(),
        par: (json['par'] as num).toInt(),
        strokeIndex: (json['strokeIndex'] as num).toInt(),
        yardage: (json['yardage'] as num?)?.toInt() ?? 0,
      );
}

class ActiveRoundSession {
  final String? tournamentId;
  final String courseId;
  final String courseName;
  final int roundNumber;
  final DateTime datePlayed;
  final String format; // 'stroke', 'stableford', 'hybrid', 'match'
  final int pointsPerSkin;
  final List<HoleSessionInfo> holes;
  final List<PlayerSessionInfo> players;

  // State
  int currentHoleNumber;
  final Map<String, Map<int, int>> grossScores; // playerId -> holeNumber -> gross
  final Map<String, Map<int, int>> putts; // playerId -> holeNumber -> putts
  final Map<String, Set<int>> greenies; // playerId -> set of holeNumbers
  final Map<String, Set<int>> sandies; // playerId -> set of holeNumbers

  ActiveRoundSession({
    this.tournamentId,
    required this.courseId,
    required this.courseName,
    this.roundNumber = 1,
    DateTime? datePlayed,
    this.format = 'hybrid',
    this.pointsPerSkin = 1,
    required this.holes,
    required this.players,
    this.currentHoleNumber = 1,
    Map<String, Map<int, int>>? grossScores,
    Map<String, Map<int, int>>? putts,
    Map<String, Set<int>>? greenies,
    Map<String, Set<int>>? sandies,
  })  : datePlayed = datePlayed ?? DateTime.now(),
        grossScores = grossScores ?? {for (final p in players) p.playerId: {}},
        putts = putts ?? {for (final p in players) p.playerId: {}},
        greenies = greenies ?? {for (final p in players) p.playerId: {}},
        sandies = sandies ?? {for (final p in players) p.playerId: {}};

  int get holeCount => holes.length;

  HoleSessionInfo getHole(int holeNumber) {
    return holes.firstWhere(
      (h) => h.holeNumber == holeNumber,
      orElse: () => HoleSessionInfo(
        holeNumber: holeNumber,
        par: 4,
        strokeIndex: holeNumber,
      ),
    );
  }

  void setGrossScore(String playerId, int holeNumber, int score) {
    grossScores.putIfAbsent(playerId, () => {})[holeNumber] = score;
  }

  void setPutts(String playerId, int holeNumber, int count) {
    putts.putIfAbsent(playerId, () => {})[holeNumber] = count;
  }

  void toggleGreenie(String playerId, int holeNumber) {
    final set = greenies.putIfAbsent(playerId, () => {});
    if (set.contains(holeNumber)) {
      set.remove(holeNumber);
    } else {
      // Clear greenie from other players on this par 3 hole
      for (final otherP in players) {
        greenies[otherP.playerId]?.remove(holeNumber);
      }
      set.add(holeNumber);
    }
  }

  void toggleSandie(String playerId, int holeNumber) {
    final set = sandies.putIfAbsent(playerId, () => {});
    if (set.contains(holeNumber)) {
      set.remove(holeNumber);
    } else {
      set.add(holeNumber);
    }
  }

  int getGrossScore(String playerId, int holeNumber) {
    return grossScores[playerId]?[holeNumber] ?? 0;
  }

  int getPutts(String playerId, int holeNumber) {
    return putts[playerId]?[holeNumber] ?? 0;
  }

  bool hasGreenie(String playerId, int holeNumber) {
    return greenies[playerId]?.contains(holeNumber) ?? false;
  }

  bool hasSandie(String playerId, int holeNumber) {
    return sandies[playerId]?.contains(holeNumber) ?? false;
  }

  int strokesForPlayer(String playerId, int holeNumber) {
    final player = players.where((p) => p.playerId == playerId).firstOrNull;
    if (player == null) return 0;
    final hole = getHole(holeNumber);
    return ScoringCalculator.strokesForHole(
      courseHandicap: player.courseHandicap,
      strokeIndex: hole.strokeIndex,
    );
  }

  int? netScoreForPlayer(String playerId, int holeNumber) {
    final gross = getGrossScore(playerId, holeNumber);
    if (gross <= 0) return null;
    final strokes = strokesForPlayer(playerId, holeNumber);
    return ScoringCalculator.netScore(
      grossScore: gross,
      strokesReceived: strokes,
    );
  }

  int? stablefordForPlayer(String playerId, int holeNumber) {
    final net = netScoreForPlayer(playerId, holeNumber);
    if (net == null) return null;
    final hole = getHole(holeNumber);
    return ScoringCalculator.stablefordPoints(
      netScore: net,
      holePar: hole.par,
    );
  }

  int totalGross(String playerId) {
    var sum = 0;
    for (var h = 1; h <= holeCount; h++) {
      final s = getGrossScore(playerId, h);
      if (s > 0) sum += s;
    }
    return sum;
  }

  int totalNet(String playerId) {
    var sum = 0;
    for (var h = 1; h <= holeCount; h++) {
      final n = netScoreForPlayer(playerId, h);
      if (n != null) sum += n;
    }
    return sum;
  }

  int totalStableford(String playerId) {
    var sum = 0;
    for (var h = 1; h <= holeCount; h++) {
      final pts = stablefordForPlayer(playerId, h);
      if (pts != null) sum += pts;
    }
    return sum;
  }

  int totalPutts(String playerId) {
    var sum = 0;
    for (var h = 1; h <= holeCount; h++) {
      final p = getPutts(playerId, h);
      if (p > 0) sum += p;
    }
    return sum;
  }

  int completedHolesCount(String playerId) {
    var count = 0;
    for (var h = 1; h <= holeCount; h++) {
      if (getGrossScore(playerId, h) > 0) count++;
    }
    return count;
  }

  bool isHoleComplete(int holeNumber) {
    if (players.isEmpty) return false;
    return players.every((p) => getGrossScore(p.playerId, holeNumber) > 0);
  }

  bool get isRoundComplete {
    if (players.isEmpty) return false;
    for (var h = 1; h <= holeCount; h++) {
      if (!isHoleComplete(h)) return false;
    }
    return true;
  }

  Map<int, SkinResult> calculateGrossSkins({bool useCarryover = true}) {
    return ScoringCalculator.calculateSkins(
      holeCount: holeCount,
      playerIds: players.map((p) => p.playerId).toList(),
      scoresByPlayer: grossScores,
      useCarryover: useCarryover,
    );
  }

  Map<int, SkinResult> calculateNetSkins({bool useCarryover = true}) {
    final netScoresByPlayer = <String, Map<int, int>>{};
    for (final p in players) {
      final playerNet = <int, int>{};
      for (var h = 1; h <= holeCount; h++) {
        final net = netScoreForPlayer(p.playerId, h);
        if (net != null) playerNet[h] = net;
      }
      netScoresByPlayer[p.playerId] = playerNet;
    }

    return ScoringCalculator.calculateSkins(
      holeCount: holeCount,
      playerIds: players.map((p) => p.playerId).toList(),
      scoresByPlayer: netScoresByPlayer,
      useCarryover: useCarryover,
    );
  }

  Map<String, int> playerSkinsWon({bool netSkins = false}) {
    final skins = netSkins ? calculateNetSkins() : calculateGrossSkins();
    final counts = <String, int>{for (final p in players) p.playerId: 0};
    for (final s in skins.values) {
      if (s.hasWinner) {
        counts[s.winnerPlayerId!] = (counts[s.winnerPlayerId!] ?? 0) + s.skinCount;
      }
    }
    return counts;
  }

  Map<String, dynamic> toJson() => {
        'tournamentId': tournamentId,
        'courseId': courseId,
        'courseName': courseName,
        'roundNumber': roundNumber,
        'datePlayed': datePlayed.toIso8601String(),
        'format': format,
        'pointsPerSkin': pointsPerSkin,
        'currentHoleNumber': currentHoleNumber,
        'holes': holes.map((h) => h.toJson()).toList(),
        'players': players.map((p) => p.toJson()).toList(),
        'grossScores': {
          for (final entry in grossScores.entries)
            entry.key: {
              for (final hEntry in entry.value.entries)
                hEntry.key.toString(): hEntry.value
            }
        },
        'putts': {
          for (final entry in putts.entries)
            entry.key: {
              for (final hEntry in entry.value.entries)
                hEntry.key.toString(): hEntry.value
            }
        },
        'greenies': {
          for (final entry in greenies.entries)
            entry.key: entry.value.toList()
        },
        'sandies': {
          for (final entry in sandies.entries)
            entry.key: entry.value.toList()
        },
      };

  factory ActiveRoundSession.fromJson(Map<String, dynamic> json) {
    final holes = (json['holes'] as List<dynamic>)
        .map((h) => HoleSessionInfo.fromJson(h as Map<String, dynamic>))
        .toList();
    final players = (json['players'] as List<dynamic>)
        .map((p) => PlayerSessionInfo.fromJson(p as Map<String, dynamic>))
        .toList();

    final rawGross = json['grossScores'] as Map<String, dynamic>? ?? {};
    final parsedGross = <String, Map<int, int>>{};
    for (final pEntry in rawGross.entries) {
      final holeMap = pEntry.value as Map<String, dynamic>;
      parsedGross[pEntry.key] = {
        for (final hEntry in holeMap.entries)
          int.parse(hEntry.key): (hEntry.value as num).toInt()
      };
    }

    final rawPutts = json['putts'] as Map<String, dynamic>? ?? {};
    final parsedPutts = <String, Map<int, int>>{};
    for (final pEntry in rawPutts.entries) {
      final holeMap = pEntry.value as Map<String, dynamic>;
      parsedPutts[pEntry.key] = {
        for (final hEntry in holeMap.entries)
          int.parse(hEntry.key): (hEntry.value as num).toInt()
      };
    }

    final rawGreenies = json['greenies'] as Map<String, dynamic>? ?? {};
    final parsedGreenies = <String, Set<int>>{};
    for (final gEntry in rawGreenies.entries) {
      final list = (gEntry.value as List<dynamic>).map((e) => (e as num).toInt());
      parsedGreenies[gEntry.key] = list.toSet();
    }

    final rawSandies = json['sandies'] as Map<String, dynamic>? ?? {};
    final parsedSandies = <String, Set<int>>{};
    for (final sEntry in rawSandies.entries) {
      final list = (sEntry.value as List<dynamic>).map((e) => (e as num).toInt());
      parsedSandies[sEntry.key] = list.toSet();
    }

    return ActiveRoundSession(
      tournamentId: json['tournamentId'] as String?,
      courseId: json['courseId'] as String,
      courseName: json['courseName'] as String,
      roundNumber: (json['roundNumber'] as num?)?.toInt() ?? 1,
      datePlayed: DateTime.parse(json['datePlayed'] as String),
      format: json['format'] as String? ?? 'hybrid',
      pointsPerSkin: (json['pointsPerSkin'] as num?)?.toInt() ?? 1,
      holes: holes,
      players: players,
      currentHoleNumber: (json['currentHoleNumber'] as num?)?.toInt() ?? 1,
      grossScores: parsedGross,
      putts: parsedPutts,
      greenies: parsedGreenies,
      sandies: parsedSandies,
    );
  }
}
