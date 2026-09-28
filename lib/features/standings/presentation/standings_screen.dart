import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../database/app_database.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/player_avatar.dart';
import '../../players/repository/player_repository.dart';
import '../../rounds/models/active_round_session.dart';
import '../../rounds/repository/round_repository.dart';
import '../../tournaments/repository/tournament_repository.dart';

class StandingsScreen extends StatefulWidget {
  final RoundRepository roundRepository;
  final PlayerRepository playerRepository;
  final TournamentRepository tournamentRepository;

  const StandingsScreen({
    super.key,
    required this.roundRepository,
    required this.playerRepository,
    required this.tournamentRepository,
  });

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  String _activeTab = 'net'; // 'net', 'stableford', 'gross', 'skins', 'teams'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Standings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.cyanLight, size: 28),
            tooltip: 'Share Standings',
            onPressed: () => _shareOverallStandings(),
          ),
        ],
      ),
      body: StreamBuilder<List<SavedRound>>(
        stream: widget.roundRepository.watchSavedRounds(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rounds = snapshot.data!;
          if (rounds.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cardBorder, width: 2),
                      ),
                      child: const Icon(
                        Icons.military_tech_outlined,
                        size: 64,
                        color: AppColors.lakeCyan,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Rounds Recorded Yet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Once you tee off and complete rounds, overall trip leaderboards, skins, and team standings will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 18, height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          }

          // Parse sessions
          final sessions = <ActiveRoundSession>[];
          for (final r in rounds) {
            try {
              final map = jsonDecode(r.roundPayloadJson) as Map<String, dynamic>;
              sessions.add(ActiveRoundSession.fromJson(map));
            } catch (_) {}
          }

          return Column(
            children: [
              // Championship Graphical Header Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B192A),
                  border: const Border(
                    bottom: BorderSide(color: AppColors.cardBorder, width: 1.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.duneSand, width: 1.8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.duneSand.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/arcadia_cup_crest.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ARCADIA COASTAL CUP',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: AppColors.cyanLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Official Trip Standings • ${rounds.length} Round${rounds.length == 1 ? '' : 's'} Scored',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.duneSand,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Segmented Filter with Extra Large Chips
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                color: AppColors.appBarDark,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTabChip('net', 'Net Total'),
                      _buildTabChip('stableford', 'Stableford'),
                      _buildTabChip('gross', 'Gross Total'),
                      _buildTabChip('skins', 'Skins'),
                      _buildTabChip('teams', 'Teams (4v4)'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _buildSelectedTabContent(sessions, rounds.length),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabChip(String key, String label) {
    final isSelected = _activeTab == key;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.lakeCyan,
        backgroundColor: AppColors.surfaceElevated,
        side: BorderSide(
          color: isSelected ? AppColors.lakeCyan : AppColors.cardBorder,
          width: isSelected ? 2 : 1,
        ),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF06111D) : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
          fontSize: 17,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        onSelected: (sel) {
          if (sel) setState(() => _activeTab = key);
        },
      ),
    );
  }

  Widget _buildSelectedTabContent(List<ActiveRoundSession> sessions, int roundCount) {
    final playerMap = <String, PlayerSessionInfo>{};
    for (final s in sessions) {
      for (final p in s.players) {
        playerMap[p.playerId] = p;
      }
    }

    final players = playerMap.values.toList();

    if (_activeTab == 'net') {
      return _buildNetLeaderboard(sessions, players, roundCount);
    } else if (_activeTab == 'stableford') {
      return _buildStablefordLeaderboard(sessions, players, roundCount);
    } else if (_activeTab == 'gross') {
      return _buildGrossLeaderboard(sessions, players, roundCount);
    } else if (_activeTab == 'skins') {
      return _buildSkinsLeaderboard(sessions, players);
    } else {
      return _buildTeamsLeaderboard(sessions, players);
    }
  }

  Widget _buildNetLeaderboard(
    List<ActiveRoundSession> sessions,
    List<PlayerSessionInfo> players,
    int roundCount,
  ) {
    final stats = <String, int>{};
    for (final p in players) {
      var netSum = 0;
      for (final s in sessions) {
        netSum += s.totalNet(p.playerId);
      }
      stats[p.playerId] = netSum;
    }

    final sorted = List<PlayerSessionInfo>.from(players)
      ..sort((a, b) => (stats[a.playerId] ?? 0).compareTo(stats[b.playerId] ?? 0));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sorted.length,
      itemBuilder: (context, idx) {
        final p = sorted[idx];
        final totalNet = stats[p.playerId] ?? 0;
        final avgNet = roundCount > 0 ? (totalNet / roundCount).toStringAsFixed(1) : '0';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Text(
                  '${idx + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    color: idx == 0 ? AppColors.lakeCyan : Colors.white70,
                  ),
                ),
                const SizedBox(width: 14),
                PlayerAvatar(initials: p.initials, radius: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Avg Net: $avgNet • $roundCount rounds',
                        style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Net $totalNet',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: AppColors.lakeCyan,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStablefordLeaderboard(
    List<ActiveRoundSession> sessions,
    List<PlayerSessionInfo> players,
    int roundCount,
  ) {
    final stats = <String, int>{};
    for (final p in players) {
      var ptsSum = 0;
      for (final s in sessions) {
        ptsSum += s.totalStableford(p.playerId);
      }
      stats[p.playerId] = ptsSum;
    }

    final sorted = List<PlayerSessionInfo>.from(players)
      ..sort((a, b) => (stats[b.playerId] ?? 0).compareTo(stats[a.playerId] ?? 0));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sorted.length,
      itemBuilder: (context, idx) {
        final p = sorted[idx];
        final totalPts = stats[p.playerId] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Text(
                  '${idx + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    color: idx == 0 ? AppColors.duneSand : Colors.white70,
                  ),
                ),
                const SizedBox(width: 14),
                PlayerAvatar(initials: p.initials, radius: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Stableford Points',
                        style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$totalPts pts',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: AppColors.duneSand,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrossLeaderboard(
    List<ActiveRoundSession> sessions,
    List<PlayerSessionInfo> players,
    int roundCount,
  ) {
    final stats = <String, int>{};
    for (final p in players) {
      var grossSum = 0;
      for (final s in sessions) {
        grossSum += s.totalGross(p.playerId);
      }
      stats[p.playerId] = grossSum;
    }

    final sorted = List<PlayerSessionInfo>.from(players)
      ..sort((a, b) => (stats[a.playerId] ?? 0).compareTo(stats[b.playerId] ?? 0));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sorted.length,
      itemBuilder: (context, idx) {
        final p = sorted[idx];
        final totalGross = stats[p.playerId] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Text(
                  '${idx + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    color: idx == 0 ? AppColors.lakeCyan : Colors.white70,
                  ),
                ),
                const SizedBox(width: 14),
                PlayerAvatar(initials: p.initials, radius: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Total Gross Strokes',
                        style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$totalGross',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkinsLeaderboard(
    List<ActiveRoundSession> sessions,
    List<PlayerSessionInfo> players,
  ) {
    final skinCounts = <String, int>{};
    for (final p in players) {
      var total = 0;
      for (final s in sessions) {
        final won = s.playerSkinsWon();
        total += won[p.playerId] ?? 0;
      }
      skinCounts[p.playerId] = total;
    }

    final sorted = List<PlayerSessionInfo>.from(players)
      ..sort((a, b) =>
          (skinCounts[b.playerId] ?? 0).compareTo(skinCounts[a.playerId] ?? 0));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sorted.length,
      itemBuilder: (context, idx) {
        final p = sorted[idx];
        final count = skinCounts[p.playerId] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Text(
                  '${idx + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    color: idx == 0 ? AppColors.lakeCyan : Colors.white70,
                  ),
                ),
                const SizedBox(width: 14),
                PlayerAvatar(initials: p.initials, radius: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Cumulative Skins Won',
                        style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$count Skin${count == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: AppColors.lakeCyan,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamsLeaderboard(
    List<ActiveRoundSession> sessions,
    List<PlayerSessionInfo> players,
  ) {
    var teamAPts = 0;
    var teamBPts = 0;

    for (final s in sessions) {
      for (final p in s.players) {
        final pts = s.totalStableford(p.playerId);
        if (p.teamId == 'a') {
          teamAPts += pts;
        } else if (p.teamId == 'b') {
          teamBPts += pts;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.teamA.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.teamA, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.shield, color: AppColors.teamA, size: 44),
                      const SizedBox(height: 8),
                      const Text(
                        'TEAM BLUE',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$teamAPts',
                        style: const TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                          color: AppColors.teamA,
                        ),
                      ),
                      const Text(
                        'Total Points',
                        style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.teamB.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.teamB, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.shield, color: AppColors.teamB, size: 44),
                      const SizedBox(height: 8),
                      const Text(
                        'TEAM RED',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$teamBPts',
                        style: const TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                          color: AppColors.teamB,
                        ),
                      ),
                      const Text(
                        'Total Points',
                        style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          const Text(
            'Points are calculated from cumulative Stableford scoring across all completed trip rounds for each team roster.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
          ),
        ],
      ),
    );
  }

  void _shareOverallStandings() async {
    final rounds = await widget.roundRepository.getAllSavedRounds();
    if (rounds.isEmpty) return;

    final sessions = <ActiveRoundSession>[];
    for (final r in rounds) {
      try {
        final map = jsonDecode(r.roundPayloadJson) as Map<String, dynamic>;
        sessions.add(ActiveRoundSession.fromJson(map));
      } catch (_) {}
    }

    final playerMap = <String, PlayerSessionInfo>{};
    for (final s in sessions) {
      for (final p in s.players) {
        playerMap[p.playerId] = p;
      }
    }

    final buffer = StringBuffer();
    buffer.writeln('🏆 Arcadia Golf Trip - Overall Standings (${rounds.length} Rounds)');
    buffer.writeln('');
    buffer.writeln('🥇 NET CHAMPIONSHIP:');

    final netStats = <String, int>{};
    for (final p in playerMap.values) {
      var netSum = 0;
      for (final s in sessions) {
        netSum += s.totalNet(p.playerId);
      }
      netStats[p.playerId] = netSum;
    }

    final sortedNet = playerMap.values.toList()
      ..sort((a, b) => (netStats[a.playerId] ?? 0).compareTo(netStats[b.playerId] ?? 0));

    for (var i = 0; i < sortedNet.length; i++) {
      final p = sortedNet[i];
      buffer.writeln('${i + 1}. ${p.nickname}: Net ${netStats[p.playerId]}');
    }

    buffer.writeln('');
    buffer.writeln('🎯 STABLEFORD POINTS:');
    final ptsStats = <String, int>{};
    for (final p in playerMap.values) {
      var ptsSum = 0;
      for (final s in sessions) {
        ptsSum += s.totalStableford(p.playerId);
      }
      ptsStats[p.playerId] = ptsSum;
    }

    final sortedPts = playerMap.values.toList()
      ..sort((a, b) => (ptsStats[b.playerId] ?? 0).compareTo(ptsStats[a.playerId] ?? 0));

    for (var i = 0; i < sortedPts.length; i++) {
      final p = sortedPts[i];
      buffer.writeln('${i + 1}. ${p.nickname}: ${ptsStats[p.playerId]} pts');
    }

    Share.share(buffer.toString());
  }
}
