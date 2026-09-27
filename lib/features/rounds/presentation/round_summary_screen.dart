import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../database/app_database.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/player_avatar.dart';
import '../models/active_round_session.dart';
import '../repository/round_repository.dart';

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
      future: roundRepository.getSavedRound(roundId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final round = snapshot.data!;
        final sessionMap = jsonDecode(round.roundPayloadJson) as Map<String, dynamic>;
        final session = ActiveRoundSession.fromJson(sessionMap);
        final skins = session.calculateGrossSkins();

        // Sort players by total net score
        final sortedPlayers = List<PlayerSessionInfo>.from(session.players)
          ..sort((a, b) =>
              session.totalNet(a.playerId).compareTo(session.totalNet(b.playerId)));

        return Scaffold(
          appBar: AppBar(
            title: Text('${session.courseName} • Round ${session.roundNumber}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: AppColors.goldLight),
                tooltip: 'Share Round Recap',
                onPressed: () => _shareRoundSummary(session),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Winner / Leader Card
              Card(
                margin: EdgeInsets.zero,
                color: AppColors.cardDark,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F4332), Color(0xFF072118)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.military_tech, color: AppColors.gold, size: 40),
                      const SizedBox(height: 6),
                      Text(
                        round.winnerName != null
                            ? '${round.winnerName} Wins Low Net!'
                            : 'Round Complete',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.goldLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${session.courseName} • ${session.holeCount} Holes',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Leaderboard Card
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ROUND RESULTS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...sortedPlayers.asMap().entries.map((entry) {
                        final rank = entry.key + 1;
                        final p = entry.value;
                        final gross = session.totalGross(p.playerId);
                        final net = session.totalNet(p.playerId);
                        final pts = session.totalStableford(p.playerId);
                        final skinCount = session.playerSkinsWon()[p.playerId] ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: rank == 1
                                ? AppColors.gold.withValues(alpha: 0.12)
                                : const Color(0xFF072118),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: rank == 1
                                  ? AppColors.gold
                                  : AppColors.cardBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '$rank',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: rank == 1 ? AppColors.gold : Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              PlayerAvatar(
                                initials: p.initials,
                                radius: 16,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  p.nickname,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Net $net',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.goldLight,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Gross $gross',
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '$pts Stableford pts • $skinCount skins',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
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
              const SizedBox(height: 16),

              // Skins Breakdown Card
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SKINS BREAKDOWN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...skins.entries.map((e) {
                        final holeNum = e.key;
                        final res = e.value;
                        final hole = session.getHole(holeNum);

                        String winnerText = 'Tied (carried)';
                        Color textColor = Colors.white54;
                        if (res.hasWinner) {
                          final winner = session.players
                              .where((p) => p.playerId == res.winnerPlayerId)
                              .firstOrNull;
                          winnerText =
                              '${winner?.nickname ?? 'Won'} with ${res.winningScore} (${res.skinCount} skin${res.skinCount > 1 ? 's' : ''})';
                          textColor = AppColors.goldLight;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                'Hole $holeNum (P${hole.par}):',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  winnerText,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: res.hasWinner
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 13,
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
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: () => _shareRoundSummary(session),
                icon: const Icon(Icons.share),
                label: const Text('Share Round Results With Guys'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareRoundSummary(ActiveRoundSession session) {
    final buffer = StringBuffer();
    buffer.writeln('🏌️ Golf Trip - Round ${session.roundNumber} Recap');
    buffer.writeln('📍 Course: ${session.courseName}');
    buffer.writeln('');
    buffer.writeln('🏆 LEADERBOARD:');

    final sorted = List<PlayerSessionInfo>.from(session.players)
      ..sort((a, b) =>
          session.totalNet(a.playerId).compareTo(session.totalNet(b.playerId)));

    final skins = session.playerSkinsWon();

    for (var i = 0; i < sorted.length; i++) {
      final p = sorted[i];
      final gross = session.totalGross(p.playerId);
      final net = session.totalNet(p.playerId);
      final pts = session.totalStableford(p.playerId);
      final skinCount = skins[p.playerId] ?? 0;
      buffer.writeln(
        '${i + 1}. ${p.nickname}: Net $net | Gross $gross | $pts pts | $skinCount skins',
      );
    }

    buffer.writeln('');
    buffer.writeln('💰 SKINS WON:');
    final grossSkins = session.calculateGrossSkins();
    var anySkins = false;
    for (final entry in grossSkins.entries) {
      if (entry.value.hasWinner) {
        anySkins = true;
        final winner = session.players
            .where((p) => p.playerId == entry.value.winnerPlayerId)
            .firstOrNull;
        buffer.writeln(
          '• Hole ${entry.key}: ${winner?.nickname} (${entry.value.winningScore}) - ${entry.value.skinCount} skin(s)',
        );
      }
    }
    if (!anySkins) buffer.writeln('No skins won outright.');

    Share.share(buffer.toString());
  }
}
