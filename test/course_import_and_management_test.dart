import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:arcadia/database/app_database.dart';
import 'package:arcadia/features/courses/repository/course_repository.dart';
import 'package:arcadia/features/courses/services/course_import_service.dart';

void main() {
  late AppDatabase db;
  late CourseRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = CourseRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CourseRepository Deletion and Updating Tests', () {
    test('createCourse creates course with holes and tees with yardages', () async {
      final courseId = await repo.createCourse(
        name: 'Test Golf Club',
        city: 'Traverse City',
        state: 'MI',
        holeCount: 18,
        pars: List.filled(18, 4),
        strokeIndexes: List.generate(18, (i) => i + 1),
        tees: [
          const TeeBoxInput(
            name: 'Blue',
            courseRating: 72.0,
            slopeRating: 130,
            totalYardage: 6500,
            holeYardages: {1: 400, 2: 350},
          ),
        ],
      );

      final details = await repo.getCourseDetails(courseId);
      expect(details, isNotNull);
      expect(details!.course.name, equals('Test Golf Club'));
      expect(details.holes.length, equals(18));
      expect(details.teeBoxes.length, equals(1));
      expect(details.teeBoxes.first.holeYardages[1], equals(400));
      expect(details.teeBoxes.first.holeYardages[2], equals(350));
    });

    test('updateCourse updates metadata and replaces holes & tees without duplicating', () async {
      final courseId = await repo.createCourse(
        name: 'Original Name',
        city: 'Detroit',
        state: 'MI',
        holeCount: 18,
        pars: List.filled(18, 4),
        strokeIndexes: List.generate(18, (i) => i + 1),
        tees: [
          const TeeBoxInput(
            name: 'White',
            courseRating: 70.0,
            slopeRating: 120,
            totalYardage: 6000,
          ),
        ],
      );

      // Now update the course
      await repo.updateCourse(
        courseId: courseId,
        name: 'Updated Championship Course',
        city: 'Grand Rapids',
        state: 'MI',
        holeCount: 18,
        pars: [5, 4, 3, 4, 5, 3, 4, 4, 4, 4, 5, 4, 3, 4, 5, 4, 3, 4],
        strokeIndexes: List.generate(18, (i) => 18 - i),
        tees: [
          const TeeBoxInput(
            name: 'Black',
            courseRating: 74.5,
            slopeRating: 140,
            totalYardage: 7100,
            holeYardages: {1: 520, 2: 410},
          ),
          const TeeBoxInput(
            name: 'Blue',
            courseRating: 72.0,
            slopeRating: 130,
            totalYardage: 6600,
          ),
        ],
      );

      final allCourses = await repo.getAllCourses();
      expect(allCourses.length, equals(1)); // Still only 1 course! No duplicate created!
      expect(allCourses.first.name, equals('Updated Championship Course'));
      expect(allCourses.first.city, equals('Grand Rapids'));

      final details = await repo.getCourseDetails(courseId);
      expect(details!.holes.first.par, equals(5));
      expect(details.teeBoxes.length, equals(2));
      expect(details.teeBoxes.first.teeBox.name, equals('Black'));
      expect(details.teeBoxes.first.holeYardages[1], equals(520));
    });

    test('deleteCourse transactionally cleans up course, holes, tee boxes, and yardages', () async {
      final courseId = await repo.createCourse(
        name: 'Course To Delete',
        city: 'Cadillac',
        state: 'MI',
        holeCount: 18,
        pars: List.filled(18, 4),
        strokeIndexes: List.generate(18, (i) => i + 1),
        tees: [
          const TeeBoxInput(
            name: 'Gold',
            courseRating: 68.0,
            slopeRating: 115,
            totalYardage: 5500,
            holeYardages: {1: 350, 2: 320},
          ),
        ],
      );

      // Verify created
      final before = await repo.getAllCourses();
      expect(before.length, equals(1));

      // Delete course
      await repo.deleteCourse(courseId);

      // Verify course is gone
      final after = await repo.getAllCourses();
      expect(after.isEmpty, isTrue);

      final details = await repo.getCourseDetails(courseId);
      expect(details, isNull);

      // Verify no orphaned records in database
      final remainingHoles = await db.select(db.courseHoles).get();
      expect(remainingHoles.isEmpty, isTrue);

      final remainingTees = await db.select(db.teeBoxes).get();
      expect(remainingTees.isEmpty, isTrue);

      final remainingYardages = await db.select(db.holeYardages).get();
      expect(remainingYardages.isEmpty, isTrue);
    });
  });

  group('CourseImportService Tests', () {
    test('parseJson correctly extracts course, hole pars, stroke indexes, and tee yardages', () {
      final jsonStr = '''
      {
        "name": "Custom Dunes Course",
        "city": "Manistee",
        "state": "MI",
        "holeCount": 18,
        "holes": [
          {"holeNumber": 1, "par": 5, "strokeIndex": 3},
          {"holeNumber": 2, "par": 4, "strokeIndex": 11},
          {"holeNumber": 3, "par": 3, "strokeIndex": 17}
        ],
        "tees": [
          {
            "name": "Championship",
            "courseRating": 74.2,
            "slopeRating": 141,
            "yardages": {
              "1": 535,
              "2": 420,
              "3": 185
            }
          }
        ]
      }
      ''';

      final imported = CourseImportService.parseJson(jsonStr);
      expect(imported.name, equals('Custom Dunes Course'));
      expect(imported.city, equals('Manistee'));
      expect(imported.state, equals('MI'));
      expect(imported.holeCount, equals(18));
      expect(imported.pars[0], equals(5));
      expect(imported.pars[1], equals(4));
      expect(imported.pars[2], equals(3));
      expect(imported.strokeIndexes[0], equals(3));
      expect(imported.strokeIndexes[1], equals(11));
      expect(imported.strokeIndexes[2], equals(17));

      expect(imported.tees.length, equals(1));
      expect(imported.tees.first.name, equals('Championship'));
      expect(imported.tees.first.courseRating, equals(74.2));
      expect(imported.tees.first.slopeRating, equals(141));
      expect(imported.tees.first.holeYardages![1], equals(535));
      expect(imported.tees.first.holeYardages![2], equals(420));
      expect(imported.tees.first.holeYardages![3], equals(185));
      expect(imported.tees.first.totalYardage, equals(1140));
    });

    test('parseScorecardText parses standard scorecard CSV lines with holes, pars, HCP and tee distances', () {
      const csvStr = '''
Course: Bear Lake Golf Club
City: Bear Lake
State: MI
Hole,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18
Par,4,4,3,5,4,4,3,4,5,4,3,5,4,4,3,4,4,5
HCP,7,1,15,9,13,3,17,5,11,8,18,6,2,12,16,4,14,10
Blue (72.5/133),410,390,175,520,380,415,160,395,510,405,170,530,425,390,165,400,385,525
White (70.1/126),385,365,155,490,355,390,140,370,480,380,150,500,395,365,145,375,360,495
''';

      final imported = CourseImportService.parseScorecardText(csvStr);
      expect(imported.name, equals('Bear Lake Golf Club'));
      expect(imported.city, equals('Bear Lake'));
      expect(imported.state, equals('MI'));
      expect(imported.holeCount, equals(18));
      expect(imported.pars[0], equals(4));
      expect(imported.pars[2], equals(3));
      expect(imported.pars[3], equals(5));
      expect(imported.strokeIndexes[0], equals(7));
      expect(imported.strokeIndexes[1], equals(1));

      expect(imported.tees.length, equals(2));
      final blue = imported.tees[0];
      expect(blue.name, equals('Blue'));
      expect(blue.courseRating, equals(72.5));
      expect(blue.slopeRating, equals(133));
      expect(blue.holeYardages![1], equals(410));
      expect(blue.holeYardages![2], equals(390));
      expect(blue.holeYardages![3], equals(175));

      final white = imported.tees[1];
      expect(white.name, equals('White'));
      expect(white.courseRating, equals(70.1));
      expect(white.slopeRating, equals(126));
      expect(white.holeYardages![1], equals(385));
    });

    test('getBuiltInPresets provides Arcadia Bluffs with complete hole distances', () {
      final presets = CourseImportService.getBuiltInPresets();
      expect(presets.length, greaterThanOrEqualTo(2));

      final bluffs = presets.firstWhere((p) => p.name.contains('The Bluffs'));
      expect(bluffs.holeCount, equals(18));
      expect(bluffs.tees.length, equals(4));
      final blackTee = bluffs.tees.firstWhere((t) => t.name == 'Black');
      expect(blackTee.totalYardage, equals(7300));
      expect(blackTee.holeYardages!.length, equals(18));
      expect(blackTee.holeYardages![1], equals(519)); // Hole 1 par 5 distance
      expect(blackTee.holeYardages![11], equals(633)); // Hole 11 par 5 distance
    });
  });
}
