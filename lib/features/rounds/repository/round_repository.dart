import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../database/app_database.dart';
import '../models/active_round_session.dart';

class RoundRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();
  void Function()? onDataChanged;

  RoundRepository(this._db, {this.onDataChanged});

  Stream<List<SavedRound>> watchSavedRounds({String? tournamentId}) {
    final query = _db.select(_db.savedRounds);
    if (tournamentId != null) {
      query.where((t) => t.tournamentId.equals(tournamentId));
    }
    return (query
          ..orderBy([
            (t) => OrderingTerm(expression: t.datePlayed, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  Future<List<SavedRound>> getAllSavedRounds({String? tournamentId}) {
    final query = _db.select(_db.savedRounds);
    if (tournamentId != null) {
      query.where((t) => t.tournamentId.equals(tournamentId));
    }
    return (query
          ..orderBy([
            (t) => OrderingTerm(expression: t.datePlayed, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<SavedRound?> getSavedRound(String id) {
    return (_db.select(_db.savedRounds)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<SavedRound?> getRoundById(String id) => getSavedRound(id);

  Future<String> saveCompletedRound(ActiveRoundSession session) async {
    final existingId = session.savedRoundId;
    if (existingId != null && existingId.isNotEmpty) {
      await updateSavedRound(existingId, session);
      return existingId;
    }

    final roundId = _uuid.v4();
    final jsonString = jsonEncode(session.toJson());

    // Determine low net winner
    String? winnerName;
    if (session.players.isNotEmpty) {
      var minNet = 999;
      for (final p in session.players) {
        final net = session.totalNet(p.playerId);
        if (net > 0 && net < minNet) {
          minNet = net;
          winnerName = p.name;
        }
      }
    }

    await _db.into(_db.savedRounds).insert(
          SavedRoundsCompanion(
            id: Value(roundId),
            tournamentId: Value(session.tournamentId),
            courseId: Value(session.courseId),
            courseName: Value(session.courseName),
            roundNumber: Value(session.roundNumber),
            datePlayed: Value(session.datePlayed.millisecondsSinceEpoch),
            format: Value(session.format),
            isComplete: Value(session.isRoundComplete),
            winnerName: Value(winnerName),
            roundPayloadJson: Value(jsonString),
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );

    // Clear active draft
    await clearActiveDraft();
    onDataChanged?.call();

    return roundId;
  }

  Future<void> updateSavedRound(String roundId, ActiveRoundSession session) async {
    final jsonString = jsonEncode(session.toJson());

    String? winnerName;
    if (session.players.isNotEmpty) {
      var minNet = 999;
      for (final p in session.players) {
        final net = session.totalNet(p.playerId);
        if (net > 0 && net < minNet) {
          minNet = net;
          winnerName = p.name;
        }
      }
    }

    await (_db.update(_db.savedRounds)..where((t) => t.id.equals(roundId))).write(
          SavedRoundsCompanion(
            courseId: Value(session.courseId),
            courseName: Value(session.courseName),
            roundNumber: Value(session.roundNumber),
            datePlayed: Value(session.datePlayed.millisecondsSinceEpoch),
            format: Value(session.format),
            isComplete: Value(session.isRoundComplete),
            winnerName: Value(winnerName),
            roundPayloadJson: Value(jsonString),
          ),
        );

    await clearActiveDraft();
    onDataChanged?.call();
  }

  /// Unlocks a finalized round so it can be edited, modifying scores, tee selections, and handicaps.
  Future<ActiveRoundSession?> unlockSavedRound(String roundId) async {
    final saved = await getSavedRound(roundId);
    if (saved == null) return null;
    try {
      final map = jsonDecode(saved.roundPayloadJson) as Map<String, dynamic>;
      final session = ActiveRoundSession.fromJson(map);
      session.savedRoundId = roundId;
      await saveActiveDraft(session);
      onDataChanged?.call();
      return session;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteSavedRound(String id) async {
    await (_db.delete(_db.savedRounds)..where((t) => t.id.equals(id))).go();
    onDataChanged?.call();
  }

  Stream<ActiveRoundSession?> watchActiveDraft() {
    return (_db.select(_db.activeRoundDraft)..where((t) => t.id.equals(1)))
        .watchSingleOrNull()
        .map((row) {
      if (row == null) return null;
      try {
        final map = jsonDecode(row.roundPayloadJson) as Map<String, dynamic>;
        return ActiveRoundSession.fromJson(map);
      } catch (e) {
        return null;
      }
    });
  }

  Future<ActiveRoundSession?> getActiveDraft() async {
    final row = await (_db.select(_db.activeRoundDraft)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (row == null) return null;
    try {
      final map = jsonDecode(row.roundPayloadJson) as Map<String, dynamic>;
      return ActiveRoundSession.fromJson(map);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveActiveDraft(ActiveRoundSession session) async {
    final jsonString = jsonEncode(session.toJson());
    await _db.into(_db.activeRoundDraft).insertOnConflictUpdate(
          ActiveRoundDraftCompanion(
            id: const Value(1),
            tournamentId: Value(session.tournamentId),
            courseId: Value(session.courseId),
            roundPayloadJson: Value(jsonString),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
    onDataChanged?.call();
  }

  Future<void> clearActiveDraft() async {
    await (_db.delete(_db.activeRoundDraft)..where((t) => t.id.equals(1))).go();
  }
}
