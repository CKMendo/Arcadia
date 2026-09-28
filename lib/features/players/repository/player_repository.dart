import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../database/app_database.dart';

import '../../../shared/utils/player_initials_helper.dart';

class PlayerRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  PlayerRepository(this._db);

  Stream<List<Player>> watchAllPlayers() {
    return (_db.select(_db.players)
          ..orderBy([
            (t) => OrderingTerm(expression: t.fullName, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  Future<List<Player>> getAllPlayers() async {
    final players = await (_db.select(_db.players)
          ..orderBy([
            (t) => OrderingTerm(expression: t.fullName, mode: OrderingMode.asc)
          ]))
        .get();

    // Self-healing: ensure all players have true first and last name initials
    for (final p in players) {
      final trueInitials = PlayerInitialsHelper.compute(p.fullName);
      if (p.initials != trueInitials) {
        await _db.update(_db.players).replace(p.copyWith(initials: trueInitials));
      }
    }

    return players;
  }

  Future<Player?> getPlayerById(String id) {
    return (_db.select(_db.players)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> createPlayer({
    required String fullName,
    String? nickname,
    String? initials,
    required double handicapIndex,
    String? preferredTee,
    String? ghinNumber,
    String? phoneNumber,
    String? email,
    String? photoPath,
  }) async {
    final id = _uuid.v4();
    final effectiveInitials = PlayerInitialsHelper.compute(fullName, initials);
    final effectiveNickname = (nickname != null && nickname.trim().isNotEmpty)
        ? nickname.trim()
        : fullName.split(' ').first;

    await _db.into(_db.players).insert(
          PlayersCompanion(
            id: Value(id),
            fullName: Value(fullName.trim()),
            nickname: Value(effectiveNickname),
            initials: Value(effectiveInitials),
            handicapIndex: Value(handicapIndex),
            preferredTee: Value(preferredTee),
            ghinNumber: Value(ghinNumber),
            phoneNumber: Value(phoneNumber),
            email: Value(email),
            photoPath: Value(photoPath),
            isActive: const Value(true),
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  }

  Future<void> updatePlayer(Player player) {
    final trueInitials = PlayerInitialsHelper.compute(player.fullName, player.initials);
    final updated = player.copyWith(initials: trueInitials);
    return _db.update(_db.players).replace(updated);
  }

  Future<void> deletePlayer(String id) {
    return (_db.delete(_db.players)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updatePlayerPhoto(String id, String? photoPath) async {
    final player = await getPlayerById(id);
    if (player != null) {
      await updatePlayer(player.copyWith(photoPath: Value(photoPath)));
    }
  }

  Future<void> seedSample8Players() async {
    final existing = await getAllPlayers();
    if (existing.isNotEmpty) return;

    final samples = [
      {'name': 'Neal Patel', 'nick': 'Neal', 'hcp': 5.5, 'tee': 'Blue', 'phone': '(248) 555-0142'},
      {'name': 'Chet Mehta', 'nick': 'Chet', 'hcp': 8.7, 'tee': 'Blue', 'phone': '(313) 555-0188'},
      {'name': 'Raudel Sandoval', 'nick': 'Raudel', 'hcp': 12.0, 'tee': 'White', 'phone': '(734) 555-0193'},
      {'name': 'Vilmer Villaverde', 'nick': 'Vilmer', 'hcp': 16.5, 'tee': 'White', 'phone': '(616) 555-0125'},
      {'name': 'Sushil Bhakta', 'nick': 'Hany', 'hcp': 6.3, 'tee': 'Blue', 'phone': '(248) 555-0177'},
      {'name': 'Hiten Amin', 'nick': 'Hiten', 'hcp': 8.2, 'tee': 'Blue', 'phone': '(586) 555-0164'},
      {'name': 'Hitesh Patel', 'nick': 'Hitesh', 'hcp': 12.8, 'tee': 'White', 'phone': '(248) 555-0131'},
      {'name': 'Vinodh Rapur', 'nick': 'Vinny', 'hcp': 15.3, 'tee': 'White', 'phone': '(734) 555-0159'},
    ];

    for (final s in samples) {
      await createPlayer(
        fullName: s['name'] as String,
        nickname: s['nick'] as String,
        handicapIndex: s['hcp'] as double,
        preferredTee: s['tee'] as String,
        phoneNumber: s['phone'] as String,
      );
    }
  }

  Future<void> clearAllPlayers() async {
    await _db.delete(_db.players).go();
  }
}
