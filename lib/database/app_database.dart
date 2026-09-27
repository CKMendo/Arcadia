import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Players extends Table {
  TextColumn get id => text()();
  TextColumn get fullName => text()();
  TextColumn get nickname => text()();
  TextColumn get initials => text()();
  RealColumn get handicapIndex => real()();
  TextColumn get preferredTee => text().nullable()();
  TextColumn get ghinNumber => text().nullable()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Courses extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get city => text()();
  TextColumn get state => text()();
  IntColumn get holeCount => integer().withDefault(const Constant(18))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CourseHoles extends Table {
  TextColumn get id => text()(); // e.g. "{courseId}_h{holeNumber}"
  TextColumn get courseId => text().references(Courses, #id, onDelete: KeyAction.cascade)();
  IntColumn get holeNumber => integer()();
  IntColumn get par => integer().withDefault(const Constant(4))();
  IntColumn get strokeIndex => integer().withDefault(const Constant(18))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {courseId, holeNumber},
  ];
}

@DataClassName('TeeBox')
class TeeBoxes extends Table {
  TextColumn get id => text()();
  TextColumn get courseId => text().references(Courses, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get colorHex => text().nullable()();
  RealColumn get courseRating => real()();
  IntColumn get slopeRating => integer()();
  IntColumn get totalYardage => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class HoleYardages extends Table {
  TextColumn get teeBoxId => text().references(TeeBoxes, #id, onDelete: KeyAction.cascade)();
  TextColumn get courseHoleId => text().references(CourseHoles, #id, onDelete: KeyAction.cascade)();
  IntColumn get yardage => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {teeBoxId, courseHoleId};
}

class Tournaments extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get startDate => integer()();
  IntColumn get endDate => integer()();
  TextColumn get formatType => text().withDefault(const Constant('hybrid'))(); // individual, teams, hybrid
  TextColumn get teamAName => text().withDefault(const Constant('Team Blue'))();
  TextColumn get teamBName => text().withDefault(const Constant('Team Red'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class TournamentPlayers extends Table {
  TextColumn get tournamentId => text().references(Tournaments, #id, onDelete: KeyAction.cascade)();
  TextColumn get playerId => text().references(Players, #id, onDelete: KeyAction.cascade)();
  TextColumn get teamId => text().withDefault(const Constant('none'))(); // 'a', 'b', 'none'
  RealColumn get customHandicap => real().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {tournamentId, playerId};
}

class SavedRounds extends Table {
  TextColumn get id => text()();
  TextColumn get tournamentId => text().nullable().references(Tournaments, #id, onDelete: KeyAction.setNull)();
  TextColumn get courseId => text().references(Courses, #id)();
  TextColumn get courseName => text()();
  IntColumn get roundNumber => integer().withDefault(const Constant(1))();
  IntColumn get datePlayed => integer()();
  TextColumn get format => text().withDefault(const Constant('stroke'))();
  BoolColumn get isComplete => boolean().withDefault(const Constant(false))();
  TextColumn get winnerName => text().nullable()();
  TextColumn get roundPayloadJson => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ActiveRoundDraft extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get tournamentId => text().nullable()();
  TextColumn get courseId => text()();
  TextColumn get roundPayloadJson => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get settingsJson => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Players,
    Courses,
    CourseHoles,
    TeeBoxes,
    HoleYardages,
    Tournaments,
    TournamentPlayers,
    SavedRounds,
    ActiveRoundDraft,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'arcadia_golf_trip');
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
