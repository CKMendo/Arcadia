import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../database/app_database.dart';
import '../../rounds/models/active_round_session.dart';
import '../../tournaments/services/tournament_pairings_engine.dart';
import '../models/scheduled_round.dart';

class TripScheduleRepository {
  static const String _keyScheduledRounds = 'trip_scheduled_rounds_json';
  static const String _keyScheduleFinalized = 'trip_schedule_finalized_flag';
  static const String _backupFileName = 'arcadia_trip_schedule_backup.json';

  final _scheduleController = StreamController<List<ScheduledRound>>.broadcast();
  final _finalizedController = StreamController<bool>.broadcast();

  final TournamentPairingsEngine _pairingsEngine = TournamentPairingsEngine();

  bool get _isTestEnv => Platform.environment['FLUTTER_TEST'] == 'true';

  TripScheduleRepository() {
    _init();
  }

  Future<void> _init() async {
    final schedule = await getSchedule();
    _scheduleController.add(schedule);
    final finalized = await isScheduleFinalized();
    _finalizedController.add(finalized);
  }

  Stream<List<ScheduledRound>> watchSchedule() async* {
    yield await getSchedule();
    yield* _scheduleController.stream;
  }

  Stream<bool> watchIsFinalized() async* {
    yield await isScheduleFinalized();
    yield* _finalizedController.stream;
  }

  Future<List<ScheduledRound>> getSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyScheduledRounds);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        final rounds = list
            .map((item) => ScheduledRound.fromJson(item as Map<String, dynamic>))
            .toList();
        _sortRounds(rounds);
        return rounds;
      }

      if (_isTestEnv) return [];

      // Self-healing from file layers if SharedPreferences was wiped
      final backupList = await _loadScheduleFromFileLayers();
      if (backupList != null && backupList.isNotEmpty) {
        final encoded = jsonEncode(backupList.map((r) => r.toJson()).toList());
        await prefs.setString(_keyScheduledRounds, encoded);
        return backupList;
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  void _sortRounds(List<ScheduledRound> rounds) {
    rounds.sort((a, b) {
      final cmpDate = a.date.compareTo(b.date);
      if (cmpDate != 0) return cmpDate;
      return a.roundNumber.compareTo(b.roundNumber);
    });
  }

  Future<bool> isScheduleFinalized() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyScheduleFinalized) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setScheduleFinalized(bool isFinalized) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyScheduleFinalized, isFinalized);
      _finalizedController.add(isFinalized);

      // Also persist finalized state alongside schedule backup
      final schedule = await getSchedule();
      await _writeScheduleToAllFileLayers(schedule, isFinalized);
    } catch (_) {}
  }

  Future<void> saveSchedule(List<ScheduledRound> schedule) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = schedule.map((r) => r.toJson()).toList();
      final jsonStr = jsonEncode(list);
      await prefs.setString(_keyScheduledRounds, jsonStr);
      _scheduleController.add(schedule);

      final isFinalized = prefs.getBool(_keyScheduleFinalized) ?? false;
      await _writeScheduleToAllFileLayers(schedule, isFinalized);
    } catch (_) {}
  }

  Future<void> removeCourseFromSchedule(String courseId) async {
    try {
      final schedule = await getSchedule();
      final remaining = schedule.where((r) => r.courseId != courseId).toList();
      if (remaining.length != schedule.length) {
        final renumbered = <ScheduledRound>[];
        for (var i = 0; i < remaining.length; i++) {
          renumbered.add(remaining[i].copyWith(roundNumber: i + 1));
        }
        await saveSchedule(renumbered);
      }
    } catch (_) {}
  }

  Future<List<ScheduledRound>?> _loadScheduleFromFileLayers() async {
    if (_isTestEnv) return null;

    // Check Documents Directory
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final docFile = File('${docsDir.path}/$_backupFileName');
      if (await docFile.exists()) {
        final content = await docFile.readAsString();
        final rounds = _parseRoundsFromJson(content);
        if (rounds != null && rounds.isNotEmpty) return rounds;
      }
    } catch (_) {}

    // Check External App Directory
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final extFile = File('${extDir.path}/$_backupFileName');
        if (await extFile.exists()) {
          final content = await extFile.readAsString();
          final rounds = _parseRoundsFromJson(content);
          if (rounds != null && rounds.isNotEmpty) return rounds;
        }
      }
    } catch (_) {}

    // Check Android Public Download Directory
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final downloadFile = File('/sdcard/Download/$_backupFileName');
        if (await downloadFile.exists()) {
          final content = await downloadFile.readAsString();
          final rounds = _parseRoundsFromJson(content);
          if (rounds != null && rounds.isNotEmpty) return rounds;
        }
      } catch (_) {}
    }

    return null;
  }

  List<ScheduledRound>? _parseRoundsFromJson(String content) {
    try {
      final decoded = jsonDecode(content);
      List<dynamic>? list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map<String, dynamic> && decoded['rounds'] is List) {
        list = decoded['rounds'] as List<dynamic>;
      }
      if (list != null) {
        final rounds = list
            .map((item) => ScheduledRound.fromJson(item as Map<String, dynamic>))
            .toList();
        _sortRounds(rounds);
        return rounds;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _writeScheduleToAllFileLayers(List<ScheduledRound> schedule, bool isFinalized) async {
    if (_isTestEnv || schedule.isEmpty) return;

    try {
      final payload = {
        'version': 1,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isFinalized': isFinalized,
        'rounds': schedule.map((r) => r.toJson()).toList(),
      };
      final jsonStr = jsonEncode(payload);

      // Documents Directory
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final docFile = File('${docsDir.path}/$_backupFileName');
        await docFile.writeAsString(jsonStr);
      } catch (_) {}

      // External App Directory
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final extFile = File('${extDir.path}/$_backupFileName');
          await extFile.writeAsString(jsonStr);
        }
      } catch (_) {}

      // Android Download Directory (survives full uninstall)
      if (!kIsWeb && Platform.isAndroid) {
        try {
          final downloadDir = Directory('/sdcard/Download');
          if (await downloadDir.exists()) {
            final downloadFile = File('/sdcard/Download/$_backupFileName');
            await downloadFile.writeAsString(jsonStr);
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Called on startup to guarantee schedule survives updates/reinstalls
  Future<int> ensureSchedulePreserved() async {
    final schedule = await getSchedule();
    return schedule.length;
  }

  Future<void> addOrUpdateScheduledRound(ScheduledRound round) async {
    final current = await getSchedule();
    final index = current.indexWhere((r) => r.id == round.id);
    if (index >= 0) {
      current[index] = round;
    } else {
      current.add(round);
    }
    // Sort chronologically
    current.sort((a, b) {
      final cmpDate = a.date.compareTo(b.date);
      if (cmpDate != 0) return cmpDate;
      return a.roundNumber.compareTo(b.roundNumber);
    });
    // Re-index round numbers if needed
    for (var i = 0; i < current.length; i++) {
      current[i] = current[i].copyWith(roundNumber: i + 1);
    }
    await saveSchedule(current);
  }

  Future<void> deleteScheduledRound(String id) async {
    final current = await getSchedule();
    current.removeWhere((r) => r.id == id);
    for (var i = 0; i < current.length; i++) {
      current[i] = current[i].copyWith(roundNumber: i + 1);
    }
    await saveSchedule(current);
  }

  Future<void> unlockSchedule() async {
    await setScheduleFinalized(false);
  }

  /// Seeds standard Arcadia Bluffs 3-round trip schedule:
  /// Round 1: The Bluffs (Day 1 - 9:30 AM & 9:42 AM)
  /// Round 2: The South (Day 2 - 9:30 AM & 9:42 AM)
  /// Round 3: The Bluffs (Day 3 - 9:30 AM & 9:42 AM) - Final Championship Round
  Future<void> seedDefaultArcadiaSchedule(List<Course> availableCourses) async {
    final now = DateTime.now();
    // Default to upcoming June weekend or 3 consecutive days
    final startDate = DateTime(now.year < 2027 ? 2027 : now.year, 6, 18);

    Course? bluffsCourse;
    Course? southCourse;
    for (final c in availableCourses) {
      if (c.name.toLowerCase().contains('south')) {
        southCourse = c;
      } else {
        bluffsCourse = c;
      }
    }
    final bluffsId = bluffsCourse?.id ?? 'c_bluffs';
    final bluffsName = bluffsCourse?.name ?? 'Arcadia Bluffs (The Bluffs)';
    final southId = southCourse?.id ?? 'c_south';
    final southName = southCourse?.name ?? 'Arcadia Bluffs (The South)';

    final defaultRounds = [
      ScheduledRound(
        id: 'sched_r1',
        roundNumber: 1,
        courseId: bluffsId,
        courseName: bluffsName,
        date: startDate,
        teeTimeGroup1: '9:30 AM',
        teeTimeGroup2: '9:42 AM',
        notes: 'Opening Round • Championship Links',
        isFinalRound: false,
        holeCount: 18,
      ),
      ScheduledRound(
        id: 'sched_r2',
        roundNumber: 2,
        courseId: southId,
        courseName: southName,
        date: startDate.add(const Duration(days: 1)),
        teeTimeGroup1: '9:30 AM',
        teeTimeGroup2: '9:42 AM',
        notes: 'C.B. Macdonald Geometric Classic',
        isFinalRound: false,
        holeCount: 18,
      ),
      ScheduledRound(
        id: 'sched_r3',
        roundNumber: 3,
        courseId: bluffsId,
        courseName: bluffsName,
        date: startDate.add(const Duration(days: 2)),
        teeTimeGroup1: '9:30 AM',
        teeTimeGroup2: '9:42 AM',
        notes: 'Championship Final Round • Top 4 Draft Partners',
        isFinalRound: true,
        holeCount: 18,
      ),
    ];

    await saveSchedule(defaultRounds);
    await setScheduleFinalized(false);
  }

  /// Generates optimal AI pairings for ALL scheduled regulation rounds without locking/finalizing the schedule.
  /// Rounds on courses with fewer than 18 regulation holes are excluded from 2-man pairings
  /// and count exclusively toward the Birdie Pot.
  Future<List<ScheduledRound>> generatePairingsForSchedule({
    required List<Player> players,
    required List<ActiveRoundSession> pastSavedRounds,
  }) async {
    final schedule = await getSchedule();
    if (schedule.isEmpty || players.length < 4) return schedule;

    // Filter regulation rounds (18 holes) - short courses (<18 holes) are for Birdie Pot only
    final regulationSchedule = schedule.where((r) => !r.isShortCourse).toList();

    final infos = regulationSchedule
        .map((r) => ScheduledRoundInfo(
              roundNumber: r.roundNumber,
              date: r.date,
              pairingPlan: r.pairingPlan,
              holeCount: r.holeCount,
            ))
        .toList();

    final plans = _pairingsEngine.generateFullSchedulePairings(
      players: players,
      scheduledRounds: infos,
      pastCompletedRounds: pastSavedRounds,
    );

    final planMap = <int, RoundPairingPlan>{};
    for (var i = 0; i < regulationSchedule.length; i++) {
      if (i < plans.length) {
        planMap[regulationSchedule[i].roundNumber] = plans[i];
      }
    }

    final updatedSchedule = <ScheduledRound>[];
    for (final round in schedule) {
      if (round.isShortCourse) {
        updatedSchedule.add(round.copyWith(
          clearPairingPlan: true,
          format: 'Birdie Pot Only (Short Course)',
        ));
      } else {
        final plan = planMap[round.roundNumber];
        updatedSchedule.add(round.copyWith(pairingPlan: plan));
      }
    }

    await saveSchedule(updatedSchedule);
    return updatedSchedule;
  }

  /// Locks and finalizes the current schedule with its chosen pairings.
  Future<void> finalizeScheduleAndLock() async {
    await setScheduleFinalized(true);
  }

  /// Finalizes the trip schedule and generates AI pairings for ALL scheduled rounds.
  Future<void> finalizeScheduleAndGeneratePairings({
    required List<Player> players,
    required List<ActiveRoundSession> pastSavedRounds,
  }) async {
    await generatePairingsForSchedule(
      players: players,
      pastSavedRounds: pastSavedRounds,
    );
    await finalizeScheduleAndLock();
  }

  /// Synchronizes scheduled round pairing plans with updated player names, nicknames, and handicaps.
  Future<void> syncPlayerProfiles(List<Player> latestPlayers) async {
    if (latestPlayers.isEmpty) return;

    final schedule = await getSchedule();
    if (schedule.isEmpty) return;

    bool anyChanged = false;
    final updatedSchedule = <ScheduledRound>[];

    for (final round in schedule) {
      if (round.pairingPlan != null) {
        final updatedPlan = round.pairingPlan!.withLatestPlayers(latestPlayers);
        updatedSchedule.add(round.copyWith(pairingPlan: updatedPlan));
        anyChanged = true;
      } else {
        updatedSchedule.add(round);
      }
    }

    if (anyChanged) {
      await saveSchedule(updatedSchedule);
    }
  }
}
