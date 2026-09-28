import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:arcadia/database/app_database.dart';
import 'package:arcadia/shared/utils/course_handicap_calculator.dart';
import 'package:arcadia/shared/utils/player_initials_helper.dart';
import 'package:arcadia/features/courses/repository/course_repository.dart';
import 'package:arcadia/features/tournaments/repository/tournament_repository.dart';
import 'package:arcadia/features/rounds/models/active_round_session.dart';
import 'package:arcadia/features/rounds/repository/round_repository.dart';

void main() {
  group('PlayerInitialsHelper Tests', () {
    test('computes initials correctly from first and last name', () {
      expect(PlayerInitialsHelper.compute('Neal Patel'), 'NP');
      expect(PlayerInitialsHelper.compute('Vilmer Villaverde'), 'VV');
      expect(PlayerInitialsHelper.compute('Chet Mehta'), 'CM');
      expect(PlayerInitialsHelper.compute('Chirag Patel'), 'CP');
      expect(PlayerInitialsHelper.compute('Ramesh Patel'), 'RP');
      expect(PlayerInitialsHelper.compute('Raj Patel'), 'RP');
      expect(PlayerInitialsHelper.compute('Sanjay Patel'), 'SP');
      expect(PlayerInitialsHelper.compute('Mahendra Patel'), 'MP');
      expect(PlayerInitialsHelper.compute('Tiger Woods'), 'TW');
      expect(PlayerInitialsHelper.compute('  Jack   Nicklaus  '), 'JN');
      expect(PlayerInitialsHelper.compute('Madonna'), 'MA');
      expect(PlayerInitialsHelper.compute(''), '?');
    });
  });

  group('CourseHandicapCalculator Tests', () {
    test('calculates Course Handicap for The Bluffs', () {
      // 8.7 Index on White Tee: 8.7 * (133 / 113) + (70.8 - 72) = 10.24 - 1.2 = 9.04 -> 9
      final chWhite = CourseHandicapCalculator.forBluffs(8.7, 'White');
      expect(chWhite, 9);

      // Black Tee (Slope 147, Rating 75.4, Par 72):
      // 8.7 * (147 / 113) + (75.4 - 72) = 11.317 + 3.4 = 14.717 -> 15
      final chBlack = CourseHandicapCalculator.forBluffs(8.7, 'Black');
      expect(chBlack, 15);

      // Blue Tee (Slope 138, Rating 73.1, Par 72):
      // 8.7 * (138 / 113) + (73.1 - 72) = 10.624 + 1.1 = 11.724 -> 12
      final chBlue = CourseHandicapCalculator.forBluffs(8.7, 'Blue');
      expect(chBlue, 12);
    });

    test('calculates Course Handicap for The South Course', () {
      // 8.7 Index on White Tee: 8.7 * (129 / 113) + (71.0 - 72) = 9.931 - 1.0 = 8.931 -> 9
      final chWhite = CourseHandicapCalculator.forSouth(8.7, 'White');
      expect(chWhite, 9);

      // Black Tee (Slope 141, Rating 75.9, Par 72):
      // 8.7 * (141 / 113) + (75.9 - 72) = 10.855 + 3.9 = 14.755 -> 15
      final chBlack = CourseHandicapCalculator.forSouth(8.7, 'Black');
      expect(chBlack, 15);
    });
  });

  group('Round Lifecycle & ActiveRoundSession Tests', () {
    late AppDatabase db;
    late CourseRepository courseRepo;
    late TournamentRepository tournamentRepo;
    late RoundRepository roundRepo;
    late String tournamentId;
    late String courseId;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      courseRepo = CourseRepository(db);
      tournamentRepo = TournamentRepository(db);
      roundRepo = RoundRepository(db);

      await courseRepo.seedArcadiaBluffsTemplates();
      final courses = await courseRepo.getAllCourses();
      courseId = courses.first.id;

      tournamentId = await tournamentRepo.createTournament(
        name: 'Arcadia Coastal Cup 2027',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 3)),
        formatType: 'hybrid',
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('ActiveRoundSession allows updating player tee and recalculating Course HC', () {
      final session = ActiveRoundSession(
        tournamentId: tournamentId,
        courseId: courseId,
        courseName: 'Arcadia Bluffs',
        roundNumber: 1,
        datePlayed: DateTime.now(),
        format: '2-Man Stableford',
        players: [
          const PlayerSessionInfo(
            playerId: 'p1',
            name: 'Neal Patel',
            nickname: 'Neal',
            initials: 'NP',
            handicapIndex: 8.7,
            courseHandicap: 9,
            teeBoxId: 'white',
            teeName: 'White',
            teamId: 'team_a',
          ),
        ],
        holes: List.generate(
          18,
          (i) => HoleSessionInfo(
            holeNumber: i + 1,
            par: 4,
            strokeIndex: i + 1,
            yardage: 400,
          ),
        ),
      );

      expect(session.players.first.courseHandicap, 9);
      expect(session.players.first.teeName, 'White');

      final calculatedCh = CourseHandicapCalculator.forBluffs(8.7, 'Black');
      session.updatePlayerTeeAndHandicap(
        playerId: 'p1',
        teeName: 'Black',
        handicapIndex: 8.7,
        newCourseHandicap: calculatedCh,
      );

      expect(session.players.first.teeName, 'Black');
      expect(session.players.first.courseHandicap, 15);
    });

    test('Finalizing round saves to savedRounds, clearing draft', () async {
      final session = ActiveRoundSession(
        tournamentId: tournamentId,
        courseId: courseId,
        courseName: 'The South Course',
        roundNumber: 2,
        datePlayed: DateTime.now(),
        format: '2-Man Stableford',
        players: [
          const PlayerSessionInfo(
            playerId: 'p1',
            name: 'Vilmer Villaverde',
            nickname: 'Vilmer',
            initials: 'VV',
            handicapIndex: 12.0,
            courseHandicap: 14,
            teeBoxId: 'white',
            teeName: 'White',
            teamId: 'team_b',
          ),
        ],
        holes: List.generate(
          18,
          (i) => HoleSessionInfo(
            holeNumber: i + 1,
            par: 4,
            strokeIndex: i + 1,
            yardage: 380,
          ),
        ),
      );

      // Save draft first
      await roundRepo.saveActiveDraft(session);
      var draft = await roundRepo.getActiveDraft();
      expect(draft, isNotNull);

      // Finalize round
      final roundId = await roundRepo.saveCompletedRound(session);
      expect(roundId, isNotEmpty);

      // Draft is cleared
      draft = await roundRepo.getActiveDraft();
      expect(draft, isNull);

      // Saved rounds contains finalized round
      final saved = await roundRepo.getAllSavedRounds();
      expect(saved.length, 1);
      expect(saved.first.id, roundId);
      expect(saved.first.courseName, 'The South Course');

      // Unlock finalized round to edit
      final unlockedSession = await roundRepo.unlockSavedRound(roundId);
      expect(unlockedSession, isNotNull);
      expect(unlockedSession!.savedRoundId, roundId);

      // Editing unlocked round and re-saving updates existing record
      final newCh = CourseHandicapCalculator.forSouth(10.0, 'Blue');
      unlockedSession.updatePlayerTeeAndHandicap(
        playerId: 'p1',
        teeName: 'Blue',
        handicapIndex: 10.0,
        newCourseHandicap: newCh,
      );
      final updatedId = await roundRepo.saveCompletedRound(unlockedSession);
      expect(updatedId, roundId);

      final reSaved = await roundRepo.getAllSavedRounds();
      expect(reSaved.length, 1);
    });
  });
}
