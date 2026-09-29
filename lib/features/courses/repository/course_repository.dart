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

  Future<void> updateCourse({
    required String courseId,
    required String name,
    required String city,
    required String state,
    int holeCount = 18,
    required List<int> pars,
    required List<int> strokeIndexes,
    required List<TeeBoxInput> tees,
  }) async {
    await _db.transaction(() async {
      // 1. Update course core row
      await (_db.update(_db.courses)..where((t) => t.id.equals(courseId))).write(
        CoursesCompanion(
          name: Value(name.trim()),
          city: Value(city.trim()),
          state: Value(state.trim()),
          holeCount: Value(holeCount),
        ),
      );

      // 2. Remove old child records cleanly
      final oldTees = await (_db.select(_db.teeBoxes)..where((t) => t.courseId.equals(courseId))).get();
      for (final tee in oldTees) {
        await (_db.delete(_db.holeYardages)..where((t) => t.teeBoxId.equals(tee.id))).go();
      }
      await (_db.delete(_db.teeBoxes)..where((t) => t.courseId.equals(courseId))).go();
      await (_db.delete(_db.courseHoles)..where((t) => t.courseId.equals(courseId))).go();

      // 3. Re-insert updated holes
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

      // 4. Re-insert updated tees and yardages
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
  }

  Future<void> deleteCourse(String courseId) async {
    await _db.transaction(() async {
      // Transactional cleanup of child records to guarantee cascade on all platforms
      final tees = await (_db.select(_db.teeBoxes)..where((t) => t.courseId.equals(courseId))).get();
      for (final tee in tees) {
        await (_db.delete(_db.holeYardages)..where((t) => t.teeBoxId.equals(tee.id))).go();
      }
      await (_db.delete(_db.teeBoxes)..where((t) => t.courseId.equals(courseId))).go();
      await (_db.delete(_db.courseHoles)..where((t) => t.courseId.equals(courseId))).go();
      await (_db.delete(_db.courses)..where((t) => t.id.equals(courseId))).go();
    });
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
      pars: [5, 3, 5, 4, 5, 3, 4, 4, 3, 4, 5, 4, 3, 4, 5, 4, 3, 4],
      strokeIndexes: [5, 9, 17, 13, 1, 15, 3, 7, 11, 8, 2, 6, 18, 10, 4, 14, 16, 12],
      tees: [
        const TeeBoxInput(
          name: 'Black',
          colorHex: '#1A1A1A',
          courseRating: 75.4,
          slopeRating: 147,
          totalYardage: 7300,
          holeYardages: {
            1: 519, 2: 189, 3: 530, 4: 415, 5: 583, 6: 195, 7: 472, 8: 449, 9: 203,
            10: 481, 11: 633, 12: 431, 13: 190, 14: 340, 15: 519, 16: 486, 17: 176, 18: 439,
          },
        ),
        const TeeBoxInput(
          name: 'Blue',
          colorHex: '#2563EB',
          courseRating: 73.1,
          slopeRating: 138,
          totalYardage: 6913,
          holeYardages: {
            1: 490, 2: 175, 3: 505, 4: 390, 5: 555, 6: 180, 7: 445, 8: 420, 9: 185,
            10: 455, 11: 605, 12: 405, 13: 170, 14: 320, 15: 490, 16: 460, 17: 160, 18: 410,
          },
        ),
        const TeeBoxInput(
          name: 'White',
          colorHex: '#E2E8F0',
          courseRating: 70.8,
          slopeRating: 133,
          totalYardage: 6389,
          holeYardages: {
            1: 460, 2: 155, 3: 475, 4: 365, 5: 525, 6: 160, 7: 415, 8: 390, 9: 165,
            10: 425, 11: 575, 12: 375, 13: 150, 14: 300, 15: 460, 16: 430, 17: 140, 18: 380,
          },
        ),
        const TeeBoxInput(
          name: 'Gold',
          colorHex: '#EAB308',
          courseRating: 67.9,
          slopeRating: 122,
          totalYardage: 5700,
          holeYardages: {
            1: 420, 2: 135, 3: 435, 4: 335, 5: 485, 6: 140, 7: 375, 8: 350, 9: 145,
            10: 385, 11: 535, 12: 335, 13: 130, 14: 270, 15: 420, 16: 390, 17: 120, 18: 340,
          },
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
          holeYardages: {
            1: 460, 2: 445, 3: 485, 4: 575, 5: 220, 6: 450, 7: 210, 8: 595, 9: 465,
            10: 440, 11: 195, 12: 460, 13: 580, 14: 435, 15: 215, 16: 605, 17: 420, 18: 480,
          },
        ),
        const TeeBoxInput(
          name: 'Blue',
          colorHex: '#2563EB',
          courseRating: 73.5,
          slopeRating: 135,
          totalYardage: 6848,
          holeYardages: {
            1: 425, 2: 410, 3: 450, 4: 535, 5: 195, 6: 415, 7: 185, 8: 555, 9: 430,
            10: 405, 11: 175, 12: 425, 13: 540, 14: 400, 15: 190, 16: 565, 17: 385, 18: 445,
          },
        ),
        const TeeBoxInput(
          name: 'White',
          colorHex: '#E2E8F0',
          courseRating: 71.0,
          slopeRating: 129,
          totalYardage: 6328,
          holeYardages: {
            1: 395, 2: 380, 3: 415, 4: 495, 5: 175, 6: 380, 7: 165, 8: 515, 9: 395,
            10: 375, 11: 155, 12: 390, 13: 500, 14: 370, 15: 170, 16: 525, 17: 355, 18: 410,
          },
        ),
        const TeeBoxInput(
          name: 'Gold',
          colorHex: '#EAB308',
          courseRating: 68.2,
          slopeRating: 123,
          totalYardage: 5815,
          holeYardages: {
            1: 360, 2: 345, 3: 380, 4: 455, 5: 150, 6: 350, 7: 140, 8: 475, 9: 360,
            10: 340, 11: 135, 12: 355, 13: 460, 14: 335, 15: 145, 16: 485, 17: 320, 18: 375,
          },
        ),
      ],
    );

    // Course 3: The Dozen (12-Hole Course, opened 2025)
    await createCourse(
      name: 'Arcadia Bluffs (The Dozen)',
      city: 'Arcadia',
      state: 'MI',
      holeCount: 12,
      pars: [4, 3, 4, 3, 4, 3, 3, 4, 3, 4, 3, 4],
      strokeIndexes: [1, 7, 3, 9, 5, 11, 8, 2, 10, 4, 12, 6],
      tees: [
        const TeeBoxInput(
          name: 'Black',
          colorHex: '#1A1A1A',
          courseRating: 62.0,
          slopeRating: 110,
          totalYardage: 3063,
          holeYardages: {
            1: 290, 2: 175, 3: 310, 4: 165, 5: 335, 6: 180,
            7: 168, 8: 345, 9: 155, 10: 360, 11: 170, 12: 410,
          },
        ),
        const TeeBoxInput(
          name: 'White',
          colorHex: '#E2E8F0',
          courseRating: 59.5,
          slopeRating: 104,
          totalYardage: 2810,
          holeYardages: {
            1: 270, 2: 160, 3: 285, 4: 150, 5: 305, 6: 165,
            7: 163, 8: 315, 9: 140, 10: 330, 11: 155, 12: 372,
          },
        ),
        const TeeBoxInput(
          name: 'Gold',
          colorHex: '#EAB308',
          courseRating: 57.0,
          slopeRating: 98,
          totalYardage: 2540,
          holeYardages: {
            1: 250, 2: 145, 3: 260, 4: 135, 5: 275, 6: 150,
            7: 137, 8: 285, 9: 125, 10: 300, 11: 140, 12: 338,
          },
        ),
        const TeeBoxInput(
          name: 'Red',
          colorHex: '#EF4444',
          courseRating: 55.0,
          slopeRating: 92,
          totalYardage: 2180,
          holeYardages: {
            1: 230, 2: 125, 3: 220, 4: 115, 5: 235, 6: 130,
            7: 85, 8: 245, 9: 105, 10: 260, 11: 120, 12: 310,
          },
        ),
      ],
    );
  }

  /// Seeds all 4 Forest Dunes courses:
  /// 1. Forest Dunes (Original Course)
  /// 2. The Loop (Black Course - Clockwise)
  /// 3. The Loop (Red Course - Counter-Clockwise)
  /// 4. The Bootlegger (Short Course)
  Future<void> seedForestDunesTemplates() async {
    final existing = await getAllCourses();

    // 1. Forest Dunes (Original Course)
    if (!existing.any((c) => c.name.toLowerCase() == 'forest dunes (original)')) {
      await createCourse(
        name: 'Forest Dunes (Original)',
        city: 'Roscommon',
        state: 'MI',
        holeCount: 18,
        pars: [4, 4, 4, 4, 4, 3, 4, 5, 3, 4, 3, 4, 4, 4, 5, 3, 5, 4],
        strokeIndexes: [9, 5, 13, 1, 11, 15, 7, 3, 17, 8, 18, 4, 14, 6, 12, 16, 2, 10],
        tees: [
          const TeeBoxInput(
            name: 'Dunes',
            colorHex: '#1A1A1A',
            courseRating: 75.2,
            slopeRating: 146,
            totalYardage: 7104,
            holeYardages: {
              1: 412, 2: 440, 3: 388, 4: 464, 5: 435, 6: 215, 7: 422, 8: 554, 9: 165,
              10: 442, 11: 178, 12: 430, 13: 395, 14: 420, 15: 540, 16: 180, 17: 575, 18: 450,
            },
          ),
          const TeeBoxInput(
            name: 'Forest',
            colorHex: '#2563EB',
            courseRating: 72.8,
            slopeRating: 139,
            totalYardage: 6547,
            holeYardages: {
              1: 380, 2: 410, 3: 355, 4: 425, 5: 400, 6: 190, 7: 390, 8: 520, 9: 145,
              10: 410, 11: 155, 12: 395, 13: 360, 14: 385, 15: 505, 16: 160, 17: 540, 18: 418,
            },
          ),
          const TeeBoxInput(
            name: 'Lake',
            colorHex: '#E2E8F0',
            courseRating: 69.9,
            slopeRating: 130,
            totalYardage: 5910,
            holeYardages: {
              1: 345, 2: 375, 3: 320, 4: 385, 5: 360, 6: 165, 7: 350, 8: 480, 9: 125,
              10: 370, 11: 135, 12: 355, 13: 325, 14: 345, 15: 465, 16: 140, 17: 495, 18: 375,
            },
          ),
        ],
      );
    }

    // 2. The Loop (Black Course - Clockwise)
    if (!existing.any((c) => c.name.toLowerCase().contains('the loop (black)'))) {
      await createCourse(
        name: 'Forest Dunes (The Loop - Black)',
        city: 'Roscommon',
        state: 'MI',
        holeCount: 18,
        pars: [4, 4, 3, 4, 5, 4, 3, 4, 4, 4, 3, 5, 4, 3, 4, 5, 3, 4],
        strokeIndexes: [5, 11, 17, 3, 1, 9, 15, 7, 13, 6, 18, 2, 8, 16, 10, 4, 14, 12],
        tees: [
          const TeeBoxInput(
            name: 'Back',
            colorHex: '#1A1A1A',
            courseRating: 73.1,
            slopeRating: 134,
            totalYardage: 6704,
            holeYardages: {
              1: 410, 2: 442, 3: 165, 4: 425, 5: 535, 6: 395, 7: 178, 8: 430, 9: 412,
              10: 388, 11: 215, 12: 554, 13: 422, 14: 180, 15: 420, 16: 575, 17: 190, 18: 464,
            },
          ),
          const TeeBoxInput(
            name: 'Middle',
            colorHex: '#2563EB',
            courseRating: 70.3,
            slopeRating: 128,
            totalYardage: 6078,
            holeYardages: {
              1: 375, 2: 405, 3: 145, 4: 385, 5: 490, 6: 360, 7: 155, 8: 395, 9: 370,
              10: 350, 11: 190, 12: 505, 13: 385, 14: 160, 15: 380, 16: 525, 17: 165, 18: 428,
            },
          ),
        ],
      );
    }

    // 3. The Loop (Red Course - Counter-Clockwise)
    if (!existing.any((c) => c.name.toLowerCase().contains('the loop (red)'))) {
      await createCourse(
        name: 'Forest Dunes (The Loop - Red)',
        city: 'Roscommon',
        state: 'MI',
        holeCount: 18,
        pars: [4, 3, 4, 5, 4, 3, 4, 4, 4, 4, 3, 4, 5, 4, 3, 5, 3, 4],
        strokeIndexes: [6, 16, 8, 2, 10, 18, 4, 14, 12, 7, 15, 9, 3, 11, 17, 1, 13, 5],
        tees: [
          const TeeBoxInput(
            name: 'Back',
            colorHex: '#1A1A1A',
            courseRating: 73.5,
            slopeRating: 135,
            totalYardage: 6805,
            holeYardages: {
              1: 420, 2: 175, 3: 435, 4: 550, 5: 400, 6: 185, 7: 425, 8: 415, 9: 390,
              10: 430, 11: 170, 12: 410, 13: 560, 14: 395, 15: 180, 16: 580, 17: 195, 18: 470,
            },
          ),
          const TeeBoxInput(
            name: 'Middle',
            colorHex: '#2563EB',
            courseRating: 70.6,
            slopeRating: 129,
            totalYardage: 6064,
            holeYardages: {
              1: 380, 2: 155, 3: 390, 4: 495, 5: 360, 6: 160, 7: 385, 8: 375, 9: 350,
              10: 390, 11: 145, 12: 370, 13: 505, 14: 355, 15: 160, 16: 530, 17: 170, 18: 430,
            },
          ),
        ],
      );
    }

    // 4. The Bootlegger (10-Hole Short Course)
    if (!existing.any((c) => c.name.toLowerCase().contains('bootlegger'))) {
      await createCourse(
        name: 'Forest Dunes (The Bootlegger)',
        city: 'Roscommon',
        state: 'MI',
        holeCount: 10,
        pars: [3, 3, 3, 3, 3, 3, 3, 3, 3, 3],
        strokeIndexes: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        tees: [
          const TeeBoxInput(
            name: 'Standard',
            colorHex: '#10B981',
            courseRating: 27.0,
            slopeRating: 90,
            totalYardage: 1065,
            holeYardages: {
              1: 110, 2: 85, 3: 135, 4: 70, 5: 120,
              6: 95, 7: 145, 8: 65, 9: 115, 10: 125,
            },
          ),
        ],
      );
    }
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
