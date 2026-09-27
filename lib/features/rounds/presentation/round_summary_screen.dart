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
              session.totalNet(a.playerId).compareTo(session.totalNet(b.playerId)));

        final skins = session.calculateGrossSkins();

        return Scaffold(
          appBar: AppBar(
            title: Text('Round ${session.roundNumber} Recap', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, size: 28, color: AppColors.cyanLight),
                tooltip: 'Share Round Results',
                onPressed: () => _shareRoundSummary(session),
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
                        round.winnerName != null
                            ? '${round.winnerName} Wins Low Net!'
                            : 'Round Complete',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${session.courseName} • ${session.holeCount} Holes',
                        style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Leaderboard Card with Large Fonts
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ROUND RESULTS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          color: AppColors.cyanLight,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...sortedPlayers.asMap().entries.map((entry) {
                        final rank = entry.key + 1;
                        final p = entry.value;
                        final gross = session.totalGross(p.playerId);
                        final net = session.totalNet(p.playerId);
                        final pts = session.totalStableford(p.playerId);
                        final skinCount = session.playerSkinsWon()[p.playerId] ?? 0;

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
                                child: Text(
                                  p.nickname,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                    color: Colors.white,
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
                                          fontWeight: FontWeight.w900,
                                          fontSize: 22,
                                          color: AppColors.lakeCyan,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Gross $gross',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$pts pts • $skinCount skins',
                                    style: const TextStyle(
                                      color: AppColors.duneSand,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
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
              const SizedBox(height: 18),

              // Skins Breakdown Card with Large Fonts
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
