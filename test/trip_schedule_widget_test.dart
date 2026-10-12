import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arcadia/database/app_database.dart';
import 'package:arcadia/features/courses/presentation/trip_schedule_tab.dart';
import 'package:arcadia/features/courses/repository/course_repository.dart';
import 'package:arcadia/features/courses/repository/trip_schedule_repository.dart';
import 'package:arcadia/features/players/repository/player_repository.dart';
import 'package:arcadia/features/rounds/repository/round_repository.dart';
import 'package:arcadia/features/courses/models/scheduled_round.dart';

void main() {
  testWidgets('TripScheduleTab displays Round 1 Bootlegger card properly', (tester) async {
    final db = AppDatabase();
    SharedPreferences.setMockInitialValues({
      'trip_scheduled_rounds_json': jsonEncode([
        {
          'id': 'sr1',
          'roundNumber': 1,
          'courseId': 'c_bootlegger',
          'courseName': 'Forest Dunes (The Bootlegger)',
          'date': DateTime(2027, 6, 9, 10, 0).millisecondsSinceEpoch,
          'teeTimeGroup1': '11:00 AM',
          'teeTimeGroup2': '11:11 AM',
          'format': 'Casual Play • Birdie Pot Only (10H)',
          'holeCount': 10,
          'isShortCourse': true,
        },
        {
          'id': 'sr2',
          'roundNumber': 2,
          'courseId': 'c_loop_black',
          'courseName': 'The Loop (Black Course)',
          'date': DateTime(2027, 6, 9, 10, 0).millisecondsSinceEpoch,
          'teeTimeGroup1': '2:06 PM',
          'teeTimeGroup2': '2:17 PM',
          'format': '2-Man Best Ball Net Stableford',
          'holeCount': 18,
          'isShortCourse': false,
        }
      ]),
    });

    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final courseRepo = CourseRepository(db);
    final playerRepo = PlayerRepository(db);
    final scheduleRepo = TripScheduleRepository();
    final roundRepo = RoundRepository(db);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TripScheduleTab(
            courseRepository: courseRepo,
            playerRepository: playerRepo,
            tripScheduleRepository: scheduleRepo,
            roundRepository: roundRepo,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Forest Dunes (The Bootlegger)'), findsOneWidget);
    expect(find.text('The Loop (Black Course)'), findsOneWidget);
    expect(find.text('ROUND 1'), findsOneWidget);
    expect(find.text('ROUND 2'), findsOneWidget);
    print('Both round cards found successfully!');
  });
}
