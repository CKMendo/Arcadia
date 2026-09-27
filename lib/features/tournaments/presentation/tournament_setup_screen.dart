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
    _teamAController = TextEditingController(text: t?.teamAName ?? 'Team Lake');
    _teamBController = TextEditingController(text: t?.teamBName ?? 'Team Bluff');
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
      // Default: half to Team A, half to Team B
      final half = (players.length / 2).ceil();
      for (var i = 0; i < players.length; i++) {
        _playerTeams[players[i].id] = i < half ? 'a' : 'b';
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
          SnackBar(
            content: Text('Error saving trip: $e', style: const TextStyle(fontSize: 16)),
          ),
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
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TRIP OVERVIEW',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: AppColors.cyanLight,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              labelText: 'Trip / Event Name *',
                              labelStyle: TextStyle(fontSize: 17),
                              hintText: 'e.g. Arcadia Bluffs Cup 2026',
                              prefixIcon:
                                  Icon(Icons.emoji_events, color: AppColors.duneSand, size: 26),
                            ),
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: _selectDateRange,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cardBorder, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.date_range,
                                      color: AppColors.cyanLight, size: 28),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Dates',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.chevron_right,
                                      color: Colors.white54, size: 28),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Format Style',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'hybrid',
                                  label: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Text('Hybrid', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                ButtonSegment(
                                  value: 'teams',
                                  label: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Text('Teams', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                ButtonSegment(
                                  value: 'individual',
                                  label: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Text('Individual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                              selected: {_formatType},
                              onSelectionChanged: (set) {
                                setState(() => _formatType = set.first);
                              },
                            ),
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
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TEAM DESIGNATION',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: AppColors.cyanLight,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _teamAController,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                      labelText: 'Team A Name',
                                      labelStyle: TextStyle(fontSize: 16),
                                      prefixIcon: Icon(
                                        Icons.shield,
                                        color: AppColors.teamA,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: TextFormField(
                                    controller: _teamBController,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                      labelText: 'Team B Name',
                                      labelStyle: TextStyle(fontSize: 16),
                                      prefixIcon: Icon(
                                        Icons.shield,
                                        color: AppColors.teamB,
                                        size: 26,
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
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'PLAYER ROSTER & TEAMS',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: AppColors.cyanLight,
                                ),
                              ),
                              Text(
                                '${_allPlayers.length} Players',
                                style: const TextStyle(
                                  color: AppColors.duneSand,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (_allPlayers.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'No players found in roster. Add players in the Roster tab first.',
                                style: TextStyle(color: Colors.white54, fontSize: 16),
                              ),
                            )
                          else
                            ..._allPlayers.map((player) {
                              final currentTeam = _playerTeams[player.id] ?? 'none';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    PlayerAvatar(
                                      initials: player.initials,
                                      photoPath: player.photoPath,
                                      radius: 22,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            player.fullName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'HCP ${player.handicapIndex.toStringAsFixed(1)}',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
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
                                            label: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              child: Text(
                                                _teamAController.text.isNotEmpty
                                                    ? _teamAController.text.substring(0, 1).toUpperCase()
                                                    : 'A',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          ButtonSegment(
                                            value: 'b',
                                            label: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              child: Text(
                                                _teamBController.text.isNotEmpty
                                                    ? _teamBController.text.substring(0, 1).toUpperCase()
                                                    : 'B',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ],
                                        selected: {
                                          currentTeam == 'b' ? 'b' : 'a'
                                        },
                                        showSelectedIcon: false,
                                        style: ButtonStyle(
                                          visualDensity: VisualDensity.comfortable,
                                          tapTargetSize: MaterialTapTargetSize.padded,
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
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : Text(widget.tournament != null
                              ? 'Save Changes'
                              : 'Create Trip Event'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
