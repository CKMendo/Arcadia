import 'package:flutter/material.dart';
import '../../database/app_database.dart';
import '../features/courses/repository/course_repository.dart';
import '../features/players/presentation/players_screen.dart';
import '../features/players/repository/player_repository.dart';
import '../features/courses/presentation/courses_screen.dart';
import '../features/rounds/presentation/active_scoring_screen.dart';
import '../features/rounds/presentation/new_round_setup_screen.dart';
import '../features/rounds/repository/round_repository.dart';
import '../features/rules/presentation/rules_screen.dart';
import '../features/standings/presentation/standings_screen.dart';
import '../features/tournaments/repository/tournament_repository.dart';
import '../features/trip/presentation/trip_overview_screen.dart';

class ArcadiaShell extends StatefulWidget {
  final AppDatabase database;
  final PlayerRepository playerRepository;
  final CourseRepository courseRepository;
  final TournamentRepository tournamentRepository;
  final RoundRepository roundRepository;

  const ArcadiaShell({
    super.key,
    required this.database,
    required this.playerRepository,
    required this.courseRepository,
    required this.tournamentRepository,
    required this.roundRepository,
  });

  @override
  State<ArcadiaShell> createState() => _ArcadiaShellState();
}

class _ArcadiaShellState extends State<ArcadiaShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      TripOverviewScreen(
        tournamentRepository: widget.tournamentRepository,
        courseRepository: widget.courseRepository,
        playerRepository: widget.playerRepository,
        roundRepository: widget.roundRepository,
      ),
      _ScoringTab(
        courseRepository: widget.courseRepository,
        playerRepository: widget.playerRepository,
        tournamentRepository: widget.tournamentRepository,
        roundRepository: widget.roundRepository,
      ),
      StandingsScreen(
        roundRepository: widget.roundRepository,
        playerRepository: widget.playerRepository,
        tournamentRepository: widget.tournamentRepository,
      ),
      CoursesScreen(courseRepository: widget.courseRepository),
      PlayersScreen(playerRepository: widget.playerRepository),
      const RulesScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        selectedFontSize: 13,
        unselectedFontSize: 11,
        iconSize: 26,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.flag_outlined),
            activeIcon: Icon(Icons.flag),
            label: 'Trip',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_golf_outlined),
            activeIcon: Icon(Icons.sports_golf),
            label: 'Scoring',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard_outlined),
            activeIcon: Icon(Icons.leaderboard),
            label: 'Standings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.golf_course_outlined),
            activeIcon: Icon(Icons.golf_course),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Roster',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Rules',
          ),
        ],
      ),
    );
  }
}

class _ScoringTab extends StatelessWidget {
  final CourseRepository courseRepository;
  final PlayerRepository playerRepository;
  final TournamentRepository tournamentRepository;
  final RoundRepository roundRepository;

  const _ScoringTab({
    required this.courseRepository,
    required this.playerRepository,
    required this.tournamentRepository,
    required this.roundRepository,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: roundRepository.watchActiveDraft(),
      builder: (context, snapshot) {
        final draft = snapshot.data;
        if (draft != null) {
          return ActiveScoringScreen(
            roundRepository: roundRepository,
            session: draft,
          );
        }

        return NewRoundSetupScreen(
          courseRepository: courseRepository,
          playerRepository: playerRepository,
          tournamentRepository: tournamentRepository,
          roundRepository: roundRepository,
        );
      },
    );
  }
}
