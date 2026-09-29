import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../database/app_database.dart';
import '../../../shared/utils/player_initials_helper.dart';
import '../services/player_backup_service.dart';

class PlayerRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();
  final PlayerBackupService _backupService = PlayerBackupService();
  void Function()? onRosterChanged;

  PlayerRepository(this._db, {this.onRosterChanged});

  Stream<List<Player>> watchAllPlayers() {
    return (_db.select(_db.players)
          ..orderBy([
            (t) => OrderingTerm(expression: t.fullName, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  /// Self-healing roster assurance:
  /// If the database was wiped by an update or reinstall, automatically restores
  /// all players from the persistent multi-layer backup.
  /// If database has players, ensures the latest state is backed up.
  Future<void> ensureRosterPreserved() async {
    try {
      final current = await (_db.select(_db.players)).get();
      if (current.isEmpty) {
        final backup = await _backupService.loadBackup();
        if (backup != null && backup.isNotEmpty) {
          debugPrint('[PlayerRepository] Auto-restoring ${backup.length} players from persistent backup...');
          for (final p in backup) {
            await _db.into(_db.players).insertOnConflictUpdate(
                  PlayersCompanion(
                    id: Value(p.id),
                    fullName: Value(p.fullName),
                    nickname: Value(p.nickname),
                    initials: Value(p.initials),
                    handicapIndex: Value(p.handicapIndex),
                    preferredTee: Value(p.preferredTee),
                    ghinNumber: Value(p.ghinNumber),
                    phoneNumber: Value(p.phoneNumber),
                    email: Value(p.email),
                    photoPath: Value(p.photoPath),
                    isActive: Value(p.isActive),
                    createdAt: Value(p.createdAt),
                  ),
                );
          }
        }
      } else {
        // Sync backup with existing database players
        await _backupService.saveBackup(current);
      }
    } catch (e) {
      debugPrint('[PlayerRepository] ensureRosterPreserved error: $e');
    }
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
    bool autoBackup = true,
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

    // Auto-backup whenever a player is added
    if (autoBackup) {
      final all = await (_db.select(_db.players)).get();
      await _backupService.saveBackup(all);
    }
    onRosterChanged?.call();
  }

  Future<void> updatePlayer(Player player) async {
    final trueInitials = PlayerInitialsHelper.compute(player.fullName, player.initials);
    final updated = player.copyWith(initials: trueInitials);
    await _db.update(_db.players).replace(updated);

    // Auto-backup whenever a player is edited
    final all = await (_db.select(_db.players)).get();
    await _backupService.saveBackup(all);
    onRosterChanged?.call();
  }

  Future<void> deletePlayer(String id) async {
    await (_db.delete(_db.players)..where((t) => t.id.equals(id))).go();

    // Auto-backup remaining roster
    final all = await (_db.select(_db.players)).get();
    if (all.isNotEmpty) {
      await _backupService.saveBackup(all);
    }
    onRosterChanged?.call();
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

    for (final s in PlayerBackupService.bundledArcadiaRoster) {
      await createPlayer(
        fullName: s['name'] as String,
        nickname: s['nick'] as String,
        handicapIndex: (s['hcp'] as num).toDouble(),
        preferredTee: s['tee'] as String,
        phoneNumber: s['phone'] as String,
        autoBackup: false,
      );
    }

    final all = await (_db.select(_db.players)).get();
    await _backupService.saveBackup(all);
    onRosterChanged?.call();
  }

  /// Manually force a fresh backup of the current roster
  Future<void> saveManualBackup() async {
    final all = await (_db.select(_db.players)).get();
    await _backupService.saveBackup(all);
  }

  /// Restores all players from the backup into the database
  Future<int> restoreFromBackup() async {
    final backup = await _backupService.loadBackup();
    if (backup == null || backup.isEmpty) return 0;

    for (final p in backup) {
      await _db.into(_db.players).insertOnConflictUpdate(
            PlayersCompanion(
              id: Value(p.id),
              fullName: Value(p.fullName),
              nickname: Value(p.nickname),
              initials: Value(p.initials),
              handicapIndex: Value(p.handicapIndex),
              preferredTee: Value(p.preferredTee),
              ghinNumber: Value(p.ghinNumber),
              phoneNumber: Value(p.phoneNumber),
              email: Value(p.email),
              photoPath: Value(p.photoPath),
              isActive: Value(p.isActive),
              createdAt: Value(p.createdAt),
            ),
          );
    }
    onRosterChanged?.call();
    return backup.length;
  }

  /// Retrieves metadata about the stored backup
  Future<RosterBackupInfo> getBackupInfo() {
    return _backupService.getBackupInfo();
  }

  /// Exports the current roster as formatted JSON
  Future<String> exportRosterJson() async {
    final all = await getAllPlayers();
    return _backupService.exportJson(all);
  }

  /// Shares the roster via text, WhatsApp, email, or Google Drive
  Future<void> shareRosterBackup() async {
    final all = await getAllPlayers();
    await _backupService.shareRosterBackup(all);
  }

  /// Imports players from a raw JSON string
  Future<int> importRosterFromJson(String jsonStr) async {
    try {
      final decoded = jsonDecode(jsonStr);
      List<dynamic> list;
      if (decoded is Map<String, dynamic> && decoded.containsKey('players')) {
        list = decoded['players'] as List<dynamic>;
      } else if (decoded is List<dynamic>) {
        list = decoded;
      } else {
        return 0;
      }

      var count = 0;
      for (final item in list) {
        final p = _backupService.playerFromMap(item as Map<String, dynamic>);
        await _db.into(_db.players).insertOnConflictUpdate(
              PlayersCompanion(
                id: Value(p.id),
                fullName: Value(p.fullName),
                nickname: Value(p.nickname),
                initials: Value(p.initials),
                handicapIndex: Value(p.handicapIndex),
                preferredTee: Value(p.preferredTee),
                ghinNumber: Value(p.ghinNumber),
                phoneNumber: Value(p.phoneNumber),
                email: Value(p.email),
                photoPath: Value(p.photoPath),
                isActive: Value(p.isActive),
                createdAt: Value(p.createdAt),
              ),
            );
        count++;
      }

      final all = await (_db.select(_db.players)).get();
      await _backupService.saveBackup(all);
      onRosterChanged?.call();
      return count;
    } catch (e) {
      debugPrint('[PlayerRepository] importRosterFromJson error: $e');
      return 0;
    }
  }

  Future<void> clearAllPlayers() async {
    await _db.delete(_db.players).go();
    onRosterChanged?.call();
  }
}
