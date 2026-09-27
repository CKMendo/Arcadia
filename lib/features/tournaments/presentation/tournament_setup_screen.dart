import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/app_database.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/player_avatar.dart';
import '../../players/repository/player_repository.dart';
import '../repository/tournament_repository.dart';

class TournamentSetupScreen extends StatefulWidget {
  final TournamentRepository tournamentRepository;
  final PlayerRepository playerRepository;
  final Tournament? tournament;

  const TournamentSetupScreen({
    super.key,
    required this.tournamentRepository,
    required this.playerRepository,
    this.tournament,
  });

  @override
  State<TournamentSetupScreen> createState() => _TournamentSetupScreenState();
}

class _TournamentSetupScreenState extends State<TournamentSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _teamAController;
  late TextEditingController _teamBController;

  late DateTime _startDate;
  late DateTime _endDate;
  String _formatType = 'hybrid'; // 'hybrid', 'teams', 'individual'

  List<Player> _allPlayers = [];
  final Map<String, String> _playerTeams = {}; // playerId -> 'a', 'b', 'none'
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.tournament;
    _nameController = TextEditingController(
      text: t?.name ?? 'Arcadia Bluffs Trip 2026',
    );
    _teamAController = TextEditingController(text: t?.teamAName ?? 'Team Blue');
    _teamBController = TextEditingController(text: t?.teamBName ?? 'Team Red');
    _startDate = t != null
        ? DateTime.fromMillisecondsSinceEpoch(t.startDate)
        : DateTime.now();
    _endDate = t != null
        ? DateTime.fromMillisecondsSinceEpoch(t.endDate)
        : DateTime.now().add(const Duration(days: 4));
    _formatType = t?.formatType ?? 'hybrid';

    _loadData();
  }

  Future<void> _loadData() async {
    final players = await widget.playerRepository.getAllPlayers();
    if (widget.tournament != null) {
      final tPlayers = await widget.tournamentRepository
          .getTournamentPlayers(widget.tournament!.id);
      for (final tp in tPlayers) {
        _playerTeams[tp.player.id] = tp.teamId;
      }
    } else {
      // Default: 4 to Team A, 4 to Team B if 8 players
      for (var i = 0; i < players.length; i++) {
        _playerTeams[players[i].id] = i < 4 ? 'a' : 'b';
      }
    }

    setState(() {
      _allPlayers = players;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teamAController.dispose();
    _teamBController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final tournamentId = widget.tournament?.id ??
          await widget.tournamentRepository.createTournament(
            name: _nameController.text.trim(),
            startDate: _startDate,
            endDate: _endDate,
            formatType: _formatType,
            teamAName: _teamAController.text.trim(),
            teamBName: _teamBController.text.trim(),
            initialPlayerIds: _playerTeams.keys.toList(),
          );

      if (widget.tournament != null) {
        final updated = widget.tournament!.copyWith(
          name: _nameController.text.trim(),
          startDate: _startDate.millisecondsSinceEpoch,
          endDate: _endDate.millisecondsSinceEpoch,
          formatType: _formatType,
          teamAName: _teamAController.text.trim(),
          teamBName: _teamBController.text.trim(),
        );
        await widget.tournamentRepository.updateTournament(updated);
      }

      // Update player teams
      for (final entry in _playerTeams.entries) {
        await widget.tournamentRepository.updatePlayerTeam(
          tournamentId: tournamentId,
          playerId: entry.key,
          teamId: entry.value,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving trip: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tournament != null ? 'Edit Trip' : 'New Golf Trip'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TRIP OVERVIEW',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: AppColors.gold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Trip / Event Name *',
                              hintText: 'e.g. Arcadia Bluffs Cup 2026',
                              prefixIcon:
                                  Icon(Icons.emoji_events, color: AppColors.gold),
                            ),
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _selectDateRange,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF09241B),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.date_range,
                                      color: AppColors.goldLight),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Dates',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.chevron_right,
                                      color: Colors.white38),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Format Style',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'hybrid',
                                label: Text('Hybrid (Team + Skins)'),
                              ),
                              ButtonSegment(
                                value: 'teams',
                                label: Text('4v4 Teams'),
                              ),
                              ButtonSegment(
                                value: 'individual',
                                label: Text('Individual'),
                              ),
                            ],
                            selected: {_formatType},
                            onSelectionChanged: (set) {
                              setState(() => _formatType = set.first);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Teams Card (if hybrid or teams)
                  if (_formatType != 'individual') ...[
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TEAM DESIGNATION',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                color: AppColors.gold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _teamAController,
                                    decoration: InputDecoration(
                                      labelText: 'Team A Name',
                                      prefixIcon: const Icon(
                                        Icons.shield,
                                        color: AppColors.teamA,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _teamBController,
                                    decoration: InputDecoration(
                                      labelText: 'Team B Name',
                                      prefixIcon: const Icon(
                                        Icons.shield,
                                        color: AppColors.teamB,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Player Rostering Card
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'PLAYER ROSTER & TEAMS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                  color: AppColors.gold,
                                ),
                              ),
                              Text(
                                '${_allPlayers.length} Players',
                                style: const TextStyle(
                                  color: AppColors.goldLight,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_allPlayers.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No players found in roster. Add players in the Roster tab first.',
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          else
                            ..._allPlayers.map((player) {
                              final currentTeam = _playerTeams[player.id] ?? 'none';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF072118),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    PlayerAvatar(
                                      initials: player.initials,
                                      photoPath: player.photoPath,
                                      radius: 16,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            player.fullName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            'HCP ${player.handicapIndex.toStringAsFixed(1)}',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_formatType != 'individual') ...[
                                      SegmentedButton<String>(
                                        segments: [
                                          ButtonSegment(
                                            value: 'a',
                                            label: Text(
                                              _teamAController.text.isNotEmpty
                                                  ? _teamAController.text.substring(0, 1).toUpperCase()
                                                  : 'A',
                                            ),
                                          ),
                                          ButtonSegment(
                                            value: 'b',
                                            label: Text(
                                              _teamBController.text.isNotEmpty
                                                  ? _teamBController.text.substring(0, 1).toUpperCase()
                                                  : 'B',
                                            ),
                                          ),
                                        ],
                                        selected: {
                                          currentTeam == 'b' ? 'b' : 'a'
                                        },
                                        showSelectedIcon: false,
                                        style: ButtonStyle(
                                          visualDensity: VisualDensity.compact,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onSelectionChanged: (set) {
                                          setState(() {
                                            _playerTeams[player.id] = set.first;
                                          });
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.tournament != null
                            ? 'Save Changes'
                            : 'Create Trip Event'),
                  ),
                ],
              ),
            ),
    );
  }
}
