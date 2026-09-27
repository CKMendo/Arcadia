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
                icon: const Icon(Icons.settings_outlined, color: AppColors.goldLight),
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
              // Hero Trip Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F4332), Color(0xFF072118)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
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
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.gold),
                          ),
                          child: const Text(
                            'GOLF TRIP 2026',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                        const Icon(Icons.golf_course, color: AppColors.goldLight),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      tournament?.name ?? 'Arcadia Bluffs Trip',
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tournament != null
                          ? '${dateFormat.format(DateTime.fromMillisecondsSinceEpoch(tournament.startDate))} - ${dateFormat.format(DateTime.fromMillisecondsSinceEpoch(tournament.endDate))}'
                          : 'Set up your trip dates & competition format',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    if (tournament != null && tournament.formatType != 'individual') ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.teamA.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.teamA),
                            ),
                            child: Text(
                              tournament.teamAName,
                              style: const TextStyle(
                                color: AppColors.teamA,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('vs', style: TextStyle(color: Colors.white38)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.teamB.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.teamB),
                            ),
                            child: Text(
                              tournament.teamBName,
                              style: const TextStyle(
                                color: AppColors.teamB,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Active Round Draft Banner (if playing)
              StreamBuilder<ActiveRoundSession?>(
                stream: roundRepository.watchActiveDraft(),
                builder: (context, draftSnap) {
                  final draft = draftSnap.data;
                  if (draft == null) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.sageGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.sageGreen),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.sageGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.play_circle_fill, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ROUND IN PROGRESS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                  color: AppColors.gold,
                                ),
                              ),
                              Text(
                                '${draft.courseName} • Hole ${draft.currentHoleNumber}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
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
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          child: const Text('Resume'),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Quick Action: Start New Round
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
                icon: const Icon(Icons.add),
                label: const Text('Start New Round'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 20),

              // Completed Rounds Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'COMPLETED ROUNDS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: AppColors.gold,
                    ),
                  ),
                  StreamBuilder<List<SavedRound>>(
                    stream: roundRepository.watchSavedRounds(),
                    builder: (context, snap) {
                      final count = snap.data?.length ?? 0;
                      return Text(
                        '$count Round${count == 1 ? '' : 's'}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              StreamBuilder<List<SavedRound>>(
                stream: roundRepository.watchSavedRounds(),
                builder: (context, snapRounds) {
                  final rounds = snapRounds.data ?? [];
                  if (rounds.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.sports_golf, size: 40, color: Colors.white24),
                          SizedBox(height: 10),
                          Text(
                            'No rounds completed yet',
                            style: TextStyle(color: Colors.white70),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap "Start New Round" above when you get to the 1st tee.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white38, fontSize: 12),
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
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.sageGreen.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.golf_course,
                                color: AppColors.goldLight),
                          ),
                          title: Text(
                            'Round ${r.roundNumber}: ${r.courseName}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${dateFormat.format(playedDate)} • Winner: ${r.winnerName ?? 'Completed'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: Colors.white38),
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
