import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../database/app_database.dart';
import '../models/course_models.dart';

class CourseRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  CourseRepository(this._db);

  Stream<List<Course>> watchAllCourses() {
    return (_db.select(_db.courses)
          ..orderBy([
            (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  Future<List<Course>> getAllCourses() {
    return (_db.select(_db.courses)
          ..orderBy([
            (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)
          ]))
        .get();
  }

  Future<CourseDetails?> getCourseDetails(String courseId) async {
    final course = await (_db.select(_db.courses)..where((t) => t.id.equals(courseId)))
        .getSingleOrNull();
    if (course == null) return null;

    final holes = await (_db.select(_db.courseHoles)
          ..where((t) => t.courseId.equals(courseId))
          ..orderBy([(t) => OrderingTerm(expression: t.holeNumber)]))
        .get();

    final teeBoxes = await (_db.select(_db.teeBoxes)
          ..where((t) => t.courseId.equals(courseId)))
        .get();

    final teeBoxesWithYardages = <TeeBoxWithYardages>[];
    for (final tee in teeBoxes) {
      final yardages = await (_db.select(_db.holeYardages)
            ..where((t) => t.teeBoxId.equals(tee.id)))
          .get();

      final yardageMap = <int, int>{};
      for (final y in yardages) {
        final hole = holes.where((h) => h.id == y.courseHoleId).firstOrNull;
        if (hole != null) {
          yardageMap[hole.holeNumber] = y.yardage;
        }
      }
      teeBoxesWithYardages.add(
        TeeBoxWithYardages(teeBox: tee, holeYardages: yardageMap),
      );
    }

    return CourseDetails(
      course: course,
      holes: holes,
      teeBoxes: teeBoxesWithYardages,
    );
  }

  Future<String> createCourse({
    required String name,
    required String city,
    required String state,
    int holeCount = 18,
    required List<int> pars,
    required List<int> strokeIndexes,
    required List<TeeBoxInput> tees,
  }) async {
    final courseId = _uuid.v4();

    await _db.transaction(() async {
      await _db.into(_db.courses).insert(
            CoursesCompanion(
              id: Value(courseId),
              name: Value(name.trim()),
              city: Value(city.trim()),
              state: Value(state.trim()),
              holeCount: Value(holeCount),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

      // Insert holes
      final holeIds = <int, String>{};
      for (var i = 1; i <= holeCount; i++) {
        final holeId = '${courseId}_h$i';
        holeIds[i] = holeId;
        final par = (i - 1 < pars.length) ? pars[i - 1] : 4;
        final strokeIndex = (i - 1 < strokeIndexes.length) ? strokeIndexes[i - 1] : i;

        await _db.into(_db.courseHoles).insert(
              CourseHolesCompanion(
                id: Value(holeId),
                courseId: Value(courseId),
                holeNumber: Value(i),
                par: Value(par),
                strokeIndex: Value(strokeIndex),
              ),
            );
      }

      // Insert tees
      for (final tee in tees) {
        final teeId = _uuid.v4();
        await _db.into(_db.teeBoxes).insert(
              TeeBoxesCompanion(
                id: Value(teeId),
                courseId: Value(courseId),
                name: Value(tee.name),
                colorHex: Value(tee.colorHex),
                courseRating: Value(tee.courseRating),
                slopeRating: Value(tee.slopeRating),
                totalYardage: Value(tee.totalYardage),
              ),
            );

        if (tee.holeYardages != null) {
          for (final entry in tee.holeYardages!.entries) {
            final hId = holeIds[entry.key];
            if (hId != null) {
              await _db.into(_db.holeYardages).insert(
                    HoleYardagesCompanion(
                      teeBoxId: Value(teeId),
                      courseHoleId: Value(hId),
                      yardage: Value(entry.value),
                    ),
                  );
            }
          }
        }
      }
    });

    return courseId;
  }

  Future<void> deleteCourse(String courseId) async {
    await (_db.delete(_db.courses)..where((t) => t.id.equals(courseId))).go();
  }

  Future<void> seedArcadiaBluffsTemplates() async {
    final existing = await getAllCourses();
    if (existing.any((c) => c.name.toLowerCase().contains('arcadia bluffs'))) return;

    // The Bluffs Course
    await createCourse(
      name: 'Arcadia Bluffs (The Bluffs)',
      city: 'Arcadia',
      state: 'MI',
      holeCount: 18,
      pars: [5, 4, 3, 4, 5, 3, 4, 4, 4, 4, 5, 4, 3, 4, 5, 4, 3, 4],
      strokeIndexes: [5, 9, 17, 13, 1, 15, 3, 7, 11, 8, 2, 6, 18, 10, 4, 14, 16, 12],
      tees: [
        const TeeBoxInput(
          name: 'Black',
          colorHex: '#1A1A1A',
          courseRating: 75.4,
          slopeRating: 147,
          totalYardage: 7300,
        ),
        const TeeBoxInput(
          name: 'Blue',
          colorHex: '#2563EB',
          courseRating: 73.1,
          slopeRating: 138,
          totalYardage: 6800,
        ),
        const TeeBoxInput(
          name: 'White',
          colorHex: '#E2E8F0',
          courseRating: 70.8,
          slopeRating: 133,
          totalYardage: 6300,
        ),
        const TeeBoxInput(
          name: 'Gold',
          colorHex: '#EAB308',
          courseRating: 67.9,
          slopeRating: 122,
          totalYardage: 5700,
        ),
      ],
    );

    // The South Course
    await createCourse(
      name: 'Arcadia Bluffs (The South)',
      city: 'Arcadia',
      state: 'MI',
      holeCount: 18,
      pars: [4, 4, 4, 5, 3, 4, 3, 5, 4, 4, 3, 4, 5, 4, 3, 5, 4, 4],
      strokeIndexes: [11, 7, 1, 9, 17, 3, 15, 5, 13, 8, 18, 4, 2, 10, 16, 6, 12, 14],
      tees: [
        const TeeBoxInput(
          name: 'Black',
          colorHex: '#1A1A1A',
          courseRating: 75.9,
          slopeRating: 141,
          totalYardage: 7412,
        ),
        const TeeBoxInput(
          name: 'Blue',
          colorHex: '#2563EB',
          courseRating: 73.5,
          slopeRating: 135,
          totalYardage: 6848,
        ),
        const TeeBoxInput(
          name: 'White',
          colorHex: '#E2E8F0',
          courseRating: 71.0,
          slopeRating: 129,
          totalYardage: 6328,
        ),
        const TeeBoxInput(
          name: 'Gold',
          colorHex: '#EAB308',
          courseRating: 68.2,
          slopeRating: 123,
          totalYardage: 5815,
        ),
      ],
    );
  }
}

class TeeBoxInput {
  final String name;
  final String? colorHex;
  final double courseRating;
  final int slopeRating;
  final int totalYardage;
  final Map<int, int>? holeYardages;

  const TeeBoxInput({
    required this.name,
    this.colorHex,
    required this.courseRating,
    required this.slopeRating,
    required this.totalYardage,
    this.holeYardages,
  });
}
