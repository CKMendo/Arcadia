import 'package:flutter/material.dart';
import '../../../database/app_database.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/player_avatar.dart';
import '../repository/player_repository.dart';
import 'player_edit_screen.dart';

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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.cyanLight, size: 28),
            onSelected: (value) async {
              if (value == 'seed') {
                await playerRepository.seedSample8Players();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sample 8 players loaded', style: TextStyle(fontSize: 17))),
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
              child: Padding(
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
                      'Add the 8 guys going on the trip, or tap below to seed sample players for quick testing.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 18, height: 1.4),
                    ),
                    const SizedBox(height: 26),
                    ElevatedButton.icon(
                      onPressed: () => _openPlayerEditor(context),
                      icon: const Icon(Icons.person_add, size: 26),
                      label: const Text('Add First Player', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await playerRepository.seedSample8Players();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sample 8 players added!', style: TextStyle(fontSize: 17))),
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

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.appBarDark,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Text(
                      'Avg Index: ${_calculateAvgHcp(players)}',
                      style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
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
                          horizontal: 16,
                          vertical: 10,
                        ),
                        leading: PlayerAvatar(
                          initials: p.initials,
                          photoPath: p.photoPath,
                          radius: 26,
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                p.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.cardBorder),
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
                              if (p.preferredTee != null && p.preferredTee!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.lakeDeep.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.lakeCyan.withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    '${p.preferredTee} Tee',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              if (p.ghinNumber != null && p.ghinNumber!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3.0),
                                  child: Text(
                                    'GHIN: ${p.ghinNumber}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 26, color: AppColors.lakeCyan),
                          onPressed: () => _openPlayerEditor(context, player: p),
                        ),
                        onTap: () => _openPlayerEditor(context, player: p),
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
        onPressed: () => _openPlayerEditor(context),
        backgroundColor: AppColors.lakeCyan,
        foregroundColor: const Color(0xFF06111D),
        icon: const Icon(Icons.add, size: 28),
        label: const Text('Add Player', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
      ),
    );
  }

  String _calculateAvgHcp(List<Player> players) {
    if (players.isEmpty) return '0.0';
    final total = players.fold(0.0, (sum, p) => sum + p.handicapIndex);
    return (total / players.length).toStringAsFixed(1);
  }

  void _openPlayerEditor(BuildContext context, {Player? player}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerEditScreen(
          playerRepository: playerRepository,
          player: player,
        ),
      ),
    );
  }
}
