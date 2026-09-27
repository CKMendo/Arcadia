import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../database/app_database.dart';

class TournamentRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  TournamentRepository(this._db);

  Stream<Tournament?> watchActiveTournament() {
    return (_db.select(_db.tournaments)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<Tournament?> getActiveTournament() {
    return (_db.select(_db.tournaments)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<Tournament>> getAllTournaments() {
    return (_db.select(_db.tournaments)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<String> createTournament({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String formatType = 'hybrid',
    String teamAName = 'Team Blue',
    String teamBName = 'Team Red',
    List<String>? initialPlayerIds,
  }) async {
    final id = _uuid.v4();

    await _db.transaction(() async {
      await _db.into(_db.tournaments).insert(
            TournamentsCompanion(
              id: Value(id),
              name: Value(name.trim()),
              startDate: Value(startDate.millisecondsSinceEpoch),
              endDate: Value(endDate.millisecondsSinceEpoch),
              formatType: Value(formatType),
              teamAName: Value(teamAName.trim()),
              teamBName: Value(teamBName.trim()),
              isActive: const Value(true),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

      if (initialPlayerIds != null) {
        for (final pId in initialPlayerIds) {
          await _db.into(_db.tournamentPlayers).insert(
                TournamentPlayersCompanion(
                  tournamentId: Value(id),
                  playerId: Value(pId),
                  teamId: const Value('none'),
                ),
              );
        }
      }
    });

    return id;
  }

  Future<void> updateTournament(Tournament tournament) {
    return _db.update(_db.tournaments).replace(tournament);
  }

  Future<void> deleteTournament(String id) {
    return (_db.delete(_db.tournaments)..where((t) => t.id.equals(id))).go();
  }

  Future<List<TournamentPlayerInfo>> getTournamentPlayers(String tournamentId) async {
    final tpList = await (_db.select(_db.tournamentPlayers)
          ..where((t) => t.tournamentId.equals(tournamentId)))
        .get();

    final result = <TournamentPlayerInfo>[];
    for (final tp in tpList) {
      final player = await (_db.select(_db.players)
            ..where((t) => t.id.equals(tp.playerId)))
          .getSingleOrNull();
      if (player != null) {
        result.add(TournamentPlayerInfo(
          player: player,
          teamId: tp.teamId,
          customHandicap: tp.customHandicap,
        ));
      }
    }
    return result;
  }

  Future<void> setTournamentPlayers(
    String tournamentId,
    List<String> playerIds,
  ) async {
    await (_db.delete(_db.tournamentPlayers)
          ..where((t) => t.tournamentId.equals(tournamentId)))
        .go();

    for (final pId in playerIds) {
      await _db.into(_db.tournamentPlayers).insert(
            TournamentPlayersCompanion(
              tournamentId: Value(tournamentId),
              playerId: Value(pId),
              teamId: const Value('none'),
            ),
          );
    }
  }

  Future<void> updatePlayerTeam({
    required String tournamentId,
    required String playerId,
    required String teamId,
    double? customHandicap,
  }) async {
    await (_db.update(_db.tournamentPlayers)
          ..where((t) =>
              t.tournamentId.equals(tournamentId) & t.playerId.equals(playerId)))
        .write(
      TournamentPlayersCompanion(
        teamId: Value(teamId),
        customHandicap: Value(customHandicap),
      ),
    );
  }
}

class TournamentPlayerInfo {
  final Player player;
  final String teamId; // 'a', 'b', 'none'
  final double? customHandicap;

  const TournamentPlayerInfo({
    required this.player,
    required this.teamId,
    this.customHandicap,
  });

  double get effectiveHandicap => customHandicap ?? player.handicapIndex;
}
