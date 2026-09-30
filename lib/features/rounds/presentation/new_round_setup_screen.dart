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
  StreamSubscription<List<Course>>? _coursesSubscription;
  StreamSubscription<List<ScheduledRound>>? _scheduleSubscription;
  StreamSubscription<bool>? _finalizedSubscription;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _playersSubscription = widget.playerRepository.watchAllPlayers().listen((players) {
      if (mounted) {
        _onRosterPlayersUpdated(players);
      }
    });
    _coursesSubscription = widget.courseRepository.watchAllCourses().listen((courses) {
      if (mounted) {
        _onCoursesUpdated(courses);
      }
    });
    _scheduleSubscription = _scheduleRepo.watchSchedule().listen((schedule) {
      if (mounted) {
        _onScheduleUpdated(schedule);
      }
    });
    _finalizedSubscription = _scheduleRepo.watchIsFinalized().listen((finalized) {
      if (mounted) {
        setState(() {
          _isScheduleFinalized = finalized;
        });
      }
    });
  }

  @override
  void dispose() {
    _playersSubscription?.cancel();
    _coursesSubscription?.cancel();
    _scheduleSubscription?.cancel();
    _finalizedSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onScheduleUpdated(List<ScheduledRound> freshSchedule) async {
    _tripSchedule = freshSchedule;
    await _syncWithScheduleForRound(_roundNumber, updateCourse: true);
    if (mounted) setState(() {});
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

    final matchingScheduled = _tripSchedule.where((r) => r.roundNumber == _roundNumber).firstOrNull;
    final isShort = (matchingScheduled != null && matchingScheduled.isShortCourse) ||
        (_selectedCourseDetails != null && _selectedCourseDetails!.holes.length != 18);

    if (isShort) {
      _currentPairingPlan = null;
      _playerFoursomes.clear();
      _playerTwoManTeams.clear();
      _twoManTeamNames.clear();
    } else if (matchingScheduled?.pairingPlan != null) {
      // Reconcile with scheduled pairing plan
      final refreshedPlan = matchingScheduled!.pairingPlan!.withLatestPlayers(freshPlayers);
      _applyPairingPlan(refreshedPlan);
    } else if (_currentPairingPlan != null) {
      final planPlayerIds = _currentPairingPlan!.allTeams
          .expand((t) => t.players.map((p) => p.id))
          .toSet();

      final allPlanPlayersStillExist = planPlayerIds.every((id) => freshIds.contains(id));

      if (allPlanPlayersStillExist && planPlayerIds.length == freshPlayers.length) {
        final refreshedPlan = _currentPairingPlan!.withLatestPlayers(freshPlayers);
        _applyPairingPlan(refreshedPlan);
      } else if (freshPlayers.length >= 8 && !_isFinalRound) {
        _generateAIPairingsInternal(freshPlayers, _pastSavedRounds, _roundNumber);
      }
    } else if (freshPlayers.length >= 8 && !_isFinalRound) {
      _generateAIPairingsInternal(freshPlayers, _pastSavedRounds, _roundNumber);
    }

    setState(() {
      _allPlayers = freshPlayers;
    });
  }

  Future<void> _onCoursesUpdated(List<Course> freshCourses) async {
    if (_isLoading) return;

    final currentCourseStillExists =
        _selectedCourseId != null && freshCourses.any((c) => c.id == _selectedCourseId);

    String? newSelectedCourseId;
    CourseDetails? newCourseDetails;

    if (currentCourseStillExists) {
      newSelectedCourseId = _selectedCourseId;
      newCourseDetails = await widget.courseRepository.getCourseDetails(newSelectedCourseId!);
    } else if (freshCourses.isNotEmpty) {
      newSelectedCourseId = freshCourses.first.id;
      newCourseDetails = await widget.courseRepository.getCourseDetails(newSelectedCourseId);
    } else {
      newSelectedCourseId = null;
      newCourseDetails = null;
    }

    if (!mounted) return;

    setState(() {
      _courses = freshCourses;
      _selectedCourseId = newSelectedCourseId;
      _selectedCourseDetails = newCourseDetails;
      if (newCourseDetails != null) {
        _assignDefaultTees(_allPlayers, newCourseDetails);
      } else {
        _playerTeeIds.clear();
      }
    });

    await _syncWithScheduleForRound(_roundNumber, updateCourse: false);
  }

  Future<void> _syncWithScheduleForRound(int rNum, {bool updateCourse = true}) async {
    final matchingScheduled = _tripSchedule.where((r) => r.roundNumber == rNum).firstOrNull;

    if (matchingScheduled != null) {
      if (updateCourse && matchingScheduled.courseId.isNotEmpty) {
        final matchingCourse = _courses.where((c) => c.id == matchingScheduled.courseId).firstOrNull;
        if (matchingCourse != null && _selectedCourseId != matchingCourse.id) {
          _selectedCourseId = matchingCourse.id;
          _selectedCourseDetails = await widget.courseRepository.getCourseDetails(matchingCourse.id);
          if (_selectedCourseDetails != null) {
            _assignDefaultTees(_allPlayers, _selectedCourseDetails);
          }
        }
      }

      final isShort = matchingScheduled.isShortCourse ||
          (_selectedCourseDetails != null && _selectedCourseDetails!.holes.length != 18);

      _isFinalRound = matchingScheduled.isFinalRound;

      if (isShort) {
        _currentPairingPlan = null;
        _playerFoursomes.clear();
        _playerTwoManTeams.clear();
        _twoManTeamNames.clear();
      } else if (matchingScheduled.pairingPlan != null) {
        final plan = matchingScheduled.pairingPlan!.withLatestPlayers(_allPlayers);
        _applyPairingPlan(plan);
      } else if (_allPlayers.length >= 8 && !_isFinalRound) {
        await _generateAIPairingsInternal(_allPlayers, _pastSavedRounds, rNum);
      }
    } else {
      final isShort = (_selectedCourseDetails != null && _selectedCourseDetails!.holes.length != 18);
      if (isShort) {
        _currentPairingPlan = null;
        _playerFoursomes.clear();
        _playerTwoManTeams.clear();
        _twoManTeamNames.clear();
      } else if (_currentPairingPlan == null && _allPlayers.length >= 8 && !_isFinalRound) {
        await _generateAIPairingsInternal(_allPlayers, _pastSavedRounds, rNum);
      }
    }
  }

  Future<void> _loadInitialData() async {
    final courses = await widget.courseRepository.getAllCourses();
    final players = await widget.playerRepository.getAllPlayers();
    final savedRounds = await widget.roundRepository.getAllSavedRounds();
    final schedule = await _scheduleRepo.getSchedule();
    final finalized = await _scheduleRepo.isScheduleFinalized();
    _courses = courses;
    _allPlayers = players;
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

    _selectedPlayerIds.addAll(players.map((p) => p.id));

    if (_courses.isNotEmpty) {
      _selectedCourseId = _courses.first.id;
      _selectedCourseDetails = await widget.courseRepository.getCourseDetails(_selectedCourseId!);
      _assignDefaultTees(players, _selectedCourseDetails);
    }

    await _syncWithScheduleForRound(_roundNumber, updateCourse: true);

    setState(() {
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
    final isShort = (details?.holes.length ?? 0) != 18;
    setState(() {
      _selectedCourseId = courseId;
      _selectedCourseDetails = details;
      if (details != null) {
        _assignDefaultTees(_allPlayers, details);
      }
      if (isShort) {
        _currentPairingPlan = null;
        _playerFoursomes.clear();
        _playerTwoManTeams.clear();
        _twoManTeamNames.clear();
      }
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

    final isShortCourse = _selectedCourseDetails!.holes.length != 18;

    final sessionPlayers = selectedPlayers.asMap().entries.map((entry) {
      final idx = entry.key;
      final p = entry.value;
      final teeId = _playerTeeIds[p.id] ??
          _selectedCourseDetails!.teeBoxes.first.teeBox.id;
      final teeObj = _selectedCourseDetails!.teeBoxes
          .firstWhere((t) => t.teeBox.id == teeId,
              orElse: () => _selectedCourseDetails!.teeBoxes.first)
          .teeBox;

      final courseHcp = _computeCourseHcp(p, teeId);
      final teamId = _playerTeams[p.id] ?? 'none';
      final foursomeGroup = isShortCourse ? (idx < 4 ? 1 : 2) : (_playerFoursomes[p.id] ?? (idx < 4 ? 1 : 2));
      final twoManTeamId = isShortCourse ? 'none' : (_playerTwoManTeams[p.id] ?? teamId);
      final twoManTeamName = isShortCourse ? null : _twoManTeamNames[twoManTeamId];

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

    final sessionFormat = isShortCourse
        ? 'Birdie Pot Only (Short Course)'
        : (_isFinalRound ? 'modified_stableford' : _format);

    final session = ActiveRoundSession(
      courseId: _selectedCourseDetails!.course.id,
      courseName: _selectedCourseDetails!.course.name,
      roundNumber: _roundNumber,
      format: sessionFormat,
      isFinalRound: _isFinalRound && !isShortCourse,
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
                    Builder(builder: (ctx) {
                      final validCourseId = _courses.any((c) => c.id == _selectedCourseId)
                          ? _selectedCourseId
                          : _courses.first.id;
                      return DropdownButtonFormField<String>(
                        key: ValueKey('round_setup_course_${validCourseId}_${_courses.length}'),
                        initialValue: validCourseId,
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
                      );
                    }),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Builder(builder: (ctx) {
                          final maxScheduled = _tripSchedule.isNotEmpty
                              ? _tripSchedule.map((r) => r.roundNumber).reduce((a, b) => a > b ? a : b)
                              : 7;
                          final maxRound = [_roundNumber, maxScheduled, 7].reduce((a, b) => a > b ? a : b);
                          final roundOptions = List.generate(maxRound, (i) => i + 1);

                          return DropdownButtonFormField<int>(
                            key: ValueKey('round_num_$_roundNumber'),
                            initialValue: _roundNumber,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Round #',
                              labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            items: roundOptions
                                .map((r) {
                                  final matching = _tripSchedule.where((s) => s.roundNumber == r).firstOrNull;
                                  final suffix = matching != null && matching.isShortCourse ? ' (${matching.holeCount}H Short)' : '';
                                  return DropdownMenuItem(
                                    value: r,
                                    child: Text('Round $r$suffix', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  );
                                })
                                .toList(),
                            onChanged: (v) async {
                              if (v != null) {
                                setState(() {
                                  _roundNumber = v;
                                });
                                await _syncWithScheduleForRound(v, updateCourse: true);
                                if (mounted) setState(() {});
                              }
                            },
                          );
                        }),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Builder(builder: (ctx) {
                          final matching = _tripSchedule.where((r) => r.roundNumber == _roundNumber).firstOrNull;
                          final isShort = (matching != null && matching.isShortCourse) ||
                              (_selectedCourseDetails != null && _selectedCourseDetails!.holes.length != 18);
                          final formatTitle = isShort
                              ? 'Birdie Pot Only'
                              : (_isFinalRound ? 'Modified Stableford' : '2-Man Stableford');
                          final formatSub = isShort
                              ? 'Short Course (${matching?.holeCount ?? _selectedCourseDetails?.holes.length ?? 0}H)'
                              : (_isFinalRound ? 'Draft Pairs' : 'Best Ball Points');

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isShort ? const Color(0xFF2E1065) : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isShort ? const Color(0xFFA855F7) : AppColors.cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isShort ? 'COURSE TYPE' : 'Scoring Format',
                                  style: TextStyle(fontSize: 12, color: isShort ? const Color(0xFFD8B4FE) : Colors.white60, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatTitle,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: isShort ? const Color(0xFFF3E8FF) : AppColors.cyanLight,
                                  ),
                                ),
                                Text(
                                  formatSub,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isShort ? const Color(0xFFD8B4FE) : Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Final Round Toggle / Modified rules banner
                  Builder(builder: (ctx) {
                    final matching = _tripSchedule.where((r) => r.roundNumber == _roundNumber).firstOrNull;
                    final isShort = (matching != null && matching.isShortCourse) ||
                        (_selectedCourseDetails != null && _selectedCourseDetails!.holes.length != 18);

                    if (isShort) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1033),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFFD8B4FE), size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Short courses do not count in Stableford points or championship draft seeding.',
                                style: TextStyle(fontSize: 13, color: Color(0xFFE9D5FF), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Container(
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
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // AI FOURSOMES & 2-MAN TEAMS CARD OR SHORT COURSE CARD
          Builder(builder: (ctx) {
            final matching = _tripSchedule.where((r) => r.roundNumber == _roundNumber).firstOrNull;
            final isShort = (matching != null && matching.isShortCourse) ||
                (_selectedCourseDetails != null && _selectedCourseDetails!.holes.length != 18);
            final shortHoles = matching?.holeCount ?? _selectedCourseDetails?.holes.length ?? 0;

            if (isShort) {
              return Card(
                color: const Color(0xFF1E1033),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFA855F7), width: 1.5),
                ),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA855F7).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFA855F7)),
                            ),
                            child: Text(
                              '⛳ SHORT COURSE ($shortHoles HOLES)',
                              style: const TextStyle(
                                color: Color(0xFFE9D5FF),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'BIRDIE POT ONLY',
                            style: TextStyle(
                              color: Color(0xFFC084FC),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'This course has fewer than 18 regulation holes. Per tournament rules, it is NOT used for 2-man pairings and does NOT count towards Stableford tournament standings.\n\nAll golfers play for the cash Birdie Pot (\$2/birdie per player) — all birdies made are automatically added to the trip pot!',
                        style: TextStyle(fontSize: 14, color: Color(0xFFF3E8FF), height: 1.45),
                      ),
                    ],
                  ),
                ),
              );
            }

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

                    if (matching?.pairingPlan != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C241B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF34D399)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock, size: 16, color: Color(0xFF34D399)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isScheduleFinalized
                                    ? 'Loaded locked-in teams & pairings from finalized Trip Schedule.'
                                    : 'Synced with Trip Schedule (Round $_roundNumber pairings).',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF6EE7B7), fontWeight: FontWeight.bold),
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
            );
          }),
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
                              Builder(builder: (ctx) {
                                final safeTeeId = _selectedCourseDetails!.teeBoxes.any((t) => t.teeBox.id == teeId)
                                    ? teeId
                                    : _selectedCourseDetails!.teeBoxes.first.teeBox.id;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceDark,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: DropdownButton<String>(
                                    key: ValueKey('player_tee_${player.id}_$safeTeeId'),
                                    value: safeTeeId,
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
                                );
                              }),
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
