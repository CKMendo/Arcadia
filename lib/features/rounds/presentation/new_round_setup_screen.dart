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

    // Check if tournament has team designations
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
        const SnackBar(content: Text('Please select or configure a course first.')),
      );
      return;
    }
    if (_selectedPlayerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one player.')),
      );
      return;
    }

    final cd = _selectedCourseDetails!;
    final sessionHoles = cd.holes
        .map((h) => HoleSessionInfo(
              holeNumber: h.holeNumber,
              par: h.par,
              strokeIndex: h.strokeIndex,
            ))
        .toList();

    final sessionPlayers = _selectedPlayerIds.map((pId) {
      final p = _allPlayers.firstWhere((item) => item.id == pId);
      final teeId = _playerTeeIds[pId] ?? cd.teeBoxes.first.teeBox.id;
      final teeBox = cd.teeBoxes
          .firstWhere((t) => t.teeBox.id == teeId)
          .teeBox;
      final courseHcp = _computeCourseHcp(p, teeId);

      return PlayerSessionInfo(
        playerId: p.id,
        name: p.fullName,
        nickname: p.nickname,
        initials: p.initials,
        handicapIndex: p.handicapIndex,
        teeBoxId: teeId,
        teeName: teeBox.name,
        courseHandicap: courseHcp,
        teamId: _playerTeams[p.id] ?? 'none',
      );
    }).toList();

    final session = ActiveRoundSession(
      tournamentId: widget.tournamentId,
      courseId: cd.course.id,
      courseName: cd.course.name,
      roundNumber: _roundNumber,
      format: _format,
      pointsPerSkin: _pointsPerSkin,
      holes: sessionHoles,
      players: sessionPlayers,
    );

    // Persist as draft immediately
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COURSE & ROUND',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_courses.isEmpty)
                    const Text(
                      'No courses added yet! Go to the Courses tab to add or template a course.',
                      style: TextStyle(color: Colors.redAccent),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCourseId,
                      decoration: const InputDecoration(
                        labelText: 'Select Course',
                        prefixIcon: Icon(Icons.golf_course, color: AppColors.gold),
                      ),
                      items: _courses.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.name} (${c.holeCount}h)'),
                        );
                      }).toList(),
                      onChanged: _onCourseChanged,
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _roundNumber,
                          decoration: const InputDecoration(labelText: 'Round #'),
                          items: [1, 2, 3, 4, 5]
                              .map((r) => DropdownMenuItem(
                                    value: r,
                                    child: Text('Round $r'),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _roundNumber = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _pointsPerSkin,
                          decoration: const InputDecoration(
                            labelText: 'Points / Skin',
                          ),
                          items: [1, 2, 3, 5, 10]
                              .map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text('$p pts'),
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
          const SizedBox(height: 16),

          // Players & Tees Selection
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PLAYERS & TEES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: AppColors.gold,
                        ),
                      ),
                      Text(
                        '${_selectedPlayerIds.length} Selected',
                        style: const TextStyle(
                          color: AppColors.goldLight,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_allPlayers.isEmpty)
                    const Text(
                      'No players in roster. Add players in the Roster tab.',
                      style: TextStyle(color: Colors.white54),
                    )
                  else
                    ..._allPlayers.map((player) {
                      final isSelected = _selectedPlayerIds.contains(player.id);
                      final teeId = _playerTeeIds[player.id];
                      final courseHcp = _computeCourseHcp(player, teeId ?? '');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0C2B20)
                              : const Color(0xFF061812),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.gold.withValues(alpha: 0.5)
                                : AppColors.cardBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              activeColor: AppColors.gold,
                              checkColor: Colors.black,
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
                            PlayerAvatar(
                              initials: player.initials,
                              photoPath: player.photoPath,
                              radius: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    player.nickname.isNotEmpty
                                        ? player.nickname
                                        : player.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Index: ${player.handicapIndex.toStringAsFixed(1)} • Course HCP: $courseHcp',
                                    style: const TextStyle(
                                      color: AppColors.goldLight,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedCourseDetails != null &&
                                _selectedCourseDetails!.teeBoxes.isNotEmpty)
                              SizedBox(
                                width: 90,
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
                                              style: const TextStyle(fontSize: 13),
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
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startRound,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Tee Off / Start Scoring'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
