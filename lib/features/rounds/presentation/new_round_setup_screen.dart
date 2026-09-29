import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../database/app_database.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/player_avatar.dart';
import '../../courses/models/course_models.dart';
import '../../courses/models/scheduled_round.dart';
import '../../courses/repository/course_repository.dart';
import '../../courses/repository/trip_schedule_repository.dart';
import '../../players/repository/player_repository.dart';
import '../../tournaments/presentation/final_round_draft_screen.dart';
import '../../tournaments/repository/tournament_repository.dart';
import '../../tournaments/services/tournament_pairings_engine.dart';
import '../models/active_round_session.dart';
import '../models/scoring_calculator.dart';
import '../repository/round_repository.dart';
import 'active_scoring_screen.dart';

class NewRoundSetupScreen extends StatefulWidget {
  final CourseRepository courseRepository;
  final PlayerRepository playerRepository;
  final TournamentRepository tournamentRepository;
  final RoundRepository roundRepository;
  final String? tournamentId;

  const NewRoundSetupScreen({
    super.key,
    required this.courseRepository,
    required this.playerRepository,
    required this.tournamentRepository,
    required this.roundRepository,
    this.tournamentId,
  });

  @override
  State<NewRoundSetupScreen> createState() => _NewRoundSetupScreenState();
}

class _NewRoundSetupScreenState extends State<NewRoundSetupScreen> {
  final TournamentPairingsEngine _pairingsEngine = TournamentPairingsEngine();
  final TripScheduleRepository _scheduleRepo = TripScheduleRepository();

  List<Course> _courses = [];
  CourseDetails? _selectedCourseDetails;
  String? _selectedCourseId;

  List<Player> _allPlayers = [];
  final Set<String> _selectedPlayerIds = {};
  final Map<String, String> _playerTeeIds = {}; // playerId -> teeBoxId
  final Map<String, String> _playerTeams = {}; // playerId -> 'a', 'b', 'none'

  // AI Pairings & 2-Man Teams
  final Map<String, int> _playerFoursomes = {}; // playerId -> 1 or 2
  final Map<String, String> _playerTwoManTeams = {}; // playerId -> 'T1', 'T2', etc.
  final Map<String, String> _twoManTeamNames = {}; // 'T1' -> 'Bob & Dave'
  RoundPairingPlan? _currentPairingPlan;
  List<ActiveRoundSession> _pastSavedRounds = [];
  List<ScheduledRound> _tripSchedule = [];
  bool _isScheduleFinalized = false;

  int _roundNumber = 1;
  bool _isFinalRound = false;
  final String _format = 'stableford';
  final int _pointsPerSkin = 2;
  bool _isLoading = true;
  StreamSubscription<List<Player>>? _playersSubscription;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _playersSubscription = widget.playerRepository.watchAllPlayers().listen((players) {
      if (mounted) {
        _onRosterPlayersUpdated(players);
      }
    });
  }

  @override
  void dispose() {
    _playersSubscription?.cancel();
    super.dispose();
  }

  void _onRosterPlayersUpdated(List<Player> freshPlayers) {
    if (_isLoading) return;

    final existingIds = _allPlayers.map((p) => p.id).toSet();
    final freshIds = freshPlayers.map((p) => p.id).toSet();

    // Reconcile selected players:
    // Remove any player IDs that no longer exist
    _selectedPlayerIds.removeWhere((id) => !freshIds.contains(id));
    // For newly added players (weren't in previous roster), add them to selection
    for (final p in freshPlayers) {
      if (!existingIds.contains(p.id)) {
        _selectedPlayerIds.add(p.id);
      }
    }

    // Reconcile default tees
    _assignDefaultTees(freshPlayers, _selectedCourseDetails);

    // Reconcile pairing plan
    if (_currentPairingPlan != null) {
      final planPlayerIds = _currentPairingPlan!.allTeams
          .expand((t) => t.players.map((p) => p.id))
          .toSet();

      // Check if all players in the existing plan still exist in the fresh roster
      final allPlanPlayersStillExist = planPlayerIds.every((id) => freshIds.contains(id));

      if (allPlanPlayersStillExist && planPlayerIds.length == freshPlayers.length) {
        // Refresh player details (names, nicknames, handicaps) and dynamic team names
        final refreshedPlan = _currentPairingPlan!.withLatestPlayers(freshPlayers);
        _applyPairingPlan(refreshedPlan);
      } else if (freshPlayers.length >= 8) {
        // Player set changed (added/removed) - re-generate balanced AI pairings
        _generateAIPairingsInternal(freshPlayers, _pastSavedRounds, _roundNumber);
      }
    } else if (freshPlayers.length >= 8) {
      _generateAIPairingsInternal(freshPlayers, _pastSavedRounds, _roundNumber);
    }

    setState(() {
      _allPlayers = freshPlayers;
    });
  }

  Future<void> _loadInitialData() async {
    final courses = await widget.courseRepository.getAllCourses();
    final players = await widget.playerRepository.getAllPlayers();
    final savedRounds = await widget.roundRepository.getAllSavedRounds();
    final schedule = await _scheduleRepo.getSchedule();
    final finalized = await _scheduleRepo.isScheduleFinalized();
    _tripSchedule = schedule;
    _isScheduleFinalized = finalized;

    _roundNumber = savedRounds.length + 1;

    // Parse past rounds
    final sessions = <ActiveRoundSession>[];
    for (final r in savedRounds) {
      try {
        final map = jsonDecode(r.roundPayloadJson) as Map<String, dynamic>;
        sessions.add(ActiveRoundSession.fromJson(map));
      } catch (_) {}
    }
    _pastSavedRounds = sessions;

    if (widget.tournamentId != null) {
      final tPlayers = await widget.tournamentRepository
          .getTournamentPlayers(widget.tournamentId!);
      for (final tp in tPlayers) {
        _playerTeams[tp.player.id] = tp.teamId;
      }
    }

    // Check if scheduled round exists for this roundNumber
    final matchingScheduled = schedule.where((r) => r.roundNumber == _roundNumber).firstOrNull;
    if (matchingScheduled != null) {
      final matchingCourse = courses.where((c) => c.id == matchingScheduled.courseId).firstOrNull;
      if (matchingCourse != null) {
        _selectedCourseId = matchingCourse.id;
        _selectedCourseDetails =
            await widget.courseRepository.getCourseDetails(matchingCourse.id);
      } else if (courses.isNotEmpty) {
        _selectedCourseId = courses.first.id;
        _selectedCourseDetails =
            await widget.courseRepository.getCourseDetails(courses.first.id);
      }
      _isFinalRound = matchingScheduled.isFinalRound;
    } else if (courses.isNotEmpty) {
      _selectedCourseId = courses.first.id;
      _selectedCourseDetails =
          await widget.courseRepository.getCourseDetails(courses.first.id);
    }

    _selectedPlayerIds.addAll(players.map((p) => p.id));
    _assignDefaultTees(players, _selectedCourseDetails);

    // Apply scheduled pairing plan if available, or generate one
    if (matchingScheduled != null && matchingScheduled.pairingPlan != null) {
      _applyPairingPlan(matchingScheduled.pairingPlan!);
    } else if (players.length >= 8) {
      await _generateAIPairingsInternal(players, sessions, _roundNumber);
    }

    setState(() {
      _courses = courses;
      _allPlayers = players;
      _isLoading = false;
    });
  }

  Future<void> _generateAIPairingsInternal(
    List<Player> players,
    List<ActiveRoundSession> pastRounds,
    int rNum,
  ) async {
    final matchingScheduled = _tripSchedule.where((r) => r.roundNumber == rNum).firstOrNull;
    final roundDate = matchingScheduled?.date ?? DateTime.now();

    final priorScheduledInfos = _tripSchedule
        .where((r) =>
            r.date.isBefore(roundDate) ||
            (TournamentPairingsEngine.isSameDay(r.date, roundDate) && r.roundNumber < rNum))
        .map((r) => ScheduledRoundInfo(
              roundNumber: r.roundNumber,
              date: r.date,
              pairingPlan: r.pairingPlan,
            ))
        .toList();

    final plan = _pairingsEngine.generateSchedulePairingsForDate(
      players: players,
      roundDate: roundDate,
      roundNumber: rNum,
      pastCompletedRounds: pastRounds,
      priorScheduledRounds: priorScheduledInfos,
    );
    _applyPairingPlan(plan);
  }

  void _applyPairingPlan(RoundPairingPlan plan) {
    _currentPairingPlan = plan;
    _isFinalRound = plan.isFinalRound;
    _playerFoursomes.clear();
    _playerTwoManTeams.clear();
    _twoManTeamNames.clear();

    for (final f in plan.foursomes) {
      for (final p in f.teamA.players) {
        _playerFoursomes[p.id] = f.groupNumber;
        _playerTwoManTeams[p.id] = f.teamA.teamId;
      }
      _twoManTeamNames[f.teamA.teamId] = f.teamA.teamName;

      for (final p in f.teamB.players) {
        _playerFoursomes[p.id] = f.groupNumber;
        _playerTwoManTeams[p.id] = f.teamB.teamId;
      }
      _twoManTeamNames[f.teamB.teamId] = f.teamB.teamName;
    }
  }

  void _assignDefaultTees(List<Player> players, CourseDetails? courseDetails) {
    if (courseDetails == null || courseDetails.teeBoxes.isEmpty) return;
    for (final p in players) {
      final match = courseDetails.teeBoxes
          .where((t) =>
              t.teeBox.name.toLowerCase() ==
              (p.preferredTee ?? '').toLowerCase())
          .firstOrNull;
      _playerTeeIds[p.id] = match != null
          ? match.teeBox.id
          : courseDetails.teeBoxes.first.teeBox.id;
    }
  }

  Future<void> _onCourseChanged(String? courseId) async {
    if (courseId == null) return;
    final details = await widget.courseRepository.getCourseDetails(courseId);
    setState(() {
      _selectedCourseId = courseId;
      _selectedCourseDetails = details;
      _assignDefaultTees(_allPlayers, details);
    });
  }

  int _computeCourseHcp(Player player, String teeBoxId) {
    if (_selectedCourseDetails == null) return player.handicapIndex.round();
    final teeWithYards = _selectedCourseDetails!.teeBoxes
        .where((t) => t.teeBox.id == teeBoxId)
        .firstOrNull;
    if (teeWithYards == null) return player.handicapIndex.round();

    final tb = teeWithYards.teeBox;
    return ScoringCalculator.calculateCourseHandicap(
      handicapIndex: player.handicapIndex,
      slopeRating: tb.slopeRating,
      courseRating: tb.courseRating,
      par: _selectedCourseDetails!.totalPar,
    );
  }

  Future<void> _openFinalRoundDraft() async {
    final selectedPlayers = _allPlayers.where((p) => _selectedPlayerIds.contains(p.id)).toList();
    if (selectedPlayers.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all 8 players for the Final Round Draft.', style: TextStyle(fontSize: 17))),
      );
      return;
    }

    final plan = await Navigator.push<RoundPairingPlan>(
      context,
      MaterialPageRoute(
        builder: (_) => FinalRoundDraftScreen(
          players: selectedPlayers,
          pastRounds: _pastSavedRounds,
          roundNumber: _roundNumber,
          onConfirmPlan: (p) {},
        ),
      ),
    );

    if (plan != null && mounted) {
      setState(() {
        _applyPairingPlan(plan);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Final Round Draft confirmed! Modified Stableford rules activated.', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.lakeDeep,
        ),
      );
    }
  }

  Future<void> _startRound() async {
    if (_selectedCourseDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or configure a course first.', style: TextStyle(fontSize: 17))),
      );
      return;
    }

    if (_selectedPlayerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 1 player for this round.', style: TextStyle(fontSize: 17))),
      );
      return;
    }

    final selectedPlayers = _allPlayers
        .where((p) => _selectedPlayerIds.contains(p.id))
        .toList();

    final sessionPlayers = selectedPlayers.map((p) {
      final teeId = _playerTeeIds[p.id] ??
          _selectedCourseDetails!.teeBoxes.first.teeBox.id;
      final teeObj = _selectedCourseDetails!.teeBoxes
          .firstWhere((t) => t.teeBox.id == teeId,
              orElse: () => _selectedCourseDetails!.teeBoxes.first)
          .teeBox;

      final courseHcp = _computeCourseHcp(p, teeId);
      final teamId = _playerTeams[p.id] ?? 'none';
      final foursomeGroup = _playerFoursomes[p.id] ?? 1;
      final twoManTeamId = _playerTwoManTeams[p.id] ?? teamId;
      final twoManTeamName = _twoManTeamNames[twoManTeamId];

      return PlayerSessionInfo(
        playerId: p.id,
        name: p.fullName,
        nickname: p.nickname.isNotEmpty ? p.nickname : p.fullName.split(' ').first,
        initials: p.initials,
        handicapIndex: p.handicapIndex,
        courseHandicap: courseHcp,
        teeBoxId: teeId,
        teeName: teeObj.name,
        teamId: teamId,
        foursomeGroup: foursomeGroup,
        twoManTeamId: twoManTeamId,
        twoManTeamName: twoManTeamName,
      );
    }).toList();

    final sessionHoles = _selectedCourseDetails!.holes.map((h) {
      return HoleSessionInfo(
        holeNumber: h.holeNumber,
        par: h.par,
        strokeIndex: h.strokeIndex,
      );
    }).toList();

    final session = ActiveRoundSession(
      courseId: _selectedCourseDetails!.course.id,
      courseName: _selectedCourseDetails!.course.name,
      roundNumber: _roundNumber,
      format: _format,
      isFinalRound: _isFinalRound,
      pointsPerSkin: _pointsPerSkin,
      currentHoleNumber: 1,
      players: sessionPlayers,
      holes: sessionHoles,
    );

    await widget.roundRepository.saveActiveDraft(session);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ActiveScoringScreen(
            roundRepository: widget.roundRepository,
            session: session,
            playerRepository: widget.playerRepository,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isFinalRound ? 'Final Championship Setup' : 'Round Setup'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Course Selection Card
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COURSE & ROUND',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: AppColors.cyanLight,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_courses.isEmpty)
                    const Text(
                      'No courses added yet! Go to the Courses tab to add or template a course.',
                      style: TextStyle(color: Colors.redAccent, fontSize: 17),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCourseId,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Select Course',
                        labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        prefixIcon: Icon(Icons.golf_course, color: AppColors.lakeCyan, size: 28),
                      ),
                      items: _courses.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.name} (${c.holeCount}h)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: _onCourseChanged,
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _roundNumber,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Round #',
                            labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          items: [1, 2, 3, 4, 5]
                              .map((r) => DropdownMenuItem(
                                    value: r,
                                    child: Text('Round $r', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ))
                              .toList(),
                          onChanged: (v) async {
                            if (v != null) {
                              setState(() {
                                _roundNumber = v;
                              });
                              if (_allPlayers.length >= 8 && !_isFinalRound) {
                                await _generateAIPairingsInternal(_allPlayers, _pastSavedRounds, v);
                                if (mounted) setState(() {});
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Scoring Format', style: TextStyle(fontSize: 13, color: Colors.white60)),
                              const SizedBox(height: 2),
                              Text(
                                _isFinalRound ? 'Modified Stableford' : '2-Man Stableford',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.cyanLight),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Final Round Toggle / Modified rules banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isFinalRound ? Colors.red.withValues(alpha: 0.15) : AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _isFinalRound ? Colors.redAccent : AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isFinalRound ? '🏆 FINAL CHAMPIONSHIP ROUND' : 'Regular Trip Round',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: _isFinalRound ? Colors.redAccent : Colors.white,
                                ),
                              ),
                              Text(
                                _isFinalRound
                                    ? 'Modified Stableford: Dbl Bogey = -1, Bogey = 0, Par = +1, Birdie = +2'
                                    : 'Standard Stableford: Dbl Bogey = 0, Bogey = 1, Par = 2, Birdie = 3',
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isFinalRound,
                          activeThumbColor: Colors.redAccent,
                          onChanged: (val) {
                            setState(() => _isFinalRound = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // AI FOURSOMES & 2-MAN TEAMS CARD
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI FOURSOMES & 2-MAN TEAMS',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                                color: AppColors.cyanLight,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Equal playing time with all 7 others + Stableford teams',
                              style: TextStyle(fontSize: 13, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final selected = _allPlayers.where((p) => _selectedPlayerIds.contains(p.id)).toList();
                            await _generateAIPairingsInternal(selected, _pastSavedRounds, _roundNumber);
                            if (!mounted) return;
                            setState(() {});
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'AI examined prior pairings & generated non-repeating 2-man teams!',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.shuffle, size: 20, color: AppColors.lakeCyan),
                          label: const Text('AI Shuffle Pairings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.lakeCyan),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openFinalRoundDraft,
                          icon: const Icon(Icons.how_to_reg, size: 20),
                          label: const Text('Partner Draft (#1..#8)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.duneSand,
                            foregroundColor: const Color(0xFF06111D),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_isScheduleFinalized)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C241B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF34D399)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock, size: 16, color: Color(0xFF34D399)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Loaded locked-in teams & pairings from finalized Trip Schedule.',
                              style: TextStyle(fontSize: 13, color: Color(0xFF6EE7B7), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_currentPairingPlan != null) ...[
                    // Foursome 1
                    _buildFoursomeCard(1, _currentPairingPlan!.foursome1),
                    const SizedBox(height: 12),
                    // Foursome 2
                    _buildFoursomeCard(2, _currentPairingPlan!.foursome2),
                  ] else
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('Tap "AI Shuffle Pairings" or "Partner Draft" to assign teams.', style: TextStyle(color: Colors.white70)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Players & Tees Selection
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
                        'PLAYERS & TEES',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          color: AppColors.cyanLight,
                        ),
                      ),
                      Text(
                        '${_selectedPlayerIds.length} Selected',
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
                    const Text(
                      'No players in roster. Add players in the Roster tab.',
                      style: TextStyle(color: Colors.white70, fontSize: 17),
                    )
                  else
                    ..._allPlayers.map((player) {
                      final isSelected = _selectedPlayerIds.contains(player.id);
                      final teeId = _playerTeeIds[player.id];
                      final courseHcp = _computeCourseHcp(player, teeId ?? '');
                      final teamId = _playerTwoManTeams[player.id];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.cardSelected
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.lakeCyan
                                : AppColors.cardBorder,
                            width: isSelected ? 1.8 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Transform.scale(
                              scale: 1.25,
                              child: Checkbox(
                                value: isSelected,
                                activeColor: AppColors.lakeCyan,
                                checkColor: const Color(0xFF06111D),
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedPlayerIds.add(player.id);
                                    } else {
                                      _selectedPlayerIds.remove(player.id);
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 4),
                            PlayerAvatar(
                              initials: player.initials,
                              photoPath: player.photoPath,
                              radius: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        player.nickname.isNotEmpty
                                            ? player.nickname
                                            : player.fullName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 19,
                                          color: Colors.white,
                                        ),
                                      ),
                                      if (teamId != null && teamId != 'none') ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.lakeDeep,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            teamId,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.lakeCyan),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Index ${player.handicapIndex.toStringAsFixed(1)} • Course HCP $courseHcp',
                                    style: const TextStyle(
                                      color: AppColors.duneSand,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedCourseDetails != null &&
                                _selectedCourseDetails!.teeBoxes.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceDark,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: DropdownButton<String>(
                                  value: teeId,
                                  isDense: true,
                                  dropdownColor: AppColors.cardDark,
                                  underline: const SizedBox.shrink(),
                                  items: _selectedCourseDetails!.teeBoxes
                                      .map((t) => DropdownMenuItem(
                                            value: t.teeBox.id,
                                            child: Text(
                                              t.teeBox.name,
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _playerTeeIds[player.id] = val;
                                      });
                                    }
                                  },
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
            onPressed: _startRound,
            icon: const Icon(Icons.play_arrow, size: 30),
            label: Text(
              _isFinalRound ? 'Tee Off Championship Final' : 'Tee Off / Start Scoring',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              backgroundColor: _isFinalRound ? Colors.redAccent : AppColors.lakeCyan,
              foregroundColor: const Color(0xFF06111D),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFoursomeCard(int groupNumber, FoursomePlan foursome) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FOURSOME $groupNumber',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: AppColors.lakeCyan,
                ),
              ),
              const Text(
                '2-Man Match',
                style: TextStyle(fontSize: 13, color: Colors.white60, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildTeamBadge(foursome.teamA)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('VS', style: TextStyle(color: AppColors.duneSand, fontWeight: FontWeight.w900, fontSize: 14)),
              ),
              Expanded(child: _buildTeamBadge(foursome.teamB)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamBadge(TwoManTeamPlan team) {
    final n1 = team.player1.nickname.isNotEmpty ? team.player1.nickname : team.player1.fullName.split(' ').first;
    final n2 = team.player2.nickname.isNotEmpty ? team.player2.nickname : team.player2.fullName.split(' ').first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.duneSand.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            team.teamId,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.duneSand),
          ),
          const SizedBox(height: 2),
          Text(
            '$n1 & $n2',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'HCP ${(team.player1.handicapIndex + team.player2.handicapIndex).toStringAsFixed(1)} comb',
            style: const TextStyle(fontSize: 11, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}
