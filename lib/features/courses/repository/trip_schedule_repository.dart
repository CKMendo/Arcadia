import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../database/app_database.dart';
import '../../rounds/models/active_round_session.dart';
import '../../tournaments/services/tournament_pairings_engine.dart';
import '../models/scheduled_round.dart';

class TripScheduleRepository {
  static const String _keyScheduledRounds = 'trip_scheduled_rounds_json';
  static const String _keyScheduleFinalized = 'trip_schedule_finalized_flag';

  final _scheduleController = StreamController<List<ScheduledRound>>.broadcast();
  final _finalizedController = StreamController<bool>.broadcast();

  final TournamentPairingsEngine _pairingsEngine = TournamentPairingsEngine();

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
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      final rounds = list
          .map((item) => ScheduledRound.fromJson(item as Map<String, dynamic>))
          .toList();
      rounds.sort((a, b) {
        final cmpDate = a.date.compareTo(b.date);
        if (cmpDate != 0) return cmpDate;
        return a.roundNumber.compareTo(b.roundNumber);
      });
      return rounds;
    } catch (e) {
      return [];
    }
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
    } catch (_) {}
  }

  Future<void> saveSchedule(List<ScheduledRound> schedule) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = schedule.map((r) => r.toJson()).toList();
      await prefs.setString(_keyScheduledRounds, jsonEncode(list));
      _scheduleController.add(schedule);
    } catch (_) {}
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
      ),
    ];

    await saveSchedule(defaultRounds);
    await setScheduleFinalized(false);
  }

  /// Finalizes the trip schedule and generates AI pairings for ALL scheduled rounds.
  /// Examines past team pairings and avoids pairing people who have been paired up before.
  Future<void> finalizeScheduleAndGeneratePairings({
    required List<Player> players,
    required List<ActiveRoundSession> pastSavedRounds,
  }) async {
    final schedule = await getSchedule();
    if (schedule.isEmpty || players.length < 4) return;

    final updatedSchedule = <ScheduledRound>[];
    final priorScheduledInfos = <ScheduledRoundInfo>[];

    for (final round in schedule) {
      RoundPairingPlan plan;
      if (round.isFinalRound && players.length >= 8) {
        // Championship final round pairings
        plan = _pairingsEngine.generateFinalRoundPairings(
          players: players,
          pastRounds: pastSavedRounds,
          roundNumber: round.roundNumber,
        );
      } else {
        // Look at all team pairings prior to that date and avoid pairing people who've been paired up before
        plan = _pairingsEngine.generateSchedulePairingsForDate(
          players: players,
          roundDate: round.date,
          roundNumber: round.roundNumber,
          pastCompletedRounds: pastSavedRounds,
          priorScheduledRounds: List.from(priorScheduledInfos),
        );
      }

      final updatedRound = round.copyWith(pairingPlan: plan);
      updatedSchedule.add(updatedRound);
      priorScheduledInfos.add(
        ScheduledRoundInfo(
          roundNumber: round.roundNumber,
          date: round.date,
          pairingPlan: plan,
        ),
      );
    }

    await saveSchedule(updatedSchedule);
    await setScheduleFinalized(true);
  }
}
