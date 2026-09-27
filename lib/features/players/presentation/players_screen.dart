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
            icon: const Icon(Icons.more_vert, color: AppColors.goldLight),
            onSelected: (value) async {
              if (value == 'seed') {
                await playerRepository.seedSample8Players();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sample 8 players loaded')),
                  );
                }
              } else if (value == 'clear') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Roster?'),
                    content: const Text('This will remove all players from the roster.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Clear All'),
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
                    Icon(Icons.group_add, color: AppColors.gold, size: 20),
                    SizedBox(width: 8),
                    Text('Load Sample 8 Players'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    SizedBox(width: 8),
                    Text('Clear Roster'),
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
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cardBorder, width: 2),
                      ),
                      child: const Icon(
                        Icons.group_outlined,
                        size: 56,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Players Added Yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add the 8 guys going on the trip, or tap below to seed sample players for quick testing.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _openPlayerEditor(context),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add First Player'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await playerRepository.seedSample8Players();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sample 8 players added!')),
                          );
                        }
                      },
                      icon: const Icon(Icons.bolt, color: AppColors.gold),
                      label: const Text('Load Sample 8 Players'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.darkGreen.withValues(alpha: 0.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ROSTER (${players.length} / 8 PLAYERS)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.gold,
                      ),
                    ),
                    Text(
                      'Avg Index: ${_calculateAvgHcp(players)}',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final p = players[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        leading: PlayerAvatar(
                          initials: p.initials,
                          photoPath: p.photoPath,
                          radius: 22,
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                p.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (p.nickname.isNotEmpty && p.nickname != p.fullName) ...[
                              const SizedBox(width: 6),
                              Text(
                                '"${p.nickname}"',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.goldLight,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBorder,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'HCP ${p.handicapIndex.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.goldLight,
                                  ),
                                ),
                              ),
                              if (p.preferredTee != null && p.preferredTee!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.sageGreen.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${p.preferredTee} Tee',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              if (p.ghinNumber != null && p.ghinNumber!.isNotEmpty)
                                Text(
                                  'GHIN: ${p.ghinNumber}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white38,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white70),
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
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add Player', style: TextStyle(fontWeight: FontWeight.bold)),
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
