import '../../../database/app_database.dart';
import '../../../shared/utils/course_handicap_calculator.dart';
import 'birdie_pot_models.dart';
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
  final int foursomeGroup; // 1 or 2
  final String twoManTeamId; // 'T1', 'T2', 'T3', 'T4', or 'none'
  final String? twoManTeamName;

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
    this.foursomeGroup = 1,
    this.twoManTeamId = 'none',
    this.twoManTeamName,
  });

  PlayerSessionInfo copyWith({
    String? playerId,
    String? name,
    String? nickname,
    String? initials,
    double? handicapIndex,
    String? teeBoxId,
    String? teeName,
    int? courseHandicap,
    String? teamId,
    int? foursomeGroup,
    String? twoManTeamId,
    String? twoManTeamName,
  }) {
    return PlayerSessionInfo(
      playerId: playerId ?? this.playerId,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      initials: initials ?? this.initials,
      handicapIndex: handicapIndex ?? this.handicapIndex,
      teeBoxId: teeBoxId ?? this.teeBoxId,
      teeName: teeName ?? this.teeName,
      courseHandicap: courseHandicap ?? this.courseHandicap,
      teamId: teamId ?? this.teamId,
      foursomeGroup: foursomeGroup ?? this.foursomeGroup,
      twoManTeamId: twoManTeamId ?? this.twoManTeamId,
      twoManTeamName: twoManTeamName ?? this.twoManTeamName,
    );
  }

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
        'foursomeGroup': foursomeGroup,
        'twoManTeamId': twoManTeamId,
        'twoManTeamName': twoManTeamName,
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
        foursomeGroup: (json['foursomeGroup'] as num?)?.toInt() ?? 1,
        twoManTeamId: json['twoManTeamId'] as String? ?? json['teamId'] as String? ?? 'none',
        twoManTeamName: json['twoManTeamName'] as String?,
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
  String? savedRoundId; // If non-null, editing an existing saved round
  final String courseId;
  final String courseName;
  final int roundNumber;
  final DateTime datePlayed;
  final String format; // 'stroke', 'stableford', 'hybrid', 'match'
  final bool isFinalRound; // If true, modified Stableford rules apply (-1 double bogey, 0 bogey, +1 par, +2 birdie)
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
    this.savedRoundId,
    required this.courseId,
    required this.courseName,
    this.roundNumber = 1,
    DateTime? datePlayed,
    this.format = 'hybrid',
    this.isFinalRound = false,
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

  void updatePlayerTeeAndHandicap({
    required String playerId,
    required String teeName,
    required double handicapIndex,
    required int newCourseHandicap,
    String? teeBoxId,
  }) {
    final idx = players.indexWhere((p) => p.playerId == playerId);
    if (idx != -1) {
      final p = players[idx];
      players[idx] = p.copyWith(
        teeName: teeName,
        teeBoxId: teeBoxId ?? teeName.toLowerCase(),
        handicapIndex: handicapIndex,
        courseHandicap: newCourseHandicap,
      );
    }
  }

  /// Automatically synchronizes all player session profiles with the latest roster data from the database.
  /// Refreshes names, nicknames, initials, handicap indexes, course handicaps, and 2-man team labels.
  bool syncWithRoster(List<Player> latestPlayers) {
    if (latestPlayers.isEmpty) return false;
    bool changed = false;
    final updatedPlayers = <PlayerSessionInfo>[];

    for (final psi in players) {
      final match = latestPlayers.where((p) => p.id == psi.playerId).firstOrNull;
      if (match != null) {
        final newNickname = match.nickname.isNotEmpty ? match.nickname : match.fullName.split(' ').first;
        final newInitials = match.initials;

        // Recalculate course handicap if index changed
        int newCourseHcp = psi.courseHandicap;
        if (match.handicapIndex != psi.handicapIndex) {
          newCourseHcp = CourseHandicapCalculator.forCourse(
            courseName: courseName,
            handicapIndex: match.handicapIndex,
            tee: psi.teeName,
          );
        }

        if (psi.name != match.fullName ||
            psi.nickname != newNickname ||
            psi.initials != newInitials ||
            psi.handicapIndex != match.handicapIndex ||
            psi.courseHandicap != newCourseHcp) {
          changed = true;
          updatedPlayers.add(psi.copyWith(
            name: match.fullName,
            nickname: newNickname,
            initials: newInitials,
            handicapIndex: match.handicapIndex,
            courseHandicap: newCourseHcp,
          ));
        } else {
          updatedPlayers.add(psi);
        }
      } else {
        updatedPlayers.add(psi);
      }
    }

    if (changed) {
      players.clear();
      players.addAll(updatedPlayers);
      _refreshTwoManTeamNames();
    }
    return changed;
  }

  void _refreshTwoManTeamNames() {
    final byTeam = <String, List<PlayerSessionInfo>>{};
    for (final p in players) {
      if (p.twoManTeamId != 'none' && p.twoManTeamId.isNotEmpty) {
        byTeam.putIfAbsent(p.twoManTeamId, () => []).add(p);
      }
    }

    for (final entry in byTeam.entries) {
      if (entry.value.length >= 2) {
        final teamName = '${entry.value[0].nickname} & ${entry.value[1].nickname}';
        for (var i = 0; i < players.length; i++) {
          if (players[i].twoManTeamId == entry.key) {
            players[i] = players[i].copyWith(twoManTeamName: teamName);
          }
        }
      }
    }
  }

  /// Adds a golfer from the current roster to this active round session if not already participating.
  bool addPlayerFromRoster(
    Player player, {
    required String teeName,
    required String teeBoxId,
    int? courseHandicap,
    String teamId = 'none',
    int foursomeGroup = 1,
    String twoManTeamId = 'none',
    String? twoManTeamName,
  }) {
    if (players.any((p) => p.playerId == player.id)) return false;

    final ch = courseHandicap ??
        CourseHandicapCalculator.forCourse(
          courseName: courseName,
          handicapIndex: player.handicapIndex,
          tee: teeName,
        );

    final nickname = player.nickname.isNotEmpty ? player.nickname : player.fullName.split(' ').first;

    players.add(
      PlayerSessionInfo(
        playerId: player.id,
        name: player.fullName,
        nickname: nickname,
        initials: player.initials,
        handicapIndex: player.handicapIndex,
        teeBoxId: teeBoxId,
        teeName: teeName,
        courseHandicap: ch,
        teamId: teamId,
        foursomeGroup: foursomeGroup,
        twoManTeamId: twoManTeamId,
        twoManTeamName: twoManTeamName,
      ),
    );

    // Initialize score containers
    grossScores.putIfAbsent(player.id, () => {});
    putts.putIfAbsent(player.id, () => {});
    greenies.putIfAbsent(player.id, () => {});
    sandies.putIfAbsent(player.id, () => {});

    return true;
  }

  int get holeCount => holes.length;
  bool get isShortCourse => holeCount != 18;

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
      isModifiedFinalRound: isFinalRound,
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

  int frontNineGross(String playerId) {
    var sum = 0;
    final end = holeCount >= 9 ? 9 : holeCount;
    for (var h = 1; h <= end; h++) {
      final s = getGrossScore(playerId, h);
      if (s > 0) sum += s;
    }
    return sum;
  }

  int backNineGross(String playerId) {
    var sum = 0;
    for (var h = 10; h <= holeCount; h++) {
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

  // --- 2-MAN TEAM STABLEFORD SCORING ---

  /// Finds all players belonging to a two-man team
  List<PlayerSessionInfo> playersForTeam(String teamId) {
    return players
        .where((p) =>
            p.twoManTeamId == teamId ||
            (p.twoManTeamId == 'none' && p.teamId == teamId))
        .toList();
  }

  /// Calculates the 2-man team Stableford score for a hole (Best Ball Stableford)
  int? teamStablefordForHole(String teamId, int holeNumber) {
    final members = playersForTeam(teamId);
    if (members.isEmpty) return null;

    int? bestPts;
    for (final m in members) {
      final pts = stablefordForPlayer(m.playerId, holeNumber);
      if (pts != null) {
        if (bestPts == null || pts > bestPts) {
          bestPts = pts;
        }
      }
    }
    return bestPts;
  }

  /// Calculates total Stableford points for the 2-man team
  int totalTeamStableford(String teamId) {
    var sum = 0;
    for (var h = 1; h <= holeCount; h++) {
      final pts = teamStablefordForHole(teamId, h);
      if (pts != null) sum += pts;
    }
    return sum;
  }

  /// Effective Stableford points for this player:
  /// Under Arcadia rules, if the player is on a 2-man team, each teammate records
  /// the 2-man team's Stableford score for that round.
  /// Courses with fewer than 18 holes are short courses and do not count toward Stableford.
  int effectivePlayerStableford(String playerId) {
    if (isShortCourse) return 0;
    final p = players.where((x) => x.playerId == playerId).firstOrNull;
    if (p == null) return 0;
    final teamId = p.twoManTeamId != 'none' ? p.twoManTeamId : p.teamId;
    if (teamId != 'none') {
      return totalTeamStableford(teamId);
    }
    return totalStableford(playerId);
  }

  /// Birdie Pot for this round
  RoundBirdiePot roundBirdiePot({int totalFieldSize = 8}) {
    return RoundBirdiePot.calculate(this, totalFieldSize: totalFieldSize);
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
    for (final p in players) {
      if (getGrossScore(p.playerId, holeNumber) <= 0) return false;
    }
    return true;
  }

  bool get isRoundComplete {
    for (final p in players) {
      for (var h = 1; h <= holeCount; h++) {
        if (getGrossScore(p.playerId, h) <= 0) return false;
      }
    }
    return true;
  }

  Map<String, int> playerSkinsWon({bool netSkins = false}) => totalSkinsByPlayer();

  Map<int, SkinResult> calculateSkins() {
    return ScoringCalculator.calculateSkins(
      holeCount: holeCount,
      playerIds: players.map((p) => p.playerId).toList(),
      scoresByPlayer: grossScores,
      useCarryover: true,
    );
  }

  Map<String, int> totalSkinsByPlayer() {
    final skins = calculateSkins();
    final counts = {for (final p in players) p.playerId: 0};
    for (final skin in skins.values) {
      if (skin.isComplete && skin.winnerPlayerId != null) {
        counts[skin.winnerPlayerId!] =
            (counts[skin.winnerPlayerId!] ?? 0) + skin.skinCount;
      }
    }
    return counts;
  }

  Map<String, dynamic> toJson() => {
        if (tournamentId != null) 'tournamentId': tournamentId,
        if (savedRoundId != null) 'savedRoundId': savedRoundId,
        'courseId': courseId,
        'courseName': courseName,
        'roundNumber': roundNumber,
        'datePlayed': datePlayed.toIso8601String(),
        'format': format,
        'isFinalRound': isFinalRound,
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
      savedRoundId: json['savedRoundId'] as String?,
      courseId: json['courseId'] as String,
      courseName: json['courseName'] as String,
      roundNumber: (json['roundNumber'] as num?)?.toInt() ?? 1,
      datePlayed: DateTime.parse(json['datePlayed'] as String),
      format: json['format'] as String? ?? 'hybrid',
      isFinalRound: json['isFinalRound'] as bool? ?? false,
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
