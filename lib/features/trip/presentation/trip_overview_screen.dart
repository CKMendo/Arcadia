import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/app_database.dart';
import '../../../shared/theme/app_colors.dart';
import '../../courses/repository/course_repository.dart';
import '../../players/repository/player_repository.dart';
import '../../rounds/models/active_round_session.dart';
import '../../rounds/presentation/active_scoring_screen.dart';
import '../../rounds/presentation/new_round_setup_screen.dart';
import '../../rounds/presentation/round_summary_screen.dart';
import '../../rounds/repository/round_repository.dart';
import '../../tournaments/presentation/tournament_setup_screen.dart';
import '../../tournaments/repository/tournament_repository.dart';

class TripOverviewScreen extends StatelessWidget {
  final TournamentRepository tournamentRepository;
  final CourseRepository courseRepository;
  final PlayerRepository playerRepository;
  final RoundRepository roundRepository;

  const TripOverviewScreen({
    super.key,
    required this.tournamentRepository,
    required this.courseRepository,
    required this.playerRepository,
    required this.roundRepository,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arcadia Trip'),
        actions: [
          StreamBuilder<Tournament?>(
            stream: tournamentRepository.watchActiveTournament(),
            builder: (context, snap) {
              final tournament = snap.data;
              return IconButton(
                icon: const Icon(Icons.settings_outlined, color: AppColors.cyanLight, size: 28),
                tooltip: 'Trip Settings',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TournamentSetupScreen(
                        tournamentRepository: tournamentRepository,
                        playerRepository: playerRepository,
                        tournament: tournament,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<Tournament?>(
        stream: tournamentRepository.watchActiveTournament(),
        builder: (context, snapTournament) {
          final tournament = snapTournament.data;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Hero Trip Card with Large Typography
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F2742), Color(0xFF0A1420)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: AppColors.lakeCyan.withValues(alpha: 0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lakeCyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.lakeCyan.withValues(alpha: 0.8), width: 1.5),
                          ),
                          child: const Text(
                            'ARCADIA BLUFFS 2026',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: AppColors.lakeCyan,
                            ),
                          ),
                        ),
                        const Icon(Icons.waves, color: AppColors.cyanLight, size: 30),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tournament?.name ?? 'Arcadia Bluffs Trip',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tournament != null
                          ? '${dateFormat.format(DateTime.fromMillisecondsSinceEpoch(tournament.startDate))} - ${dateFormat.format(DateTime.fromMillisecondsSinceEpoch(tournament.endDate))}'
                          : 'Set up your trip dates & competition format',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (tournament != null && tournament.formatType != 'individual') ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.teamA.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.teamA, width: 1.5),
                            ),
                            child: Text(
                              tournament.teamAName,
                              style: const TextStyle(
                                color: AppColors.teamA,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(
                              'vs',
                              style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.teamB.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.teamB, width: 1.5),
                            ),
                            child: Text(
                              tournament.teamBName,
                              style: const TextStyle(
                                color: AppColors.teamB,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Active Round Draft Banner (if playing) with Large Fonts
              StreamBuilder<ActiveRoundSession?>(
                stream: roundRepository.watchActiveDraft(),
                builder: (context, draftSnap) {
                  final draft = draftSnap.data;
                  if (draft == null) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.lakeDeep.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.lakeCyan, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.lakeCyan,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.play_circle_fill, color: Color(0xFF06111D), size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ROUND IN PROGRESS',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: AppColors.cyanLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${draft.courseName} • Hole ${draft.currentHoleNumber}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 19,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ActiveScoringScreen(
                                  roundRepository: roundRepository,
                                  session: draft,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.lakeCyan,
                            foregroundColor: const Color(0xFF06111D),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          child: const Text('Resume', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Quick Action: Start New Round Button (Big Touch Target)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NewRoundSetupScreen(
                        courseRepository: courseRepository,
                        playerRepository: playerRepository,
                        tournamentRepository: tournamentRepository,
                        roundRepository: roundRepository,
                        tournamentId: tournament?.id,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_circle, size: 28),
                label: const Text('Start New Round', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
              const SizedBox(height: 24),

              // Completed Rounds Section with Large Text
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'COMPLETED ROUNDS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: AppColors.cyanLight,
                    ),
                  ),
                  StreamBuilder<List<SavedRound>>(
                    stream: roundRepository.watchSavedRounds(),
                    builder: (context, snap) {
                      final count = snap.data?.length ?? 0;
                      return Text(
                        '$count Round${count == 1 ? '' : 's'}',
                        style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w700),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              StreamBuilder<List<SavedRound>>(
                stream: roundRepository.watchSavedRounds(),
                builder: (context, snapRounds) {
                  final rounds = snapRounds.data ?? [];
                  if (rounds.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.sports_golf, size: 48, color: Colors.white30),
                          SizedBox(height: 14),
                          Text(
                            'No rounds completed yet',
                            style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Tap "Start New Round" above when you get to the 1st tee.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white60, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: rounds.map((r) {
                      final playedDate =
                          DateTime.fromMillisecondsSinceEpoch(r.datePlayed);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: const Icon(Icons.sports_golf,
                                color: AppColors.lakeCyan, size: 28),
                          ),
                          title: Text(
                            'Round ${r.roundNumber}: ${r.courseName}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '${dateFormat.format(playedDate)} • Winner: ${r.winnerName ?? 'Completed'}',
                              style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600),
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: Colors.white60, size: 28),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RoundSummaryScreen(
                                  roundRepository: roundRepository,
                                  roundId: r.id,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
