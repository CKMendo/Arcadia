import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../database/app_database.dart';
import '../../../shared/theme/app_colors.dart';
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
              if (value == 'seed') {
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
                    content: const Text('This will remove all players from the roster.', style: TextStyle(fontSize: 18)),
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
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/arcadia_cup_crest.jpg',
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
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$photoCount photos added • ${players.length - photoCount} spaces reserved',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
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
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        // Reserved Headshot Space
                        leading: Tooltip(
                          message: p.photoPath != null ? 'Tap to change photo' : 'Headshot space (Tap to add photo)',
                          child: PlayerAvatar(
                            initials: p.initials,
                            photoPath: p.photoPath,
                            radius: 28,
                            isHeadshotSpace: true,
                            showBadge: true,
                            badgeIcon: p.photoPath != null ? Icons.check : Icons.camera_alt,
                            onTap: () => _updatePlayerPhoto(context, p),
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                p.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 21,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (p.nickname.isNotEmpty && p.nickname != p.fullName) ...[
                              const SizedBox(width: 8),
                              Text(
                                '"${p.nickname}"',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.duneSand,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // HANDICAP Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.lakeCyan.withValues(alpha: 0.6)),
                                    ),
                                    child: Text(
                                      'HCP ${p.handicapIndex.toStringAsFixed(1)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.lakeCyan,
                                      ),
                                    ),
                                  ),

                                  // PHONE NUMBER Badge
                                  if (p.phoneNumber != null && p.phoneNumber!.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F2B3E),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.cardBorder),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.phone, size: 14, color: AppColors.cyanLight),
                                          const SizedBox(width: 6),
                                          Text(
                                            p.phoneNumber!,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Preferred Tee
                                  if (p.preferredTee != null && p.preferredTee!.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.lakeDeep.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.cardBorder),
                                      ),
                                      child: Text(
                                        '${p.preferredTee} Tee',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Headshot hint
                              Text(
                                p.photoPath != null && p.photoPath!.isNotEmpty
                                    ? 'Headshot attached'
                                    : 'Headshot space reserved • Tap photo to fill in',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: p.photoPath != null ? AppColors.cyanLight : AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 26, color: AppColors.lakeCyan),
                          tooltip: 'Edit Player Details',
                          onPressed: () => _openPlayerEntry(context, player: p),
                        ),
                        onTap: () => _openPlayerEntry(context, player: p),
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
        foregroundColor: const Color(0xFF06111D),
        icon: const Icon(Icons.person_add, size: 28),
        label: const Text('Add Player', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
      ),
    );
  }

  String _calculateAvgHcp(List<Player> players) {
    if (players.isEmpty) return '0.0';
    final total = players.fold(0.0, (sum, p) => sum + p.handicapIndex);
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

  Future<void> _updatePlayerPhoto(BuildContext context, Player p) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Headshot for ${p.fullName}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose a photo to fill in this headshot space:',
                style: TextStyle(fontSize: 15, color: Colors.white70),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.lakeCyan, size: 26),
                title: const Text('Choose from Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);
                  if (picked != null) {
                    final appDir = await getApplicationDocumentsDirectory();
                    final fileName = 'player_${p.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                    final savedFile = await File(picked.path).copy('${appDir.path}/$fileName');
                    await playerRepository.updatePlayerPhoto(p.id, savedFile.path);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.lakeCyan, size: 26),
                title: const Text('Take Photo with Camera', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 800, maxHeight: 800, imageQuality: 85);
                  if (picked != null) {
                    final appDir = await getApplicationDocumentsDirectory();
                    final fileName = 'player_${p.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                    final savedFile = await File(picked.path).copy('${appDir.path}/$fileName');
                    await playerRepository.updatePlayerPhoto(p.id, savedFile.path);
                  }
                },
              ),
              if (p.photoPath != null && p.photoPath!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 26),
                  title: const Text('Remove Photo (Leave Space)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await playerRepository.updatePlayerPhoto(p.id, null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
