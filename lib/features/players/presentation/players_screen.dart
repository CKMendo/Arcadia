import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../database/app_database.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/course_handicap_calculator.dart';
import '../../../shared/widgets/player_avatar.dart';
import '../repository/player_repository.dart';
import 'player_entry_screen.dart';

class PlayersScreen extends StatelessWidget {
  final PlayerRepository playerRepository;

  const PlayersScreen({
    super.key,
    required this.playerRepository,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Roster'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: AppColors.cyanLight, size: 28),
            tooltip: 'Add Player',
            onPressed: () => _openPlayerEntry(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.cyanLight, size: 28),
            onSelected: (value) async {
              if (value == 'backup') {
                await playerRepository.saveManualBackup();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF0F382A),
                      content: Text(
                        '🛡️ Roster backup saved! Persists across app updates and reinstalls.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }
              } else if (value == 'restore') {
                await _showRestoreBackupDialog(context);
              } else if (value == 'share') {
                await playerRepository.shareRosterBackup();
              } else if (value == 'import') {
                await _showImportRosterDialog(context);
              } else if (value == 'seed') {
                await playerRepository.seedSample8Players();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sample 8 players loaded with phone numbers', style: TextStyle(fontSize: 17)),
                    ),
                  );
                }
              } else if (value == 'clear') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Roster?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    content: const Text(
                      'This will remove all players from the current active roster.\n\nNote: Your persistent backup is preserved so you can restore anytime.',
                      style: TextStyle(fontSize: 17),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel', style: TextStyle(fontSize: 17)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Clear All', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await playerRepository.clearAllPlayers();
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'backup',
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.lakeCyan, size: 24),
                    SizedBox(width: 10),
                    Text('Backup Roster Now', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'restore',
                child: Row(
                  children: [
                    Icon(Icons.restore, color: AppColors.duneSand, size: 24),
                    SizedBox(width: 10),
                    Text('Restore from Backup', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: Colors.white70, size: 24),
                    SizedBox(width: 10),
                    Text('Share / Export Backup', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.file_download_outlined, color: Colors.white70, size: 24),
                    SizedBox(width: 10),
                    Text('Import Roster JSON', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'seed',
                child: Row(
                  children: [
                    Icon(Icons.group_add, color: AppColors.lakeCyan, size: 24),
                    SizedBox(width: 10),
                    Text('Load Sample 8 Players', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
                    SizedBox(width: 10),
                    Text('Clear Roster', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Player>>(
        stream: playerRepository.watchAllPlayers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final players = snapshot.data!;

          if (players.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cardBorder, width: 2),
                      ),
                      child: const Icon(
                        Icons.group_outlined,
                        size: 64,
                        color: AppColors.lakeCyan,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Players in Roster',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Add the 8 golfers for the trip. You will enter Name, Handicap, and Phone Number, and headshot spaces will be reserved for photos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                    ),
                    const SizedBox(height: 26),
                    ElevatedButton.icon(
                      onPressed: () => _openPlayerEntry(context),
                      icon: const Icon(Icons.person_add, size: 26),
                      label: const Text('Open Player Entry', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () => _showRestoreBackupDialog(context),
                      icon: const Icon(Icons.restore, size: 24, color: Color(0xFF04111D)),
                      label: const Text('Restore from Backup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.duneSand,
                        foregroundColor: const Color(0xFF04111D),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await playerRepository.seedSample8Players();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sample 8 players added with phone numbers!', style: TextStyle(fontSize: 17))),
                          );
                        }
                      },
                      icon: const Icon(Icons.bolt, color: AppColors.lakeCyan, size: 26),
                      label: const Text('Load Sample 8 Players', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          }

          final photoCount = players.where((p) => p.photoPath != null && p.photoPath!.isNotEmpty).length;

          return Column(
            children: [
              // Graphical Summary Banner with Crest
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF0C1929),
                  border: Border(
                    bottom: BorderSide(color: AppColors.cardBorder, width: 1.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.duneSand, width: 1.5),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/arcadia_logo.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ROSTER (${players.length} / 8 PLAYERS)',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: AppColors.cyanLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$photoCount photos added • ${players.length - photoCount} spaces reserved',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _showRestoreBackupDialog(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F382A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield, color: Color(0xFF10B981), size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Backed Up',
                              style: TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        'Avg HCP: ${_calculateAvgHcp(players)}',
                        style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Player List with Headshot Spaces
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final p = players[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Interactive Headshot / Avatar Space
                            GesturecastPlayerHeadshot(
                              player: p,
                              onPhotoUpdated: (newPath) async {
                                await playerRepository.updatePlayerPhoto(p.id, newPath);
                              },
                            ),
                            const SizedBox(width: 14),

                            // Player Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name and Nickname (Responsive Wrap to prevent overflow banner)
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        p.fullName,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      if (p.nickname.isNotEmpty && p.nickname != p.fullName.split(' ').first)
                                        Text(
                                          '"${p.nickname}"',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontStyle: FontStyle.italic,
                                            color: AppColors.duneSand,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Handicap, Phone, Tee Badges (Responsive Wrap to prevent overflow banner)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.lakeCyan.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.lakeCyan.withValues(alpha: 0.6)),
                                        ),
                                        child: Text(
                                          'HCP ${p.handicapIndex.toStringAsFixed(1)}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.cyanLight,
                                          ),
                                        ),
                                      ),
                                      if (p.phoneNumber != null && p.phoneNumber!.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceElevated,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: AppColors.cardBorder),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.phone, size: 14, color: AppColors.lakeCyan),
                                              const SizedBox(width: 4),
                                              Text(
                                                p.phoneNumber!,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (p.preferredTee != null && p.preferredTee!.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _getTeeColor(p.preferredTee!).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: _getTeeColor(p.preferredTee!).withValues(alpha: 0.6)),
                                          ),
                                          child: Text(
                                            '${p.preferredTee} Tee',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: _getTeeColor(p.preferredTee!),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Calculated Course Handicaps
                                  _buildCalculatedCourseHcpBanner(p),

                                  const SizedBox(height: 4),
                                  // Prompt if photo is missing
                                  if (p.photoPath == null || p.photoPath!.isEmpty)
                                    const Text(
                                      'Headshot space reserved • Tap photo to fill in',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Edit Icon Button
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppColors.lakeCyan, size: 24),
                              tooltip: 'Edit Player',
                              onPressed: () => _openPlayerEntry(context, player: p),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPlayerEntry(context),
        backgroundColor: AppColors.lakeCyan,
        foregroundColor: const Color(0xFF04111D),
        icon: const Icon(Icons.person_add, size: 24),
        label: const Text('Add Player', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCalculatedCourseHcpBanner(Player p) {
    final tee = p.preferredTee ?? 'White';
    final bluffsHcp = CourseHandicapCalculator.forBluffs(p.handicapIndex, tee);
    final southHcp = CourseHandicapCalculator.forSouth(p.handicapIndex, tee);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF081524),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.5)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          const Icon(Icons.sports_golf, size: 14, color: AppColors.lakeCyan),
          Text(
            'Course HCP ($tee):',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          Text(
            'Bluffs: $bluffsHcp',
            style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const Text('•', style: TextStyle(fontSize: 13, color: Colors.white38)),
          Text(
            'South: $southHcp',
            style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getTeeColor(String tee) {
    switch (tee.toLowerCase()) {
      case 'black':
        return Colors.white70;
      case 'blue':
        return AppColors.lakeCyan;
      case 'white':
        return Colors.white;
      case 'gold':
        return AppColors.duneSand;
      case 'red':
        return Colors.redAccent;
      default:
        return AppColors.lakeCyan;
    }
  }

  String _calculateAvgHcp(List<Player> players) {
    if (players.isEmpty) return '0.0';
    final total = players.fold<double>(0.0, (acc, p) => acc + p.handicapIndex);
    return (total / players.length).toStringAsFixed(1);
  }

  void _openPlayerEntry(BuildContext context, {Player? player}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerEntryScreen(
          playerRepository: playerRepository,
          player: player,
        ),
      ),
    );
  }

  Future<void> _showRestoreBackupDialog(BuildContext context) async {
    final info = await playerRepository.getBackupInfo();
    if (!context.mounted) return;

    if (!info.exists || info.count == 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No Backup Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          content: const Text(
            'No existing player roster backup was found yet.\n\nYou can load the sample 8 players or add golfers manually, and they will be automatically backed up.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await playerRepository.seedSample8Players();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.lakeCyan),
              child: const Text('Load 8 Arcadia Golfers', style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    final dateStr = info.timestamp != null ? DateFormat('MMM d, yyyy • h:mm a').format(info.timestamp!.toLocal()) : 'Recent';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield, color: AppColors.lakeCyan, size: 28),
            SizedBox(width: 8),
            Text('Restore Roster Backup', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Found backup of ${info.count} golfers',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Backed up: $dateStr',
              style: const TextStyle(fontSize: 14, color: AppColors.duneSand),
            ),
            const SizedBox(height: 12),
            const Text(
              'Golfers included:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: ListView(
                shrinkWrap: true,
                children: info.playerNames.map((name) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 16, color: AppColors.lakeCyan),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(name, style: const TextStyle(fontSize: 14, color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final restored = await playerRepository.restoreFromBackup();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF0F382A),
                    content: Text(
                      '✅ Restored $restored golfers from backup!',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lakeCyan,
              foregroundColor: const Color(0xFF04111D),
            ),
            child: const Text('Restore All', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportRosterDialog(BuildContext context) async {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Roster JSON', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste a previously exported roster JSON backup below:',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: textController,
              maxLines: 6,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Colors.white),
              decoration: const InputDecoration(
                hintText: '{\n  "players": [...]\n}',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              final raw = textController.text.trim();
              if (raw.isEmpty) return;
              Navigator.pop(ctx);
              final count = await playerRepository.importRosterFromJson(raw);
              if (context.mounted) {
                if (count > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF0F382A),
                      content: Text('✅ Successfully imported $count players!', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not parse roster JSON. Please check formatting.', style: TextStyle(fontSize: 16)),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.lakeCyan, foregroundColor: Colors.black),
            child: const Text('Import', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class GesturecastPlayerHeadshot extends StatelessWidget {
  final Player player;
  final ValueChanged<String?> onPhotoUpdated;

  const GesturecastPlayerHeadshot({
    super.key,
    required this.player,
    required this.onPhotoUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickImage(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PlayerAvatar(
            name: player.fullName,
            initials: player.initials,
            photoPath: player.photoPath,
            radius: 30,
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.lakeCyan,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardDark, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 13,
                color: Color(0xFF04111D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, color: AppColors.lakeCyan),
              title: const Text('Take Photo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.lakeCyan),
              title: const Text('Choose from Gallery', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (player.photoPath != null && player.photoPath!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Remove Photo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
          ],
        ),
      ),
    );

    if (action == null) return;

    if (action == 'remove') {
      onPhotoUpdated(null);
      return;
    }

    final source = action == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final ext = pickedFile.path.split('.').last;
      final fileName = 'player_${player.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      onPhotoUpdated(savedImage.path);
    }
  }
}
