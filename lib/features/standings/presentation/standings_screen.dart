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
            icon: const Icon(Icons.share, color: AppColors.goldLight),
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
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cardBorder, width: 2),
                      ),
                      child: const Icon(
                        Icons.military_tech_outlined,
                        size: 56,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Rounds Recorded Yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Once you tee off and complete rounds, overall trip leaderboards, skins, and team standings will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 14),
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
              // Segmented Filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: const Color(0xFF061812),
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
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.gold,
        backgroundColor: AppColors.cardDark,
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (sel) {
          if (sel) setState(() => _activeTab = key);
        },
      ),
    );
  }

  Widget _buildSelectedTabContent(List<ActiveRoundSession> sessions, int roundCount) {
    // Gather all distinct players across sessions
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
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${idx + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: idx == 0 ? AppColors.gold : Colors.white70,
                  ),
                ),
                const SizedBox(width: 10),
                PlayerAvatar(initials: p.initials, radius: 18),
              ],
            ),
            title: Text(
              p.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Avg Net: $avgNet across $roundCount rounds'),
            trailing: Text(
              'Net $totalNet',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.goldLight,
              ),
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
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${idx + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: idx == 0 ? AppColors.gold : Colors.white70,
                  ),
                ),
                const SizedBox(width: 10),
                PlayerAvatar(initials: p.initials, radius: 18),
              ],
            ),
            title: Text(
              p.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Stableford Championship Points'),
            trailing: Text(
              '$totalPts pts',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.goldLight,
              ),
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
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${idx + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: idx == 0 ? AppColors.gold : Colors.white70,
                  ),
                ),
                const SizedBox(width: 10),
                PlayerAvatar(initials: p.initials, radius: 18),
              ],
            ),
            title: Text(
              p.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Gross Strokes Total'),
            trailing: Text(
              '$totalGross',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.goldLight,
              ),
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
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${idx + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: idx == 0 ? AppColors.gold : Colors.white70,
                  ),
                ),
                const SizedBox(width: 10),
                PlayerAvatar(initials: p.initials, radius: 18),
              ],
            ),
            title: Text(
              p.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Cumulative Skins Won'),
            trailing: Text(
              '$count Skin${count == 1 ? '' : 's'}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: AppColors.gold,
              ),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.teamA.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.teamA),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.shield, color: AppColors.teamA, size: 36),
                      const SizedBox(height: 6),
                      const Text(
                        'TEAM BLUE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$teamAPts',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.teamA,
                        ),
                      ),
                      const Text(
                        'Total Points',
                        style: TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.teamB.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.teamB),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.shield, color: AppColors.teamB, size: 36),
                      const SizedBox(height: 6),
                      const Text(
                        'TEAM RED',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$teamBPts',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.teamB,
                        ),
                      ),
                      const Text(
                        'Total Points',
                        style: TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Points are calculated from cumulative Stableford scoring across all completed trip rounds for each team roster.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13),
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
