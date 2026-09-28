import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../database/app_database.dart';
import '../../../shared/services/app_settings_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../courses/repository/course_repository.dart';
import '../../players/repository/player_repository.dart';
import '../../publish/services/website_publish_service.dart';
import '../../rounds/import/presentation/gemini_key_config_dialog.dart';
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
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined, color: AppColors.lakeCyan, size: 28),
            tooltip: 'Push Standings to Website',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.lakeCyan),
                      ),
                      SizedBox(width: 14),
                      Text('Pushing updated standings to live website...'),
                    ],
                  ),
                  duration: Duration(seconds: 1),
                ),
              );
              final result = await WebsitePublishService.publishTournament(
                tournamentRepo: tournamentRepository,
                courseRepo: courseRepository,
                playerRepo: playerRepository,
                roundRepo: roundRepository,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.success
                          ? '✅ Standings pushed to website successfully (${DateFormat('h:mm a').format(DateTime.now())})'
                          : '⚠️ ${result.message}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: result.success ? const Color(0xFF0F382A) : const Color(0xFF381515),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppColors.duneSand, size: 26),
            tooltip: 'Configure Gemini AI Key',
            onPressed: () => GeminiKeyConfigDialog.show(context),
          ),
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
                height: 310,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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

                                // Large Prominent Tournament Crest Emblem with Hero Morph
                                Hero(
                                  tag: 'arcadia_cup_crest_hero',
                                  child: Material(
                                    type: MaterialType.transparency,
                                    child: Container(
                                      width: 96,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.duneSand, width: 3.2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.duneSand.withValues(alpha: 0.5),
                                            blurRadius: 18,
                                            spreadRadius: 2,
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.8),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
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
              const SizedBox(height: 14),

              // Public Website Summary & Live Standings Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A2218), Color(0xFF04110A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lakeCyan.withValues(alpha: 0.7), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lakeCyan.withValues(alpha: 0.15),
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.lakeCyan.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.public, color: AppColors.lakeCyan, size: 22),
                            ),
                            const SizedBox(width: 10),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WEBSITE SUMMARY',
                                  style: TextStyle(
                                    color: AppColors.cyanLight,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  'Live Web Leaderboard & Pairings',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.greenAccent),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.fiber_manual_record, color: Colors.greenAccent, size: 10),
                              SizedBox(width: 4),
                              Text(
                                'ONLINE',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'All 8 players can open this website on any phone or browser to see real-time cumulative standings, preliminary pairings, birdie pots, and detailed scorecards.',
                      style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.lakeCyan.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.public, size: 16, color: AppColors.lakeCyan),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  AppSettingsService.defaultWebsiteUrl,
                                  style: TextStyle(
                                    color: AppColors.cyanLight,
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.bolt, size: 16, color: AppColors.duneSand),
                              const SizedBox(width: 8),
                              const Text(
                                'Short Link: ',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                AppSettingsService.defaultTinyUrl,
                                style: const TextStyle(
                                  color: AppColors.duneSand,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_browser, size: 20, color: Color(0xFF04110A)),
                        label: const Text(
                          'OPEN SITE',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF04110A),
                            fontSize: 14,
                            letterSpacing: 0.8,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyanLight,
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          final uri = Uri.parse(AppSettingsService.defaultWebsiteUrl);
                          try {
                            final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                            if (!launched && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not open browser for URL.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error launching browser: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.cyanLight),
                            label: const Text(
                              'COPY URL',
                              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.cyanLight, fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.lakeCyan, width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                            onPressed: () async {
                              await Clipboard.setData(
                                const ClipboardData(text: AppSettingsService.defaultTinyUrl),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 20),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text('Short URL (https://tinyurl.com/2xnkqbrx) copied to clipboard!'),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Color(0xFF0F3224),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.share, size: 18, color: AppColors.cyanLight),
                            label: const Text(
                              'Share Link',
                              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.cyanLight, fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.lakeCyan, width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                            onPressed: () {
                              Share.share(
                                '🏌️ Arcadia Cup 2026 Live Standings & Tournament Summary:\n'
                                '${AppSettingsService.defaultWebsiteUrl}\n\n'
                                'Short link: ${AppSettingsService.defaultTinyUrl}',
                                subject: 'Arcadia Cup 2026 Live Tournament Summary',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
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
