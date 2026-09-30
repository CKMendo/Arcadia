import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/course_handicap_calculator.dart';
import '../../../shared/widgets/player_avatar.dart';
import '../../players/repository/player_repository.dart';
import '../../rounds/models/active_round_session.dart';
import '../../rounds/repository/round_repository.dart';
import '../../tournaments/services/tournament_pairings_engine.dart';
import '../models/scheduled_round.dart';
import '../repository/course_repository.dart';
import '../repository/trip_schedule_repository.dart';

import '../../tournaments/repository/tournament_repository.dart';
import '../../publish/services/website_publish_service.dart';
import '../../../database/app_database.dart';

class TripScheduleTab extends StatelessWidget {
  final CourseRepository courseRepository;
  final PlayerRepository playerRepository;
  final TripScheduleRepository tripScheduleRepository;
  final RoundRepository roundRepository;
  final TournamentRepository? tournamentRepository;

  const TripScheduleTab({
    super.key,
    required this.courseRepository,
    required this.playerRepository,
    required this.tripScheduleRepository,
    required this.roundRepository,
    this.tournamentRepository,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ScheduledRound>>(
      stream: tripScheduleRepository.watchSchedule(),
      builder: (context, scheduleSnap) {
        return StreamBuilder<bool>(
          stream: tripScheduleRepository.watchIsFinalized(),
          builder: (context, finalizedSnap) {
            final schedule = scheduleSnap.data ?? [];
            final isFinalized = finalizedSnap.data ?? false;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              children: [
                // Top Status & Instruction Banner
                _buildScheduleStatusBanner(context, schedule, isFinalized),
                const SizedBox(height: 14),

                if (schedule.isEmpty)
                  _buildEmptyScheduleCard(context)
                else
                  ...schedule.map((round) => _buildScheduledRoundCard(
                        context,
                        round,
                        isFinalized,
                      )),
                const SizedBox(height: 80),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildScheduleStatusBanner(
    BuildContext context,
    List<ScheduledRound> schedule,
    bool isFinalized,
  ) {
    final hasPairings = schedule.any((r) => r.pairingPlan != null);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFinalized ? const Color(0xFF10B981) : AppColors.cardBorder,
          width: isFinalized ? 1.8 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isFinalized ? Icons.check_circle : (hasPairings ? Icons.group_work : Icons.schedule),
                color: isFinalized
                    ? const Color(0xFF34D399)
                    : (hasPairings ? AppColors.lakeCyan : const Color(0xFFFBBF24)),
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isFinalized
                      ? 'TRIP SCHEDULE FINALIZED (${schedule.length} ROUNDS) • LIVE ON SITE'
                      : (hasPairings
                          ? 'PAIRINGS CHOSEN (${schedule.length} ROUNDS) • NOT FINALIZED'
                          : 'TRIP SCHEDULE (${schedule.length} ROUND${schedule.length == 1 ? '' : 'S'} ENTERED)'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: isFinalized
                        ? const Color(0xFF6EE7B7)
                        : (hasPairings ? AppColors.cyanLight : const Color(0xFFFDE68A)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isFinalized
                ? 'All rounds, 2-man teams, and foursomes are locked and published to the website with zero repeat partners. To change pairings or edit rounds, tap "Undo Finalized Pairings" below or in the 3 dots menu.'
                : (hasPairings
                    ? 'Optimal pairings generated with zero partner repeats. Review teams on each round card below. Tap "Finalize & Lock Pairings" to publish live to the website, or "Re-Generate / Shuffle Pairings" for another optimal draw.'
                    : 'Pairings and 2-man teams can be generated once rounds are entered on the schedule. Tap "Choose Pairings" below to generate optimal, non-repeating teams.'),
            style: const TextStyle(
              fontSize: 15,
              height: 1.35,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if (!isFinalized)
                ElevatedButton.icon(
                  onPressed: () => _openAddEditRoundDialog(context),
                  icon: const Icon(Icons.add, size: 22),
                  label: const Text(
                    'Add Round to Schedule',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lakeCyan,
                    foregroundColor: const Color(0xFF04111D),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              if (!isFinalized && schedule.isNotEmpty) ...[
                ElevatedButton.icon(
                  onPressed: () => _choosePairings(context, schedule),
                  icon: Icon(hasPairings ? Icons.shuffle : Icons.auto_awesome, size: 22),
                  label: Text(
                    hasPairings ? 'Re-Generate / Shuffle Pairings' : 'Choose Pairings',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasPairings ? const Color(0xFF0F384C) : AppColors.lakeCyan,
                    foregroundColor: hasPairings ? AppColors.cyanLight : const Color(0xFF04111D),
                    side: hasPairings ? const BorderSide(color: AppColors.lakeCyan, width: 1.5) : BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                if (hasPairings)
                  ElevatedButton.icon(
                    onPressed: () => _finalizeAndPublishPairings(context, schedule),
                    icon: const Icon(Icons.lock, size: 22),
                    label: const Text(
                      'Finalize & Lock Pairings',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
              ],
              if (isFinalized)
                OutlinedButton.icon(
                  onPressed: () => _unlockSchedule(context),
                  icon: const Icon(Icons.lock_open, size: 22, color: AppColors.duneSand),
                  label: const Text(
                    'Undo / Unlock Finalized Pairings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.duneSand),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.duneSand, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              if (schedule.isEmpty)
                OutlinedButton.icon(
                  onPressed: () => _seedDefaultArcadiaSchedule(context),
                  icon: const Icon(Icons.auto_awesome, size: 22, color: AppColors.cyanLight),
                  label: const Text(
                    'Load Default 3-Round Arcadia Schedule',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.lakeCyan),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScheduleCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.calendar_month, size: 54, color: AppColors.lakeCyan),
          const SizedBox(height: 14),
          const Text(
            'No Rounds Scheduled Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the courses and tee times you will play during your trip. Once all rounds are on the schedule, the AI pairing engine will generate balanced, non-repeating 2-man teams across the trip.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => _seedDefaultArcadiaSchedule(context),
            icon: const Icon(Icons.bolt, size: 24),
            label: const Text(
              'Load Arcadia 3-Round Schedule',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lakeCyan,
              foregroundColor: const Color(0xFF04111D),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledRoundCard(
    BuildContext context,
    ScheduledRound round,
    bool isFinalized,
  ) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final isShort = round.isShortCourse;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: isShort ? const Color(0xFF181022) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isShort
              ? const Color(0xFFA855F7)
              : (round.isFinalRound
                  ? AppColors.duneSand.withValues(alpha: 0.8)
                  : AppColors.cardBorder),
          width: isShort || round.isFinalRound ? 1.8 : 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Round Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isShort
                            ? const Color(0xFFA855F7).withValues(alpha: 0.25)
                            : (round.isFinalRound
                                ? AppColors.duneSand.withValues(alpha: 0.3)
                                : AppColors.lakeCyan.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isShort
                              ? const Color(0xFFA855F7)
                              : (round.isFinalRound
                                  ? AppColors.duneSand
                                  : AppColors.lakeCyan),
                        ),
                      ),
                      child: Text(
                        'ROUND ${round.roundNumber}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          color: isShort
                              ? const Color(0xFFE9D5FF)
                              : (round.isFinalRound
                                  ? AppColors.duneSand
                                  : AppColors.cyanLight),
                        ),
                      ),
                    ),
                    if (isShort) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B154D),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA855F7)),
                        ),
                        child: Text(
                          '⛳ SHORT COURSE (${round.holeCount}H) • BIRDIE POT ONLY',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF3E8FF)),
                        ),
                      ),
                    ] else if (round.isFinalRound) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF26190C),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.duneSand.withValues(alpha: 0.5)),
                        ),
                        child: const Text(
                          '🏆 CHAMPIONSHIP',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.duneLight),
                        ),
                      ),
                    ],
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white70, size: 24),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _openAddEditRoundDialog(context, round: round);
                    } else if (val == 'delete') {
                      _deleteRound(context, round);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, color: AppColors.lakeCyan, size: 20),
                          SizedBox(width: 10),
                          Text('Edit Round & Times', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          SizedBox(width: 10),
                          Text('Remove Round', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Course Name
            Text(
              round.courseName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),

            // Date & Tee Times Row (Tap to edit)
            InkWell(
              onTap: () => _openAddEditRoundDialog(context, round: round),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: AppColors.duneSand),
                        const SizedBox(width: 6),
                        Text(
                          dateFormat.format(round.date),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, size: 16, color: AppColors.lakeCyan),
                        const SizedBox(width: 6),
                        Text(
                          'Tee Times: ${round.teeTimeGroup1} & ${round.teeTimeGroup2}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.cyanLight),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit, size: 14, color: AppColors.lakeCyan),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (round.notes != null && round.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                round.notes!,
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.white70),
              ),
            ],
            const SizedBox(height: 10),

            // Prominent Round Actions Bar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openAddEditRoundDialog(context, round: round),
                    icon: const Icon(Icons.edit_calendar, size: 18),
                    label: const Text(
                      'Edit Course & Tee Times',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.lakeCyan,
                      side: const BorderSide(color: AppColors.lakeCyan),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  tooltip: 'Remove Round',
                  style: IconButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.all(10),
                  ),
                  onPressed: () => _deleteRound(context, round),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pairings & 2-Man Teams Block
            if (round.isShortCourse)
              _buildShortCourseCardBlock(round)
            else if (round.pairingPlan != null)
              _buildFinalizedPairingsBlock(round.pairingPlan!, round, isFinalized)
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1B29),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.white54, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '🔒 Pairings Not Chosen: Tap "Choose Pairings" above to generate balanced 2-man teams with zero repeats.',
                        style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortCourseCardBlock(ScheduledRound round) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF130A1C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.6), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.stars, color: Color(0xFFA855F7), size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'BIRDIE POT GAME ONLY • NOT IN STABLEFORD',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE9D5FF),
                    letterSpacing: 0.9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'This course has ${round.holeCount} holes (not an 18-hole regulation tournament course). Per tournament rules, it is excluded from 2-man partner pairings and Stableford standings. All 8 golfers play individually, and all birdies made count toward the Birdie Pot game!',
            style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalizedPairingsBlock(
    RoundPairingPlan plan,
    ScheduledRound round,
    bool isFinalized,
  ) {
    final isSouth = round.courseName.toLowerCase().contains('south');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1624),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFinalized
              ? const Color(0xFF10B981).withValues(alpha: 0.7)
              : AppColors.lakeCyan.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isFinalized ? Icons.verified : Icons.groups,
                    color: isFinalized ? const Color(0xFF34D399) : AppColors.lakeCyan,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isFinalized
                        ? 'FINALIZED 2-MAN TEAMS & FOURSOMES'
                        : 'PROPOSED 2-MAN TEAMS (REVIEW)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isFinalized ? const Color(0xFF6EE7B7) : AppColors.cyanLight,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isFinalized ? const Color(0xFF0D281E) : const Color(0xFF192534),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isFinalized ? const Color(0xFF34D399) : AppColors.lakeCyan,
                  ),
                ),
                child: Text(
                  isFinalized ? 'LOCKED & PUBLISHED' : 'PENDING FINALIZATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isFinalized ? const Color(0xFF34D399) : AppColors.cyanLight,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.cardBorder, height: 16),

          // Group 1
          _buildFoursomeGroupRow(
            groupNum: 1,
            teeTime: round.teeTimeGroup1,
            foursome: plan.foursome1,
            isSouth: isSouth,
          ),
          const SizedBox(height: 10),

          // Group 2
          _buildFoursomeGroupRow(
            groupNum: 2,
            teeTime: round.teeTimeGroup2,
            foursome: plan.foursome2,
            isSouth: isSouth,
          ),
        ],
      ),
    );
  }

  Widget _buildFoursomeGroupRow({
    required int groupNum,
    required String teeTime,
    required FoursomePlan foursome,
    required bool isSouth,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GROUP $groupNum • TEE TIME $teeTime',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.duneSand,
                  letterSpacing: 0.8,
                ),
              ),
              const Text(
                '2-Man Match',
                style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Team A vs Team B
          Row(
            children: [
              Expanded(
                child: _buildTeamCard(
                  team: foursome.teamA,
                  label: 'Team 1',
                  color: AppColors.lakeCyan,
                  isSouth: isSouth,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'VS',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.duneSand),
                ),
              ),
              Expanded(
                child: _buildTeamCard(
                  team: foursome.teamB,
                  label: 'Team 2',
                  color: AppColors.teamB,
                  isSouth: isSouth,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard({
    required TwoManTeamPlan team,
    required String label,
    required Color color,
    required bool isSouth,
  }) {
    final p1 = team.player1;
    final p2 = team.player2;

    final ch1 = isSouth
        ? CourseHandicapCalculator.forSouth(p1.handicapIndex, p1.preferredTee ?? 'White')
        : CourseHandicapCalculator.forBluffs(p1.handicapIndex, p1.preferredTee ?? 'White');
    final ch2 = isSouth
        ? CourseHandicapCalculator.forSouth(p2.handicapIndex, p2.preferredTee ?? 'White')
        : CourseHandicapCalculator.forBluffs(p2.handicapIndex, p2.preferredTee ?? 'White');

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF07121E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlayerAvatar(
                name: p1.fullName,
                initials: p1.initials,
                photoPath: p1.photoPath,
                radius: 12,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  p1.fullName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'H$ch1',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.lakeCyan),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              PlayerAvatar(
                name: p2.fullName,
                initials: p2.initials,
                photoPath: p2.photoPath,
                radius: 12,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  p2.fullName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'H$ch2',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.lakeCyan),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _seedDefaultArcadiaSchedule(BuildContext context) async {
    final courses = await courseRepository.getAllCourses();
    await tripScheduleRepository.seedDefaultArcadiaSchedule(courses);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loaded Arcadia Bluffs 3-round trip schedule with tee times!', style: TextStyle(fontSize: 16)),
        ),
      );
    }
  }

  Future<void> _choosePairings(BuildContext context, List<ScheduledRound> schedule) async {
    final players = await playerRepository.getAllPlayers();
    if (players.length < 4) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least 4 players (or all 8) to the roster before choosing pairings.', style: TextStyle(fontSize: 16)),
          ),
        );
      }
      return;
    }

    final savedRounds = await roundRepository.getAllSavedRounds();
    final sessions = <ActiveRoundSession>[];
    for (final r in savedRounds) {
      try {
        final map = jsonDecode(r.roundPayloadJson) as Map<String, dynamic>;
        sessions.add(ActiveRoundSession.fromJson(map));
      } catch (_) {}
    }

    await tripScheduleRepository.generatePairingsForSchedule(
      players: players,
      pastSavedRounds: sessions,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0F382A),
          content: Text(
            '✅ Pairings generated! Review the 2-man teams and foursomes below. Tap "Finalize & Lock Pairings" when ready to publish to website.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  Future<void> _finalizeAndPublishPairings(BuildContext context, List<ScheduledRound> schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalize & Publish Pairings?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        content: Text(
          'This will lock in the 2-man teams and foursomes across all ${schedule.length} scheduled rounds and publish them to the official tournament website.\n\nYou can undo or unlock pairings anytime via the 3 dots menu at the top or below.',
          style: const TextStyle(fontSize: 16, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.verified, size: 20),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            label: const Text('Finalize & Publish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await tripScheduleRepository.finalizeScheduleAndLock();

    // Publish to website
    try {
      final tRepo = tournamentRepository ?? TournamentRepository(AppDatabase());
      await WebsitePublishService.publishTournament(
        tournamentRepo: tRepo,
        courseRepo: courseRepository,
        playerRepo: playerRepository,
        roundRepo: roundRepository,
      );
    } catch (_) {}

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0F382A),
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF34D399), size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '🔒 Pairings finalized & published live to the tournament website!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _unlockSchedule(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Undo Finalized Pairings?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        content: const Text(
          'Unlocking will reopen the schedule so you can choose different pairings or edit rounds and tee times. Pairings will not be locked until you finalize them again.',
          style: TextStyle(fontSize: 16, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.duneSand),
            child: const Text('Unlock Pairings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await tripScheduleRepository.unlockSchedule();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF0F2B20),
            content: Text('Pairings unlocked! You can now choose new pairings or edit rounds.', style: TextStyle(fontSize: 16)),
          ),
        );
      }
    }
  }

  Future<void> _deleteRound(BuildContext context, ScheduledRound round) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Round ${round.roundNumber}?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        content: Text('Remove "${round.courseName}" from the trip schedule?', style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await tripScheduleRepository.deleteScheduledRound(round.id);
    }
  }

  Future<void> _openAddEditRoundDialog(
    BuildContext context, {
    ScheduledRound? round,
  }) async {
    final courses = await courseRepository.getAllCourses();
    if (courses.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please load courses first from Courses & Tees tab.', style: TextStyle(fontSize: 16))),
        );
      }
      return;
    }

    final schedule = await tripScheduleRepository.getSchedule();
    final defaultRoundNumber = round != null ? round.roundNumber : schedule.length + 1;

    final courseExists = courses.any((c) => c.id == round?.courseId);
    String selectedCourseId = courseExists ? round!.courseId : (courses.isNotEmpty ? courses.first.id : '');
    DateTime selectedDate = round?.date ?? DateTime.now().add(Duration(days: schedule.length));
    TimeOfDay selectedTime1 = const TimeOfDay(hour: 9, minute: 30);
    TimeOfDay selectedTime2 = const TimeOfDay(hour: 9, minute: 42);
    bool isFinal = round?.isFinalRound ?? false;
    final notesController = TextEditingController(text: round?.notes ?? '');

    if (round != null) {
      try {
        final parsed1 = DateFormat('h:mm a').parse(round.teeTimeGroup1);
        selectedTime1 = TimeOfDay(hour: parsed1.hour, minute: parsed1.minute);
      } catch (_) {}
      try {
        final parsed2 = DateFormat('h:mm a').parse(round.teeTimeGroup2);
        selectedTime2 = TimeOfDay(hour: parsed2.hour, minute: parsed2.minute);
      } catch (_) {}
    }

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B1726),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            String formatTime(TimeOfDay t) {
              final now = DateTime.now();
              final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
              return DateFormat('h:mm a').format(dt);
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            round != null ? 'Edit Round ${round.roundNumber} & Tee Times' : 'Add Round to Schedule',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: () => Navigator.pop(modalCtx),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.cardBorder, height: 20),

                      // Explanatory AI Pairing Note
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F263A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.lakeCyan.withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: AppColors.lakeCyan, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'AI Pairing Notice: When pairings are generated, the engine examines all team pairings prior to this date to ensure golfers who have been paired up before are not paired together again.',
                                style: TextStyle(fontSize: 13, color: Colors.white, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Course Dropdown
                      const Text('Course *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
                      const SizedBox(height: 6),
                      Builder(builder: (ctx) {
                        final validCourseId = courses.any((c) => c.id == selectedCourseId)
                            ? selectedCourseId
                            : (courses.isNotEmpty ? courses.first.id : null);
                        return DropdownButtonFormField<String>(
                          key: ValueKey('round_course_${validCourseId}_${courses.length}'),
                          initialValue: validCourseId,
                          dropdownColor: AppColors.surfaceElevated,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surfaceElevated,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: courses.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedCourseId = val);
                          },
                        );
                      }),
                      const SizedBox(height: 14),

                      // Date Picker
                      const Text('Date of Play *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: modalCtx,
                            initialDate: selectedDate,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setModalState(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const Icon(Icons.calendar_month, color: AppColors.cyanLight),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Tee Times Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Group 1 Tee Time', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white70)),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showTimePicker(context: modalCtx, initialTime: selectedTime1);
                                    if (picked != null) setModalState(() => selectedTime1 = picked);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.cardBorder),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(formatTime(selectedTime1), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                        const Icon(Icons.access_time, size: 20, color: AppColors.lakeCyan),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Group 2 Tee Time', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white70)),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showTimePicker(context: modalCtx, initialTime: selectedTime2);
                                    if (picked != null) setModalState(() => selectedTime2 = picked);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.cardBorder),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(formatTime(selectedTime2), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                        const Icon(Icons.access_time, size: 20, color: AppColors.lakeCyan),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Final Championship Round Switch
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Championship Final Round', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: const Text('Top 4 cumulative leaders pick their 2-man partners from bottom 4', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        value: isFinal,
                        activeThumbColor: AppColors.duneSand,
                        onChanged: (val) => setModalState(() => isFinal = val),
                      ),
                      const SizedBox(height: 10),

                      // Notes Input
                      TextFormField(
                        controller: notesController,
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          hintText: 'e.g. Opening Round, Lunch after, etc.',
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Save Button
                      ElevatedButton(
                        onPressed: () async {
                          final selectedCourse = courses.firstWhere((c) => c.id == selectedCourseId);
                          final isShort = selectedCourse.holeCount != 18;
                          final newRound = ScheduledRound(
                            id: round?.id ?? 'sched_${DateTime.now().millisecondsSinceEpoch}',
                            roundNumber: defaultRoundNumber,
                            courseId: selectedCourse.id,
                            courseName: selectedCourse.name,
                            date: selectedDate,
                            teeTimeGroup1: formatTime(selectedTime1),
                            teeTimeGroup2: formatTime(selectedTime2),
                            notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                            isFinalRound: isShort ? false : isFinal,
                            holeCount: selectedCourse.holeCount,
                            format: isShort ? 'Birdie Pot Only (Short Course)' : '2-Man Best Ball Net Stableford',
                            pairingPlan: isShort ? null : round?.pairingPlan,
                          );

                          await tripScheduleRepository.addOrUpdateScheduledRound(newRound);
                          if (modalCtx.mounted) Navigator.pop(modalCtx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lakeCyan,
                          foregroundColor: const Color(0xFF04111D),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          round != null ? 'Update Scheduled Round' : 'Save Round to Schedule',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
