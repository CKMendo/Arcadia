import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/app_database.dart';
import '../../../shared/theme/app_colors.dart';
import '../../courses/repository/course_repository.dart';
import '../../players/repository/player_repository.dart';
import '../../rounds/models/active_round_session.dart';
import '../../rounds/models/birdie_pot_models.dart';
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
              // Hero Photographic Trip Banner with Tournament Crest
              Container(
                height: 270,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.lakeCyan.withValues(alpha: 0.6), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lakeCyan.withValues(alpha: 0.2),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // High-res Coastal Course Photography
                      Image.asset(
                        'assets/images/arcadia_bluffs.jpg',
                        fit: BoxFit.cover,
                      ),

                      // Rich Gradient Overlay for Crisp Text Readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.25),
                              const Color(0xFF07111C).withValues(alpha: 0.85),
                              const Color(0xFF050D16).withValues(alpha: 0.98),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),

                      // Content Layer
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0C1D2F).withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.lakeCyan.withValues(alpha: 0.8), width: 1.5),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.location_on, color: AppColors.lakeCyan, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        'ARCADIA BLUFFS 2026',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                          color: AppColors.cyanLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Tournament Crest Emblem
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.duneSand, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.6),
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
                              ],
                            ),
                            const Spacer(),

                            Text(
                              tournament?.name ?? 'Arcadia Coastal Cup',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                                color: Colors.white,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 2)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.calendar_month, color: AppColors.duneSand, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  tournament != null
                                      ? '${dateFormat.format(DateTime.fromMillisecondsSinceEpoch(tournament.startDate))} - ${dateFormat.format(DateTime.fromMillisecondsSinceEpoch(tournament.endDate))}'
                                      : 'Set up your trip dates & competition format',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            if (tournament != null && tournament.formatType != 'individual') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.teamA.withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.teamA, width: 1.5),
                                    ),
                                    child: Text(
                                      tournament.teamAName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                                    child: Text(
                                      'VS',
                                      style: TextStyle(color: AppColors.duneSand, fontSize: 16, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.teamB.withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.teamB, width: 1.5),
                                    ),
                                    child: Text(
                                      tournament.teamBName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Coastal Live Conditions Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.air, color: AppColors.lakeCyan, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Bluffs Wind: 14 mph NW',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.wb_sunny_outlined, color: AppColors.duneSand, size: 18),
                        SizedBox(width: 6),
                        Text(
                          '71°F • Lake Michigan',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.duneLight),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Birdie Pot Pool Live Banner
              StreamBuilder<List<SavedRound>>(
                stream: roundRepository.watchSavedRounds(),
                builder: (context, snap) {
                  final rounds = snap.data ?? [];
                  final sessions = <ActiveRoundSession>[];
                  for (final r in rounds) {
                    try {
                      final map = jsonDecode(r.roundPayloadJson) as Map<String, dynamic>;
                      sessions.add(ActiveRoundSession.fromJson(map));
                    } catch (_) {}
                  }
                  final ledger = TripBirdiePotLedger.calculate(sessions);

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF261D05), Color(0xFF100C02)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5C07B).withValues(alpha: 0.7), width: 1.4),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5C07B).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE5C07B)),
                          ),
                          child: const Icon(Icons.monetization_on, color: Color(0xFFE5C07B), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'BIRDIE POT POOL',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFE5C07B),
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  Text(
                                    '\$${ledger.totalCumulativePot.toStringAsFixed(0)} CUMULATIVE',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFF7D98C),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ledger.tripWinnerNames.isNotEmpty
                                    ? 'Reigning Leader: ${ledger.tripWinnerNames.join(' & ')} (H${ledger.tripWinningHole}, R${ledger.tripWinningRoundNumber})'
                                    : '\$2/birdie per player • \$1 Round Pot, \$1 Cumulative • Last birdie wins!',
                                style: const TextStyle(fontSize: 13, color: Colors.white70),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
