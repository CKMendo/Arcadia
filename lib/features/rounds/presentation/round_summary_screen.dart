import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../database/app_database.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/player_avatar.dart';
import '../models/active_round_session.dart';
import '../repository/round_repository.dart';
import 'active_scoring_screen.dart';

class RoundSummaryScreen extends StatelessWidget {
  final RoundRepository roundRepository;
  final String roundId;

  const RoundSummaryScreen({
    super.key,
    required this.roundRepository,
    required this.roundId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SavedRound?>(
      future: roundRepository.getRoundById(roundId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final round = snapshot.data!;
        final map = jsonDecode(round.roundPayloadJson) as Map<String, dynamic>;
        final session = ActiveRoundSession.fromJson(map);

        final sortedPlayers = List<PlayerSessionInfo>.from(session.players)
          ..sort((a, b) =>
              session.effectivePlayerStableford(b.playerId).compareTo(session.effectivePlayerStableford(a.playerId)));

        final skins = session.calculateSkins();
        final skinsWon = session.totalSkinsByPlayer();
        final birdiePot = session.roundBirdiePot();

        return Scaffold(
          appBar: AppBar(
            title: Text('Round ${session.roundNumber} Recap', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, size: 28, color: AppColors.cyanLight),
                tooltip: 'Share Round Results',
                onPressed: () => _shareRoundSummary(session),
              ),
              IconButton(
                icon: const Icon(Icons.lock_open, size: 26, color: AppColors.duneSand),
                tooltip: 'Unlock & Edit Round',
                onPressed: () => _unlockAndEdit(context, session),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 26, color: Colors.redAccent),
                tooltip: 'Delete Round',
                onPressed: () => _confirmDeleteRound(context, session),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Winner / Leader Card with Large Fonts
              Card(
                margin: EdgeInsets.zero,
                color: AppColors.cardDark,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F2742), Color(0xFF0A1420)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: AppColors.lakeCyan.withValues(alpha: 0.6), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.military_tech, color: AppColors.lakeCyan, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        sortedPlayers.isNotEmpty
                            ? '${sortedPlayers.first.nickname} Leads Stableford (${session.effectivePlayerStableford(sortedPlayers.first.playerId)} pts)!'
                            : 'Round Complete',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${session.courseName} • ${session.holeCount} Holes • ${session.isFinalRound ? 'Modified Stableford' : '2-Man Stableford'}',
                        style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // BIRDIE POT CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF281E05), Color(0xFF100C02)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5C07B), width: 1.6),
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
                          child: const Text(
                            '💰 BIRDIE POT RESULTS',
                            style: TextStyle(
                              color: Color(0xFFE5C07B),
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        Text(
                          '\$2.00 / Birdie',
                          style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Round Pot', style: TextStyle(color: Colors.white60, fontSize: 13)),
                              Text(
                                '\$${birdiePot.roundPotTotal.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFFF7D98C)),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('To Cumulative Pot', style: TextStyle(color: Colors.white60, fontSize: 13)),
                              Text(
                                '+\$${birdiePot.cumulativeContribution.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFFE5C07B)),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Dues / Golfer', style: TextStyle(color: Colors.white60, fontSize: 13)),
                              Text(
                                '-\$${birdiePot.duesPerPlayer.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: Color(0xFF4A3B12)),
                    const SizedBox(height: 6),
                    if (birdiePot.hasBirdies) ...[
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFFE5C07B), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Round Pot Winner: ${birdiePot.winnerNames.join(' & ')} (Last Birdie on Hole ${birdiePot.lastBirdieHole})\nPayout: \$${birdiePot.payoutPerWinner.toStringAsFixed(0)} each',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ] else
                      const Text(
                        'No birdies recorded in this round. No dues owed.',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Leaderboard Card with Large Fonts
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'STABLEFORD & NET SCORES',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                              color: AppColors.cyanLight,
                            ),
                          ),
                          Text(
                            '2-Man Best Ball',
                            style: TextStyle(color: AppColors.duneSand, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...sortedPlayers.asMap().entries.map((entry) {
                        final rank = entry.key + 1;
                        final p = entry.value;
                        final gross = session.totalGross(p.playerId);
                        final net = session.totalNet(p.playerId);
                        final pts = session.effectivePlayerStableford(p.playerId);
                        final skinCount = skinsWon[p.playerId] ?? 0;
                        final teamId = p.twoManTeamId != 'none' ? p.twoManTeamId : p.teamId;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: rank == 1
                                ? AppColors.lakeCyan.withValues(alpha: 0.15)
                                : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: rank == 1
                                  ? AppColors.lakeCyan
                                  : AppColors.cardBorder,
                              width: rank == 1 ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '$rank',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: rank == 1 ? AppColors.lakeCyan : Colors.white70,
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              PlayerAvatar(
                                initials: p.initials,
                                radius: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            p.nickname,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 20,
                                              color: Colors.white,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (teamId != 'none') ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.lakeDeep,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              teamId,
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.lakeCyan),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      'Net $net • Gross $gross',
                                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$pts pts',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                      color: AppColors.duneSand,
                                    ),
                                  ),
                                  Text(
                                    '$skinCount skins',
                                    style: const TextStyle(fontSize: 13, color: Colors.white60),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Skins Breakdown Card
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SKINS BREAKDOWN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          color: AppColors.duneSand,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...skins.entries.map((e) {
                        final holeNum = e.key;
                        final res = e.value;
                        final hole = session.getHole(holeNum);

                        String winnerText = 'Tied (carried)';
                        Color textColor = Colors.white60;
                        if (res.hasWinner) {
                          final winner = session.players
                              .where((p) => p.playerId == res.winnerPlayerId)
                              .firstOrNull;
                          winnerText =
                              '${winner?.nickname ?? 'Won'} (${res.winningScore}) • ${res.skinCount} skin${res.skinCount > 1 ? 's' : ''}';
                          textColor = AppColors.cyanLight;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Text(
                                'Hole $holeNum (P${hole.par}):',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  winnerText,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: res.hasWinner
                                        ? FontWeight.w800
                                        : FontWeight.normal,
                                    fontSize: 17,
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
              const SizedBox(height: 26),

              ElevatedButton.icon(
                onPressed: () => _shareRoundSummary(session),
                icon: const Icon(Icons.share, size: 28),
                label: const Text('Share Round Results', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _unlockAndEdit(context, session),
                icon: const Icon(Icons.lock_open, color: AppColors.duneSand, size: 24),
                label: const Text(
                  'Unlock & Edit This Round',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.duneSand),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.duneSand, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _unlockAndEdit(BuildContext context, ActiveRoundSession session) async {
    final activeDraft = await roundRepository.getActiveDraft();
    if (activeDraft != null && context.mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Replace Active Draft?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            'You currently have a round in progress (${activeDraft.courseName}, Hole ${activeDraft.currentHoleNumber}).\n\nUnlocking Round ${session.roundNumber} will replace the active draft. Do you want to continue?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.duneSand, foregroundColor: Colors.black),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Unlock & Edit', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    final unlocked = await roundRepository.unlockSavedRound(roundId);
    if (unlocked != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔓 Round ${session.roundNumber} unlocked! You can now edit scores, tees, and player handicaps.'),
          backgroundColor: const Color(0xFF0F3224),
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ActiveScoringScreen(
            roundRepository: roundRepository,
            session: unlocked,
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteRound(BuildContext context, ActiveRoundSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Round ${session.roundNumber}?', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete Round ${session.roundNumber} (${session.courseName})? This cannot be undone.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Round', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await roundRepository.deleteSavedRound(roundId);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Round ${session.roundNumber} deleted'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _shareRoundSummary(ActiveRoundSession session) {
    final buffer = StringBuffer();
    buffer.writeln('🏌️ Arcadia Cup - Round ${session.roundNumber} Recap');
    buffer.writeln('📍 Course: ${session.courseName}');
    buffer.writeln('');
    buffer.writeln('🏆 STABLEFORD LEADERBOARD:');

    final sorted = List<PlayerSessionInfo>.from(session.players)
      ..sort((a, b) =>
          session.effectivePlayerStableford(b.playerId).compareTo(session.effectivePlayerStableford(a.playerId)));

    for (var i = 0; i < sorted.length; i++) {
      final p = sorted[i];
      final gross = session.totalGross(p.playerId);
      final net = session.totalNet(p.playerId);
      final pts = session.effectivePlayerStableford(p.playerId);
      buffer.writeln(
        '${i + 1}. ${p.nickname}: $pts pts (Net $net, Gross $gross)',
      );
    }

    buffer.writeln('');
    final birdiePot = session.roundBirdiePot();
    buffer.writeln('💰 BIRDIE POT:');
    buffer.writeln('Total Birdies: ${birdiePot.totalBirdies} • Round Pot: \$${birdiePot.roundPotTotal.toStringAsFixed(0)}');
    if (birdiePot.hasBirdies) {
      buffer.writeln('Winner: ${birdiePot.winnerNames.join(' & ')} (Hole ${birdiePot.lastBirdieHole}) - \$${birdiePot.payoutPerWinner.toStringAsFixed(0)} each');
    }

    Share.share(buffer.toString());
  }
}
