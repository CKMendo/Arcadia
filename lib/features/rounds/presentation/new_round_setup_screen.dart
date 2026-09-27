import 'package:flutter/material.dart';
import '../../../database/app_database.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/player_avatar.dart';
import '../../courses/models/course_models.dart';
import '../../courses/repository/course_repository.dart';
import '../../players/repository/player_repository.dart';
import '../../tournaments/repository/tournament_repository.dart';
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
  List<Course> _courses = [];
  CourseDetails? _selectedCourseDetails;
  String? _selectedCourseId;

  List<Player> _allPlayers = [];
  final Set<String> _selectedPlayerIds = {};
  final Map<String, String> _playerTeeIds = {}; // playerId -> teeBoxId
  final Map<String, String> _playerTeams = {}; // playerId -> 'a', 'b', 'none'

  int _roundNumber = 1;
  final String _format = 'hybrid';
  int _pointsPerSkin = 2;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final courses = await widget.courseRepository.getAllCourses();
    final players = await widget.playerRepository.getAllPlayers();
    final savedRounds = await widget.roundRepository.getAllSavedRounds();
    _roundNumber = savedRounds.length + 1;

    if (widget.tournamentId != null) {
      final tPlayers = await widget.tournamentRepository
          .getTournamentPlayers(widget.tournamentId!);
      for (final tp in tPlayers) {
        _playerTeams[tp.player.id] = tp.teamId;
      }
    }

    if (courses.isNotEmpty) {
      _selectedCourseId = courses.first.id;
      _selectedCourseDetails =
          await widget.courseRepository.getCourseDetails(courses.first.id);
    }

    _selectedPlayerIds.addAll(players.map((p) => p.id));
    _assignDefaultTees(players, _selectedCourseDetails);

    setState(() {
      _courses = courses;
      _allPlayers = players;
      _isLoading = false;
    });
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
        title: const Text('Round Setup'),
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
                          onChanged: (v) {
                            if (v != null) setState(() => _roundNumber = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _pointsPerSkin,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Points / Skin',
                            labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          items: [1, 2, 3, 5, 10]
                              .map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text('$p pts', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _pointsPerSkin = v);
                          },
                        ),
                      ),
                    ],
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
                                  Text(
                                    player.nickname.isNotEmpty
                                        ? player.nickname
                                        : player.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Index ${player.handicapIndex.toStringAsFixed(1)} • Course HCP $courseHcp',
                                    style: const TextStyle(
                                      color: AppColors.duneSand,
                                      fontSize: 16,
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
            label: const Text('Tee Off / Start Scoring', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ],
      ),
    );
  }
}
