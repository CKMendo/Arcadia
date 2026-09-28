import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/app_database.dart';
import '../../../shared/services/app_settings_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/course_handicap_calculator.dart';
import '../../../shared/widgets/player_avatar.dart';
import '../../players/repository/player_repository.dart';
import '../../rounds/import/presentation/gemini_key_config_dialog.dart';
import '../repository/tournament_repository.dart';

class TournamentSetupScreen extends StatefulWidget {
  final TournamentRepository tournamentRepository;
  final PlayerRepository playerRepository;
  final Tournament? tournament;

  const TournamentSetupScreen({
    super.key,
    required this.tournamentRepository,
    required this.playerRepository,
    this.tournament,
  });

  @override
  State<TournamentSetupScreen> createState() => _TournamentSetupScreenState();
}

class _TournamentSetupScreenState extends State<TournamentSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _teamAController;
  late TextEditingController _teamBController;

  late DateTime _startDate;
  late DateTime _endDate;
  String _formatType = 'hybrid'; // 'hybrid', 'teams', 'individual'

  List<Player> _allPlayers = [];
  final Map<String, String> _playerTeams = {}; // playerId -> 'a', 'b', 'none'
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.tournament;
    _nameController = TextEditingController(
      text: t?.name ?? 'Arcadia Bluffs Trip 2027',
    );
    _teamAController = TextEditingController(text: t?.teamAName ?? 'Team Lake');
    _teamBController = TextEditingController(text: t?.teamBName ?? 'Team Bluff');
    _startDate = t != null
        ? DateTime.fromMillisecondsSinceEpoch(t.startDate)
        : DateTime.now();
    _endDate = t != null
        ? DateTime.fromMillisecondsSinceEpoch(t.endDate)
        : DateTime.now().add(const Duration(days: 4));
    _formatType = t?.formatType ?? 'hybrid';

    _loadData();
  }

  Future<void> _loadData() async {
    final players = await widget.playerRepository.getAllPlayers();
    if (widget.tournament != null) {
      final tPlayers = await widget.tournamentRepository
          .getTournamentPlayers(widget.tournament!.id);
      for (final tp in tPlayers) {
        _playerTeams[tp.player.id] = tp.teamId;
      }
    } else {
      // Default: half to Team A, half to Team B
      final half = (players.length / 2).ceil();
      for (var i = 0; i < players.length; i++) {
        _playerTeams[players[i].id] = i < half ? 'a' : 'b';
      }
    }

    setState(() {
      _allPlayers = players;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teamAController.dispose();
    _teamBController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final tournamentId = widget.tournament?.id ??
          await widget.tournamentRepository.createTournament(
            name: _nameController.text.trim(),
            startDate: _startDate,
            endDate: _endDate,
            formatType: _formatType,
            teamAName: _teamAController.text.trim(),
            teamBName: _teamBController.text.trim(),
            initialPlayerIds: _playerTeams.keys.toList(),
          );

      if (widget.tournament != null) {
        final updated = widget.tournament!.copyWith(
          name: _nameController.text.trim(),
          startDate: _startDate.millisecondsSinceEpoch,
          endDate: _endDate.millisecondsSinceEpoch,
          formatType: _formatType,
          teamAName: _teamAController.text.trim(),
          teamBName: _teamBController.text.trim(),
        );
        await widget.tournamentRepository.updateTournament(updated);
      }

      // Update player teams
      for (final entry in _playerTeams.entries) {
        await widget.tournamentRepository.updatePlayerTeam(
          tournamentId: tournamentId,
          playerId: entry.key,
          teamId: entry.value,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving trip: $e', style: const TextStyle(fontSize: 16)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tournament != null ? 'Edit Trip' : 'New Golf Trip'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TRIP OVERVIEW',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: AppColors.cyanLight,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              labelText: 'Trip / Event Name *',
                              labelStyle: TextStyle(fontSize: 17),
                              hintText: 'e.g. Arcadia Bluffs Cup 2027',
                              prefixIcon:
                                  Icon(Icons.emoji_events, color: AppColors.duneSand, size: 26),
                            ),
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: _selectDateRange,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cardBorder, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.date_range,
                                      color: AppColors.cyanLight, size: 28),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Dates',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.chevron_right,
                                      color: Colors.white54, size: 28),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0C1F33),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.lakeCyan.withValues(alpha: 0.5), width: 1.3),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.lock_outline, color: AppColors.cyanLight, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'COMPETITION FORMAT (FIXED)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.1,
                                        color: AppColors.cyanLight,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Text(
                                  '2-Man Best Ball Net Stableford',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Fixed tournament format for Arcadia Cup 2027. All rounds pair golfers into 2-man teams competing for points with individual Net Stableford tracked concurrently.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Player Rostering Card
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'PLAYER ROSTER',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: AppColors.cyanLight,
                                ),
                              ),
                              Text(
                                '${_allPlayers.length} / 8 Golfers',
                                style: const TextStyle(
                                  color: AppColors.duneSand,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (_allPlayers.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'No players found in roster. Add players in the Roster tab first.',
                                style: TextStyle(color: Colors.white54, fontSize: 16),
                              ),
                            )
                          else
                            ..._allPlayers.map((player) {
                              final tee = player.preferredTee ?? 'White';
                              final bluffsCh = CourseHandicapCalculator.forBluffs(player.handicapIndex, tee);
                              final southCh = CourseHandicapCalculator.forSouth(player.handicapIndex, tee);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    PlayerAvatar(
                                      name: player.fullName,
                                      initials: player.initials,
                                      photoPath: player.photoPath,
                                      radius: 22,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            player.fullName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: [
                                              Text(
                                                'HCP ${player.handicapIndex.toStringAsFixed(1)} ($tee)',
                                                style: const TextStyle(
                                                  color: AppColors.lakeCyan,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                '• Bluffs CH: $bluffsCh',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                '• South CH: $southCh',
                                                style: const TextStyle(
                                                  color: AppColors.duneSand,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
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

                  // TEAMS & PAIRINGS PER COURSE SECTION
                  _buildTeamsPerCourseCard(),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),

                  // AI Integration & Website Card
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
                                'AI INTEGRATION & WEBSITE',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: AppColors.cyanLight,
                                ),
                              ),
                              Icon(Icons.auto_awesome, color: AppColors.duneSand, size: 20),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Gemini API Key row
                          FutureBuilder<List<String?>>(
                            future: Future.wait([
                              AppSettingsService.getGeminiPrimaryApiKey(),
                              AppSettingsService.getGeminiSecondaryApiKey(),
                            ]),
                            builder: (context, snapshot) {
                              final keys = snapshot.data ?? [null, null];
                              final primaryKey = keys[0];
                              final secondaryKey = keys[1];
                              final hasPrimary = primaryKey != null && primaryKey.isNotEmpty;
                              final hasSecondary = secondaryKey != null && secondaryKey.isNotEmpty;
                              final hasAny = hasPrimary || hasSecondary;

                              final title = (hasPrimary && hasSecondary)
                                  ? 'Gemini 3.8 + 3.7 Dual Keys Active'
                                  : hasPrimary
                                      ? 'Gemini 3.8 Flash API Key'
                                      : hasSecondary
                                          ? 'Gemini 3.7 Backup Key Active'
                                          : 'Gemini Keys Not Configured';

                              final subtitle = (hasPrimary && hasSecondary)
                                  ? 'Primary 3.8 (...${primaryKey.length > 4 ? primaryKey.substring(primaryKey.length - 4) : primaryKey}) • Backup 3.7 (...${secondaryKey.length > 4 ? secondaryKey.substring(secondaryKey.length - 4) : secondaryKey})'
                                  : hasPrimary
                                      ? 'Primary active (...${primaryKey.length > 4 ? primaryKey.substring(primaryKey.length - 4) : primaryKey}). Tap to add a 3.7 backup key.'
                                      : hasSecondary
                                          ? 'Backup active (...${secondaryKey.length > 4 ? secondaryKey.substring(secondaryKey.length - 4) : secondaryKey}). Tap to add 3.8 primary key.'
                                          : 'Required for automatic scorecard vision scanning.';

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: hasAny
                                        ? Colors.greenAccent.withValues(alpha: 0.5)
                                        : AppColors.duneSand.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      hasAny ? Icons.check_circle_outline : Icons.vpn_key_outlined,
                                      color: hasAny ? Colors.greenAccent : AppColors.duneSand,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: hasAny ? Colors.greenAccent : AppColors.duneSand,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            subtitle,
                                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    FilledButton.tonal(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: hasAny
                                            ? AppColors.lakeCyan.withValues(alpha: 0.25)
                                            : AppColors.duneSand,
                                        foregroundColor: hasAny ? AppColors.cyanLight : Colors.black,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      onPressed: () async {
                                        final changed = await GeminiKeyConfigDialog.show(context);
                                        if (changed == true) {
                                          setState(() {});
                                        }
                                      },
                                      child: Text(
                                        hasAny ? 'Configure' : 'Add Keys',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // Website info
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.public, color: AppColors.lakeCyan, size: 22),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Live Tournament Website',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'ckmendo.github.io/Arcadia\nShort link: tinyurl.com/arcadia2027',
                                        style: TextStyle(
                                          color: AppColors.cyanLight,
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : Text(widget.tournament != null
                              ? 'Save Changes'
                              : 'Create Trip Event'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildTeamsPerCourseCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.golf_course, color: AppColors.cyanLight, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'ESTABLISHED TEAMS PER COURSE',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: AppColors.cyanLight,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Text(
                    '2 Courses',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.duneSand),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_allPlayers.length < 4)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Add at least 4 golfers to generate course pairings and 2-man teams.',
                  style: TextStyle(color: Colors.white60, fontSize: 15),
                ),
              )
            else ...[
              _buildCoursePairingsBlock(
                courseName: 'Arcadia Bluffs (The Bluffs)',
                subtitle: 'Par 72 • Championship Links',
                isSouth: false,
                players: _allPlayers,
              ),
              const SizedBox(height: 14),
              _buildCoursePairingsBlock(
                courseName: 'Arcadia Bluffs (The South)',
                subtitle: 'Par 72 • C.B. Macdonald Geometric Classic',
                isSouth: true,
                players: _allPlayers,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCoursePairingsBlock({
    required String courseName,
    required String subtitle,
    required bool isSouth,
    required List<Player> players,
  }) {
    // Generate pairings for this course
    final pList = List<Player>.from(players);
    // On South, rearrange partner pairings so players play with different partners
    final ordered = isSouth && pList.length >= 8
        ? [pList[0], pList[2], pList[1], pList[3], pList[4], pList[6], pList[5], pList[7]]
        : pList;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSouth ? const Color(0xFF26190C) : const Color(0xFF0F2B3E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.sports_golf,
                  color: isSouth ? AppColors.duneSand : AppColors.lakeCyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Group 1
          _buildPairingGroup(
            groupNum: 1,
            p1: ordered[0],
            p2: ordered[1],
            p3: ordered.length > 2 ? ordered[2] : null,
            p4: ordered.length > 3 ? ordered[3] : null,
            isSouth: isSouth,
          ),
          if (ordered.length >= 8) ...[
            const SizedBox(height: 10),
            _buildPairingGroup(
              groupNum: 2,
              p1: ordered[4],
              p2: ordered[5],
              p3: ordered[6],
              p4: ordered[7],
              isSouth: isSouth,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPairingGroup({
    required int groupNum,
    required Player p1,
    required Player p2,
    Player? p3,
    Player? p4,
    required bool isSouth,
  }) {
    final t1Ch1 = isSouth
        ? CourseHandicapCalculator.forSouth(p1.handicapIndex, p1.preferredTee ?? 'White')
        : CourseHandicapCalculator.forBluffs(p1.handicapIndex, p1.preferredTee ?? 'White');
    final t1Ch2 = isSouth
        ? CourseHandicapCalculator.forSouth(p2.handicapIndex, p2.preferredTee ?? 'White')
        : CourseHandicapCalculator.forBluffs(p2.handicapIndex, p2.preferredTee ?? 'White');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Foursome $groupNum',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.cyanLight),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.teamA.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.teamA.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Team 1', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.teamA)),
                      const SizedBox(height: 2),
                      Text('${p1.nickname} (HCP $t1Ch1)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('${p2.nickname} (HCP $t1Ch2)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              if (p3 != null && p4 != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('VS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.duneSand)),
                ),
                Expanded(
                  child: Builder(builder: (context) {
                    final t2Ch1 = isSouth
                        ? CourseHandicapCalculator.forSouth(p3.handicapIndex, p3.preferredTee ?? 'White')
                        : CourseHandicapCalculator.forBluffs(p3.handicapIndex, p3.preferredTee ?? 'White');
                    final t2Ch2 = isSouth
                        ? CourseHandicapCalculator.forSouth(p4.handicapIndex, p4.preferredTee ?? 'White')
                        : CourseHandicapCalculator.forBluffs(p4.handicapIndex, p4.preferredTee ?? 'White');
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.teamB.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.teamB.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Team 2', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.teamB)),
                          const SizedBox(height: 2),
                          Text('${p3.nickname} (HCP $t2Ch1)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('${p4.nickname} (HCP $t2Ch2)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
