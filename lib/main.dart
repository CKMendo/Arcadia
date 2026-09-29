import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database/app_database.dart';
import 'features/courses/repository/course_repository.dart';
import 'features/players/repository/player_repository.dart';
import 'features/publish/services/website_publish_service.dart';
import 'features/rounds/repository/round_repository.dart';
import 'features/tournaments/repository/tournament_repository.dart';
import 'presentation/splash_screen.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dark navigation bar and status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0C1622),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final database = AppDatabase();
  final playerRepository = PlayerRepository(database);
  await playerRepository.ensureRosterPreserved();
  final courseRepository = CourseRepository(database);
  final tournamentRepository = TournamentRepository(database);
  final roundRepository = RoundRepository(database);

  roundRepository.onDataChanged = () {
    WebsitePublishService.publishTournament(
      tournamentRepo: tournamentRepository,
      courseRepo: courseRepository,
      playerRepo: playerRepository,
      roundRepo: roundRepository,
    );
  };

  // Initial push to ensure website has latest data
  WebsitePublishService.publishTournament(
    tournamentRepo: tournamentRepository,
    courseRepo: courseRepository,
    playerRepo: playerRepository,
    roundRepo: roundRepository,
  );

  runApp(
    ArcadiaApp(
      database: database,
      playerRepository: playerRepository,
      courseRepository: courseRepository,
      tournamentRepository: tournamentRepository,
      roundRepository: roundRepository,
    ),
  );
}

class ArcadiaApp extends StatelessWidget {
  final AppDatabase database;
  final PlayerRepository playerRepository;
  final CourseRepository courseRepository;
  final TournamentRepository tournamentRepository;
  final RoundRepository roundRepository;

  const ArcadiaApp({
    super.key,
    required this.database,
    required this.playerRepository,
    required this.courseRepository,
    required this.tournamentRepository,
    required this.roundRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arcadia Golf Trip',
      debugShowCheckedModeBanner: false,
      theme: buildArcadiaTheme(),
      home: ArcadiaSplashScreen(
        database: database,
        playerRepository: playerRepository,
        courseRepository: courseRepository,
        tournamentRepository: tournamentRepository,
        roundRepository: roundRepository,
      ),
    );
  }
}
