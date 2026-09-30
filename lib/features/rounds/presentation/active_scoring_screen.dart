import 'dart:async';
import 'package:flutter/material.dart';
import '../../../database/app_database.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/course_handicap_calculator.dart';
import '../../../shared/widgets/player_avatar.dart';
import '../../../shared/widgets/stat_badge.dart';
import '../../players/repository/player_repository.dart';
import '../import/presentation/round_scorecard_import_screen.dart';
import '../import/services/player_score_row_matcher.dart';
import '../models/active_round_session.dart';
import '../repository/round_repository.dart';
import 'round_summary_screen.dart';

class ActiveScoringScreen extends StatefulWidget {
  final RoundRepository roundRepository;
  final ActiveRoundSession session;
  final PlayerRepository? playerRepository;
  final bool initialGridView;

  const ActiveScoringScreen({
    super.key,
    required this.roundRepository,
    required this.session,
    this.playerRepository,
    this.initialGridView = true,
  });

  @override
  State<ActiveScoringScreen> createState() => _ActiveScoringScreenState();
}

class _ActiveScoringScreenState extends State<ActiveScoringScreen> {
  late int _currentHole;
  late bool _isGridView;
  StreamSubscription<List<Player>>? _playersSub;

  @override
  void initState() {
    super.initState();
    _currentHole = widget.session.currentHoleNumber;
    _isGridView = widget.initialGridView;

    if (widget.playerRepository != null) {
      _playersSub = widget.playerRepository!.watchAllPlayers().listen((players) {
        if (mounted && players.isNotEmpty) {
          final changed = widget.session.syncWithRoster(players);
          if (changed) {
            _saveDraft();
            setState(() {});
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _playersSub?.cancel();
    super.dispose();
  }

  void _saveDraft() {
    widget.session.currentHoleNumber = _currentHole;
    widget.roundRepository.saveActiveDraft(widget.session);
  }

  void _goToHole(int hole) {
    if (hole < 1 || hole > widget.session.holeCount) return;
    setState(() {
      _currentHole = hole;
    });
    _saveDraft();
  }

  void _adjustScore(String playerId, int holeNumber, int delta) {
    final current = widget.session.getGrossScore(playerId, holeNumber);
    final hole = widget.session.getHole(holeNumber);
    int nextScore;

    if (current <= 0) {
      nextScore = (hole.par + delta).clamp(1, 15);
    } else {
      nextScore = (current + delta).clamp(1, 15);
    }

    setState(() {
      widget.session.setGrossScore(playerId, holeNumber, nextScore);
    });
    _saveDraft();
  }

  void _setScoreDirect(String playerId, int holeNumber, int score) {
    setState(() {
      widget.session.setGrossScore(playerId, holeNumber, score);
    });
    _saveDraft();
  }

  void _exitRound() {
    _saveDraft();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Round draft saved. You can resume anytime from Options.', style: TextStyle(fontSize: 16)),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _deleteRound() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Delete Round?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this round? All entered scores for this round will be discarded.',
          style: TextStyle(fontSize: 18, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontSize: 17)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete Round', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await widget.roundRepository.clearActiveDraft();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _finalizeRound() async {
    final isLocked = widget.session.savedRoundId != null;
    final isComplete = widget.session.isRoundComplete;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          isLocked ? 'Save Changes & Lock Round?' : 'Finalize & Lock Round?',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Text(
          isComplete
              ? 'All ${widget.session.holeCount} holes completed! This will lock the round. You can unlock it anytime from Settings (gear icon).'
              : 'Some holes are not yet filled in. Are you sure you want to finalize and lock this round now?',
          style: const TextStyle(fontSize: 18, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing', style: TextStyle(fontSize: 17)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.lakeCyan, foregroundColor: const Color(0xFF06111D)),
            child: Text(
              isLocked ? 'Save & Lock' : 'Finalize Round',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final roundId = await widget.roundRepository.saveCompletedRound(widget.session);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RoundSummaryScreen(
              roundRepository: widget.roundRepository,
              roundId: roundId,
              playerRepository: widget.playerRepository,
            ),
          ),
        );
      }
    }
  }

  Future<void> _showEditPlayerDialog(PlayerSessionInfo player) async {
    final hcpCtrl = TextEditingController(text: player.handicapIndex.toStringAsFixed(1));
    String selectedTee = player.teeName;
    const teeOptions = ['Black', 'Blue', 'White', 'Gold', 'Red'];

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hcpVal = double.tryParse(hcpCtrl.text.trim()) ?? player.handicapIndex;
            final newCh = CourseHandicapCalculator.forCourse(
              courseName: widget.session.courseName,
              handicapIndex: hcpVal,
              tee: selectedTee,
            );

            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              title: Row(
                children: [
                  PlayerAvatar(name: player.name, initials: player.initials, radius: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Edit ${player.name}',
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TEE BOX SELECTION', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.cyanLight)),
                    const SizedBox(height: 8),
                    Builder(builder: (ctx) {
                      final effectiveTeeOptions = teeOptions.contains(selectedTee)
                          ? teeOptions
                          : [selectedTee, ...teeOptions];
                      return DropdownButtonFormField<String>(
                        key: ValueKey('scoring_tee_${player.playerId}_$selectedTee'),
                        initialValue: selectedTee,
                        dropdownColor: AppColors.surfaceElevated,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                        items: effectiveTeeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedTee = val);
                          }
                        },
                      );
                    }),
                    const SizedBox(height: 18),
                    const Text('HANDICAP INDEX', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.cyanLight)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: hcpCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white),
                      decoration: const InputDecoration(hintText: 'e.g. 8.7'),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C1F33),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.lakeCyan.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Calculated Course HCP:',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                          Text(
                            '$newCh',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.lakeCyan),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(fontSize: 17)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final hcp = double.tryParse(hcpCtrl.text.trim()) ?? player.handicapIndex;
                    setState(() {
                      widget.session.updatePlayerTeeAndHandicap(
                        playerId: player.playerId,
                        teeName: selectedTee,
                        handicapIndex: hcp,
                        newCourseHandicap: newCh,
                      );
                    });
                    _saveDraft();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Changes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showQuickScoreSheet(String playerId, String playerName, int holeNumber, int currentScore) {
    final hole = widget.session.getHole(holeNumber);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$playerName • Hole $holeNumber (Par ${hole.par})',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'TAP SCORE TO SET',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.cyanLight,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ...List.generate(9, (idx) {
                    final score = idx + 1;
                    final isSelected = score == currentScore;
                    final diff = score - hole.par;
                    Color btnColor = AppColors.surfaceElevated;
                    if (diff <= -2) {
                      btnColor = const Color(0xFF8B5CF6);
                    } else if (diff == -1) {
                      btnColor = AppColors.scoreBirdie;
                    } else if (diff == 0) {
                      btnColor = AppColors.scorePar;
                    } else if (diff == 1) {
                      btnColor = AppColors.scoreBogey;
                    } else if (diff >= 2) {
                      btnColor = AppColors.scoreDouble;
                    }

                    return InkWell(
                      onTap: () {
                        _setScoreDirect(playerId, holeNumber, score);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.lakeCyan : btnColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.white : AppColors.cardBorder,
                            width: isSelected ? 2.5 : 1.2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? const Color(0xFF06111D) : Colors.white,
                          ),
                        ),
                      ),
                    );
                  }),
                  // Clear button
                  InkWell(
                    onTap: () {
                      _setScoreDirect(playerId, holeNumber, 0);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6), width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showLiveLeaderboardSheet() {
    final players = widget.session.players;
    final sorted = List<PlayerSessionInfo>.from(players)
      ..sort((a, b) {
        final netA = widget.session.totalNet(a.playerId);
        final netB = widget.session.totalNet(b.playerId);
        return netA.compareTo(netB);
      });

    final skins = widget.session.playerSkinsWon(netSkins: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.70,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Live Leaderboard • ${widget.session.courseName}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 26),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.cardBorder),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: sorted.length,
                      itemBuilder: (context, idx) {
                        final p = sorted[idx];
                        final gross = widget.session.totalGross(p.playerId);
                        final net = widget.session.totalNet(p.playerId);
                        final pts = widget.session.effectivePlayerStableford(p.playerId);
                        final skinCount = skins[p.playerId] ?? 0;
                        final completed = widget.session.completedHolesCount(p.playerId);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: idx == 0
                                ? AppColors.lakeCyan.withValues(alpha: 0.15)
                                : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: idx == 0
                                  ? AppColors.lakeCyan
                                  : AppColors.cardBorder,
                              width: idx == 0 ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: idx == 0
                                      ? AppColors.lakeCyan
                                      : Colors.white70,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              PlayerAvatar(
                                name: p.name,
                                initials: p.initials,
                                radius: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.nickname,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      '$completed / ${widget.session.holeCount} Holes',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Net $net',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 22,
                                          color: AppColors.lakeCyan,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Gross $gross',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '$pts pts • $skinCount skins',
                                    style: const TextStyle(
                                      color: AppColors.duneSand,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openScorecardImport() async {
    final candidates = widget.session.players
        .map((p) => ImportPlayerCandidate(
              id: p.playerId,
              fullName: p.name,
              nickname: p.nickname,
              initials: p.initials,
            ))
        .toList();

    final parByHole = <int, int>{
      for (final h in widget.session.holes) h.holeNumber: h.par,
    };

    final result = await Navigator.of(context).push<RoundScorecardImportResult>(
      MaterialPageRoute(
        builder: (_) => RoundScorecardImportScreen(
          players: candidates,
          holeCount: widget.session.holeCount,
          parByHole: parByHole,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        for (final entry in result.scoresByPlayerId.entries) {
          final pid = entry.key;
          final scores = entry.value;
          for (var i = 0; i < scores.length; i++) {
            final s = scores[i];
            if (s != null) {
              widget.session.setGrossScore(pid, i + 1, s);
            }
          }
        }
      });
      _saveDraft();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Scores imported and applied to table grid!'),
          backgroundColor: Color(0xFF0F382A),
        ),
      );
    }
  }

  Future<void> _manualSyncRoster() async {
    if (widget.playerRepository == null) return;
    final players = await widget.playerRepository!.getAllPlayers();
    final changed = widget.session.syncWithRoster(players);
    if (changed) {
      _saveDraft();
      setState(() {});
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Round player names & handicaps synchronized with Roster!'),
          backgroundColor: Color(0xFF0F3224),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showAddPlayerFromRosterDialog() async {
    if (widget.playerRepository == null) return;
    final allPlayers = await widget.playerRepository!.getAllPlayers();
    final participatingIds = widget.session.players.map((p) => p.playerId).toSet();
    final available = allPlayers.where((p) => !participatingIds.contains(p.id)).toList();

    if (!mounted) return;

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All players in the roster are already in this round!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ADD GOLFER FROM ROSTER',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: AppColors.cyanLight,
                ),
              ),
              const SizedBox(height: 14),
              ...available.map((p) {
                return ListTile(
                  leading: PlayerAvatar(name: p.fullName, initials: p.initials, radius: 20),
                  title: Text(p.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                  subtitle: Text('Index: ${p.handicapIndex.toStringAsFixed(1)} • Preferred Tee: ${p.preferredTee ?? "White"}', style: const TextStyle(color: AppColors.duneSand)),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.lakeCyan, foregroundColor: const Color(0xFF04111D)),
                    onPressed: () {
                      final tee = p.preferredTee ?? 'White';
                      setState(() {
                        widget.session.addPlayerFromRoster(
                          p,
                          teeName: tee,
                          teeBoxId: tee.toLowerCase(),
                        );
                      });
                      _saveDraft();
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ Added "${p.fullName}" to this round!'),
                          backgroundColor: const Color(0xFF0F3224),
                        ),
                      );
                    },
                    child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditingLocked = widget.session.savedRoundId != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          tooltip: 'Exit Round',
          onPressed: _exitRound,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.session.courseName} • R${widget.session.roundNumber}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            if (isEditingLocked)
              const Text(
                'EDITING FINALIZED ROUND',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.duneSand),
              ),
          ],
        ),
        actions: [
          // View Switcher: Table/Grid vs Hole-by-Hole
          IconButton(
            icon: Icon(_isGridView ? Icons.view_day_outlined : Icons.table_chart_outlined, size: 28, color: AppColors.cyanLight),
            tooltip: _isGridView ? 'Switch to Hole-by-Hole View' : 'Switch to 8-Player Grid',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard, size: 28, color: AppColors.lakeCyan),
            tooltip: 'Live Leaderboard',
            onPressed: _showLiveLeaderboardSheet,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 28, color: Colors.white),
            onSelected: (val) {
              if (val == 'exit') {
                _exitRound();
              } else if (val == 'sync') {
                _manualSyncRoster();
              } else if (val == 'add_player') {
                _showAddPlayerFromRosterDialog();
              } else if (val == 'delete') {
                _deleteRound();
              } else if (val == 'finalize') {
                _finalizeRound();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [
                    Icon(Icons.sync, color: AppColors.lakeCyan, size: 22),
                    SizedBox(width: 10),
                    Text('Sync with Trip Roster', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              if (widget.playerRepository != null)
                const PopupMenuItem(
                  value: 'add_player',
                  child: Row(
                    children: [
                      Icon(Icons.person_add_alt_1, color: AppColors.cyanLight, size: 22),
                      SizedBox(width: 10),
                      Text('Add Golfer from Roster', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'exit',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: AppColors.cyanLight, size: 22),
                    SizedBox(width: 10),
                    Text('Exit Round (Keep Draft)', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'finalize',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.lakeCyan, size: 22),
                    SizedBox(width: 10),
                    Text('Finalize & Lock Round', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                    SizedBox(width: 10),
                    Text('Delete Round', style: TextStyle(fontSize: 16, color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.session.holeCount != 18)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF2E1065),
                border: Border(bottom: BorderSide(color: Color(0xFFA855F7), width: 1.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Color(0xFFD8B4FE), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⛳ SHORT COURSE (${widget.session.holeCount} HOLES) • BIRDIE POT ONLY • Excluded from Stableford standings',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF3E8FF),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Header Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0A1828),
              border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(_isGridView ? Icons.grid_on : Icons.golf_course, size: 18, color: AppColors.lakeCyan),
                    const SizedBox(width: 8),
                    Text(
                      _isGridView ? '8-PLAYER SCORING GRID (HOLES 1-${widget.session.holeCount})' : 'HOLE $_currentHole OF ${widget.session.holeCount}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        color: AppColors.cyanLight,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Tap any score to edit',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          // Main Scoring Content
          Expanded(
            child: _isGridView ? _buildScorecardGrid() : _buildHoleByHoleView(),
          ),

          // High-Visibility Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border(
                top: BorderSide(color: AppColors.cardBorder, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                // Exit Round Button
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _exitRound,
                    icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 20),
                    label: const Text(
                      'EXIT',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // OCR Scorecard Scan Button (Primary Entry)
                Expanded(
                  flex: 5,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2B3E),
                      foregroundColor: AppColors.lakeCyan,
                      side: const BorderSide(color: AppColors.lakeCyan, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _openScorecardImport,
                    icon: const Icon(Icons.document_scanner, size: 22),
                    label: const Text(
                      'OCR SCAN',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Finalize Round Button
                Expanded(
                  flex: 4,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lakeCyan,
                      foregroundColor: const Color(0xFF06111D),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _finalizeRound,
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: Text(
                      isEditingLocked ? 'SAVE' : 'FINALIZE',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 8-PLAYER TABLE / GRID FORMAT (ROWS = PLAYERS, COLUMNS = HOLES 1-18)
  // Large font design for +2.25 reading glasses
  // ===========================================================================
  Widget _buildScorecardGrid() {
    final players = widget.session.players;
    final holeCount = widget.session.holeCount;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sticky Left Column: Golfer Info & Tee / HCP Edit Button
          Container(
            width: 175,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.cardBorder, width: 2.0)),
              color: Color(0xFF0C1929),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Cell
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  alignment: Alignment.centerLeft,
                  decoration: const BoxDecoration(
                    color: Color(0xFF08121D),
                    border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1.5)),
                  ),
                  child: const Text(
                    'GOLFER',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: AppColors.cyanLight,
                    ),
                  ),
                ),

                // Player Row Headers
                ...players.map((p) {
                  return Container(
                    height: 68,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1.2)),
                    ),
                    child: Row(
                      children: [
                        PlayerAvatar(
                          name: p.name,
                          initials: p.initials,
                          radius: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                p.nickname,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              InkWell(
                                onTap: () => _showEditPlayerDialog(p),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.lakeCyan.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${p.teeName} • CH ${p.courseHandicap}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.lakeCyan,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.edit, size: 10, color: AppColors.lakeCyan),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // Horizontal Scrolling Columns: Holes 1..9, OUT, Holes 10..18, IN, TOT, NET, PTS
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Hole Numbers & Pars
                  Container(
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFF08121D),
                      border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1.5)),
                    ),
                    child: Row(
                      children: [
                        // Holes 1..9
                        for (var h = 1; h <= (holeCount >= 9 ? 9 : holeCount); h++)
                          _buildHoleHeaderCell(h),

                        // OUT Total Column
                        if (holeCount >= 9) _buildTotalHeaderCell('OUT', AppColors.cyanLight),

                        // Holes 10..18
                        for (var h = 10; h <= holeCount; h++)
                          _buildHoleHeaderCell(h),

                        // IN Total Column
                        if (holeCount >= 18) _buildTotalHeaderCell('IN', AppColors.cyanLight),

                        // TOT Column
                        _buildTotalHeaderCell('TOT', Colors.white),

                        // NET Column
                        _buildTotalHeaderCell('NET', AppColors.duneSand),

                        // PTS Column
                        _buildTotalHeaderCell('PTS', AppColors.lakeCyan),
                      ],
                    ),
                  ),

                  // Player Rows with Hole Scores
                  ...players.map((p) {
                    return Container(
                      height: 68,
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1.2)),
                      ),
                      child: Row(
                        children: [
                          // Holes 1..9
                          for (var h = 1; h <= (holeCount >= 9 ? 9 : holeCount); h++)
                            _buildScoreGridCell(p, h),

                          // OUT Total
                          if (holeCount >= 9)
                            _buildTotalValueCell(
                              value: widget.session.frontNineGross(p.playerId),
                              color: AppColors.cyanLight,
                            ),

                          // Holes 10..18
                          for (var h = 10; h <= holeCount; h++)
                            _buildScoreGridCell(p, h),

                          // IN Total
                          if (holeCount >= 18)
                            _buildTotalValueCell(
                              value: widget.session.backNineGross(p.playerId),
                              color: AppColors.cyanLight,
                            ),

                          // TOT (Gross)
                          _buildTotalValueCell(
                            value: widget.session.totalGross(p.playerId),
                            color: Colors.white,
                          ),

                          // NET
                          _buildTotalValueCell(
                            value: widget.session.totalNet(p.playerId),
                            color: AppColors.duneSand,
                          ),

                          // PTS (Stableford)
                          _buildTotalValueCell(
                            value: widget.session.effectivePlayerStableford(p.playerId),
                            color: AppColors.lakeCyan,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoleHeaderCell(int holeNumber) {
    final hole = widget.session.getHole(holeNumber);
    return Container(
      width: 58,
      height: 64,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.cardBorder, width: 1.0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$holeNumber',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          Text(
            'P${hole.par}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalHeaderCell(String label, Color color) {
    return Container(
      width: 66,
      height: 64,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF0F2236),
        border: Border(right: BorderSide(color: AppColors.cardBorder, width: 1.2)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildTotalValueCell({required int value, required Color color}) {
    return Container(
      width: 66,
      height: 68,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF0A1A2B),
        border: Border(right: BorderSide(color: AppColors.cardBorder, width: 1.2)),
      ),
      child: Text(
        value > 0 ? '$value' : '-',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: value > 0 ? color : Colors.white24,
        ),
      ),
    );
  }

  Widget _buildScoreGridCell(PlayerSessionInfo player, int holeNumber) {
    final gross = widget.session.getGrossScore(player.playerId, holeNumber);
    final hole = widget.session.getHole(holeNumber);
    final strokes = widget.session.strokesForPlayer(player.playerId, holeNumber);

    Color cellBg = const Color(0xFF0D1B2A);
    Color borderColor = AppColors.cardBorder;
    if (gross > 0) {
      final diff = gross - hole.par;
      if (diff <= -2) {
        cellBg = const Color(0xFF5B21B6);
        borderColor = const Color(0xFF8B5CF6);
      } else if (diff == -1) {
        cellBg = const Color(0xFF065F46);
        borderColor = const Color(0xFF10B981);
      } else if (diff == 0) {
        cellBg = const Color(0xFF162A45);
        borderColor = AppColors.lakeCyan.withValues(alpha: 0.6);
      } else if (diff == 1) {
        cellBg = const Color(0xFF78350F);
        borderColor = const Color(0xFFF59E0B);
      } else if (diff >= 2) {
        cellBg = const Color(0xFF7F1D1D);
        borderColor = const Color(0xFFEF4444);
      }
    }

    return InkWell(
      onTap: () => _showQuickScoreSheet(player.playerId, player.nickname, holeNumber, gross),
      child: Container(
        width: 58,
        height: 68,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: const Border(right: BorderSide(color: AppColors.cardBorder, width: 1.0)),
          color: const Color(0xFF081320),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: cellBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: gross > 0 ? 1.5 : 1.0),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Stroke dots in corner
              if (strokes > 0)
                Positioned(
                  top: 3,
                  right: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      strokes,
                      (_) => Container(
                        margin: const EdgeInsets.only(left: 2),
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.lakeCyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),

              // Large Score Display for +2.25 Reading Glasses
              Text(
                gross > 0 ? '$gross' : '-',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: gross > 0 ? Colors.white : Colors.white24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HOLE-BY-HOLE VIEW (WITHOUT SANDIES AND WITHOUT PUTTS)
  // Large font design for +2.25 reading glasses
  // ===========================================================================
  Widget _buildHoleByHoleView() {
    final currentHoleInfo = widget.session.getHole(_currentHole);

    return Column(
      children: [
        // Hole Navigation Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.appBarDark,
            border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 28),
                color: _currentHole > 1 ? AppColors.lakeCyan : Colors.white24,
                onPressed: _currentHole > 1 ? () => _goToHole(_currentHole - 1) : null,
              ),
              Column(
                children: [
                  Text(
                    'HOLE $_currentHole',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lakeCyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.lakeCyan, width: 1.5),
                        ),
                        child: Text(
                          'PAR ${currentHoleInfo.par}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.lakeCyan,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder, width: 1.5),
                        ),
                        child: Text(
                          'HCP ${currentHoleInfo.strokeIndex}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 28),
                color: _currentHole < widget.session.holeCount ? AppColors.lakeCyan : Colors.white24,
                onPressed: _currentHole < widget.session.holeCount ? () => _goToHole(_currentHole + 1) : null,
              ),
            ],
          ),
        ),

        // Golfer Cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            itemCount: widget.session.players.length,
            itemBuilder: (context, idx) {
              final player = widget.session.players[idx];
              final gross = widget.session.getGrossScore(player.playerId, _currentHole);
              final strokes = widget.session.strokesForPlayer(player.playerId, _currentHole);
              final isGreenie = widget.session.hasGreenie(player.playerId, _currentHole);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      PlayerAvatar(
                        name: player.name,
                        initials: player.initials,
                        radius: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    player.nickname,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 21,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (strokes > 0) ...[
                                  const SizedBox(width: 6),
                                  HandDots(count: strokes),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            InkWell(
                              onTap: () => _showEditPlayerDialog(player),
                              child: Text(
                                '${player.teeName} Tee • HCP ${player.courseHandicap} ✏️',
                                style: const TextStyle(
                                  color: AppColors.lakeCyan,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (currentHoleInfo.par == 3) ...[
                              const SizedBox(height: 6),
                              FilterChip(
                                label: const Text('Greenie 🎯', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                selected: isGreenie,
                                selectedColor: AppColors.lakeDeep,
                                onSelected: (sel) {
                                  setState(() {
                                    widget.session.toggleGreenie(player.playerId, _currentHole);
                                  });
                                  _saveDraft();
                                },
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Large Score Controls (+2.25 glasses friendly)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 38),
                            color: gross > 1 ? AppColors.lakeCyan : Colors.white24,
                            onPressed: () => _adjustScore(player.playerId, _currentHole, -1),
                          ),
                          InkWell(
                            onTap: () => _showQuickScoreSheet(player.playerId, player.nickname, _currentHole, gross),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 62,
                              height: 58,
                              decoration: BoxDecoration(
                                color: gross > 0 ? AppColors.lakeCyan : AppColors.backgroundDark,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: gross > 0 ? Colors.transparent : AppColors.cardBorder, width: 1.5),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                gross > 0 ? '$gross' : '-',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: gross > 0 ? const Color(0xFF06111D) : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 38),
                            color: AppColors.lakeCyan,
                            onPressed: () => _adjustScore(player.playerId, _currentHole, 1),
                          ),
                        ],
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
  }
}
