import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../database/app_database.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/player_avatar.dart';
import '../../players/repository/player_repository.dart';
import '../../rounds/models/active_round_session.dart';
import '../../rounds/models/birdie_pot_models.dart';
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
  String _activeTab = 'stableford'; // 'stableford', 'birdie_pot', 'net', 'gross', 'skins', 'teams'

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
                      'Once you tee off and complete rounds, overall trip leaderboards, skins, 2-man Stableford, and Birdie Pot standings will appear here.',
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
                      width: 54,
                      height: 54,
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
                            '${rounds.length} ${rounds.length == 1 ? 'Round' : 'Rounds'} Completed • 2-Man Stableford',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
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
                      _buildTabChip('stableford', '🏆 Arcadia Cup'),
                      _buildTabChip('birdie_pot', '💰 Birdie Pot (\$)'),
                      _buildTabChip('net', 'Net Total'),
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
          fontSize: 16,
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

    if (_activeTab == 'stableford') {
      return _buildStablefordLeaderboard(sessions, players, roundCount);
    } else if (_activeTab == 'birdie_pot') {
      return _buildBirdiePotLeaderboard(sessions, players);
    } else if (_activeTab == 'net') {
      return _buildNetLeaderboard(sessions, players, roundCount);
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
                        'Total Net ($roundCount rounds)',
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
    final roundBreakdown = <String, List<int>>{};

    for (final p in players) {
      var ptsSum = 0;
      final list = <int>[];
      for (final s in sessions) {
        final pPts = s.effectivePlayerStableford(p.playerId);
        ptsSum += pPts;
        list.add(pPts);
      }
      stats[p.playerId] = ptsSum;
      roundBreakdown[p.playerId] = list;
    }

    final sorted = List<PlayerSessionInfo>.from(players)
      ..sort((a, b) => (stats[b.playerId] ?? 0).compareTo(stats[a.playerId] ?? 0));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Tournament Format Info Header
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F241A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.duneSand.withValues(alpha: 0.5)),
          ),
          child: const Row(
            children: [
              Icon(Icons.emoji_events, color: AppColors.duneSand, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '2-MAN BEST BALL STABLEFORD',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.cyanLight, letterSpacing: 1.1),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Each golfer records their 2-man team\'s Stableford score for the round. Ranked #1 through #8 for the Final Round Draft!',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        ...sorted.asMap().entries.map((entry) {
          final idx = entry.key;
          final p = entry.value;
          final totalPts = stats[p.playerId] ?? 0;
          final breakdown = roundBreakdown[p.playerId] ?? [];

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Text(
                    '#${idx + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      color: idx == 0
                          ? AppColors.duneSand
                          : (idx < 4 ? AppColors.lakeCyan : Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 14),
                  PlayerAvatar(initials: p.initials, radius: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                p.nickname.isNotEmpty ? p.nickname : p.name,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (idx < 4) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.lakeCyan.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Top 4 Captain',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.lakeCyan),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        if (breakdown.isNotEmpty)
                          Text(
                            breakdown.asMap().entries.map((e) => 'R${e.key + 1}: ${e.value}p').join(' • '),
                            style: const TextStyle(fontSize: 13, color: Colors.white60, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$totalPts pts',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: AppColors.duneSand,
                        ),
                      ),
                      Text(
                        'Seed #${idx + 1}',
                        style: const TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBirdiePotLeaderboard(
    List<ActiveRoundSession> sessions,
    List<PlayerSessionInfo> players,
  ) {
    final ledger = TripBirdiePotLedger.calculate(sessions);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Hero Cumulative Pot Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E2206), Color(0xFF130E02)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5C07B), width: 1.8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE5C07B).withValues(alpha: 0.15),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5C07B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5C07B)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.monetization_on, color: Color(0xFFE5C07B), size: 16),
                        SizedBox(width: 4),
                        Text(
                          'TRIP CUMULATIVE POT',
                          style: TextStyle(
                            color: Color(0xFFE5C07B),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${ledger.totalTripBirdies} Total Birdies',
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '\$${ledger.totalCumulativePot.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFF7D98C),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              if (ledger.tripWinnerNames.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Color(0xFFE5C07B), size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reigning Leader: ${ledger.tripWinnerNames.join(' & ')} (Hole ${ledger.tripWinningHole}, Round ${ledger.tripWinningRoundNumber})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                if (ledger.tripWinnerNames.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Tied on last hole! Pot splits evenly (\$${ledger.payoutPerTripWinner.toStringAsFixed(0)} each).',
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ),
              ] else
                const Text(
                  'No birdies recorded yet. \$2/birdie per player (\$1 Round Pot, \$1 Cumulative Pot). Last birdie wins!',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Cash Ledger Table Card
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PLAYER CASH LEDGER',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        color: AppColors.cyanLight,
                      ),
                    ),
                    Text(
                      '\$2 / Birdie',
                      style: TextStyle(color: AppColors.duneSand, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: Text('Golfer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70))),
                      Expanded(flex: 2, child: Text('Birdies', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70))),
                      Expanded(flex: 2, child: Text('Dues', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70))),
                      Expanded(flex: 2, child: Text('Won', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70))),
                      Expanded(flex: 2, child: Text('Net', textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70))),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                ...ledger.playerLedgers.values.map((pl) {
                  final isNetPositive = pl.netBalance >= 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            pl.playerName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${pl.totalBirdiesMade}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '-\$${pl.totalDuesOwed.toStringAsFixed(0)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '\$${pl.totalWon.toStringAsFixed(0)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${isNetPositive ? '+' : ''}\$${pl.netBalance.toStringAsFixed(0)}',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              color: isNetPositive ? Colors.greenAccent : Colors.redAccent,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Round-by-Round Pot Results
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            'ROUND-BY-ROUND POTS',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              color: AppColors.cyanLight,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...ledger.roundPots.map((rp) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ROUND ${rp.roundNumber}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    Text(
                      '${rp.totalBirdies} Birdies • \$${rp.roundPotTotal.toStringAsFixed(0)} Pot',
                      style: const TextStyle(color: AppColors.duneSand, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (rp.hasBirdies) ...[
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.lakeCyan, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Won by ${rp.winnerNames.join(', ')} (Hole ${rp.lastBirdieHole}) — \$${rp.payoutPerWinner.toStringAsFixed(0)} each',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ] else
                  const Text('No birdies made in this round.', style: TextStyle(color: Colors.white60, fontSize: 13)),
              ],
            ),
          );
        }),
      ],
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
                      Text(
                        'Total Gross ($roundCount rounds)',
                        style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$totalGross',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
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
    final skinsMap = <String, int>{};
    for (final s in sessions) {
      final sMap = s.totalSkinsByPlayer();
      for (final entry in sMap.entries) {
        skinsMap[entry.key] = (skinsMap[entry.key] ?? 0) + entry.value;
      }
    }

    final sorted = List<PlayerSessionInfo>.from(players)
      ..sort((a, b) => (skinsMap[b.playerId] ?? 0).compareTo(skinsMap[a.playerId] ?? 0));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sorted.length,
      itemBuilder: (context, idx) {
        final p = sorted[idx];
        final totalSkins = skinsMap[p.playerId] ?? 0;

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
                        'Total Skins Won',
                        style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$totalSkins skins',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
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
    return FutureBuilder<Tournament?>(
      future: widget.tournamentRepository.getActiveTournament(),
      builder: (context, snapshot) {
        final tournament = snapshot.data;
        final teamAName = tournament?.teamAName ?? 'Team Blue';
        final teamBName = tournament?.teamBName ?? 'Team Red';

        var teamAPts = 0;
        var teamBPts = 0;

        for (final s in sessions) {
          for (final p in s.players) {
            final pts = s.effectivePlayerStableford(p.playerId);
            if (p.teamId.toLowerCase() == 'a') teamAPts += pts;
            if (p.teamId.toLowerCase() == 'b') teamBPts += pts;
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.teamA.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.teamA, width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          teamAName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$teamAPts',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: AppColors.teamA,
                          ),
                        ),
                        const Text('Total Points', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.teamB.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.teamB, width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          teamBName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$teamBPts',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: AppColors.teamB,
                          ),
                        ),
                        const Text('Total Points', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
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

    buffer.writeln('🎯 ARCADIA CUP (2-MAN STABLEFORD):');
    final ptsStats = <String, int>{};
    for (final p in playerMap.values) {
      var ptsSum = 0;
      for (final s in sessions) {
        ptsSum += s.effectivePlayerStableford(p.playerId);
      }
      ptsStats[p.playerId] = ptsSum;
    }

    final sortedPts = playerMap.values.toList()
      ..sort((a, b) => (ptsStats[b.playerId] ?? 0).compareTo(ptsStats[a.playerId] ?? 0));

    for (var i = 0; i < sortedPts.length; i++) {
      final p = sortedPts[i];
      buffer.writeln('${i + 1}. ${p.nickname}: ${ptsStats[p.playerId]} pts');
    }

    buffer.writeln('');
    buffer.writeln('💰 BIRDIE POT:');
    final ledger = TripBirdiePotLedger.calculate(sessions);
    buffer.writeln('Trip Cumulative Pot: \$${ledger.totalCumulativePot.toStringAsFixed(0)}');
    if (ledger.tripWinnerNames.isNotEmpty) {
      buffer.writeln('Reigning Leader: ${ledger.tripWinnerNames.join(' & ')} (Hole ${ledger.tripWinningHole}, Round ${ledger.tripWinningRoundNumber})');
    }

    Share.share(buffer.toString());
  }
}
