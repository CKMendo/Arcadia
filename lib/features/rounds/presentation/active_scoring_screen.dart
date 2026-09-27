import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/player_avatar.dart';
import '../../../shared/widgets/stat_badge.dart';
import '../models/active_round_session.dart';
import '../repository/round_repository.dart';
import 'round_summary_screen.dart';

class ActiveScoringScreen extends StatefulWidget {
  final RoundRepository roundRepository;
  final ActiveRoundSession session;

  const ActiveScoringScreen({
    super.key,
    required this.roundRepository,
    required this.session,
  });

  @override
  State<ActiveScoringScreen> createState() => _ActiveScoringScreenState();
}

class _ActiveScoringScreenState extends State<ActiveScoringScreen> {
  late int _currentHole;

  @override
  void initState() {
    super.initState();
    _currentHole = widget.session.currentHoleNumber;
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

  void _adjustScore(String playerId, int delta) {
    final current = widget.session.getGrossScore(playerId, _currentHole);
    final hole = widget.session.getHole(_currentHole);
    int nextScore;

    if (current <= 0) {
      nextScore = (hole.par + delta).clamp(1, 15);
    } else {
      nextScore = (current + delta).clamp(1, 15);
    }

    setState(() {
      widget.session.setGrossScore(playerId, _currentHole, nextScore);
    });
    _saveDraft();
  }

  void _setScoreDirect(String playerId, int score) {
    setState(() {
      widget.session.setGrossScore(playerId, _currentHole, score);
    });
    _saveDraft();
  }

  void _adjustPutts(String playerId, int delta) {
    final current = widget.session.getPutts(playerId, _currentHole);
    final nextPutts = (current + delta).clamp(0, 6);
    setState(() {
      widget.session.setPutts(playerId, _currentHole, nextPutts);
    });
    _saveDraft();
  }

  void _showQuickScoreSheet(String playerId, String playerName, int currentScore) {
    final hole = widget.session.getHole(_currentHole);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Score for $playerName on Hole $_currentHole (Par ${hole.par})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.goldLight,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: List.generate(10, (idx) {
                  final score = idx + 1;
                  final isSelected = score == currentScore;
                  final diff = score - hole.par;
                  Color btnColor = AppColors.cardBorder;
                  if (diff <= -1) btnColor = AppColors.scoreBirdie;
                  if (diff == 0) btnColor = AppColors.scorePar;
                  if (diff == 1) btnColor = AppColors.scoreBogey;
                  if (diff >= 2) btnColor = AppColors.scoreDouble;

                  return InkWell(
                    onTap: () {
                      _setScoreDirect(playerId, score);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.gold : btnColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
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
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live Leaderboard (${widget.session.courseName})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.goldLight,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
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
                        final pts = widget.session.totalStableford(p.playerId);
                        final skinCount = skins[p.playerId] ?? 0;
                        final completed = widget.session.completedHolesCount(p.playerId);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: idx == 0
                                ? AppColors.gold.withValues(alpha: 0.15)
                                : const Color(0xFF09241B),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: idx == 0
                                  ? AppColors.gold
                                  : AppColors.cardBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: idx == 0
                                      ? AppColors.gold
                                      : Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              PlayerAvatar(
                                initials: p.initials,
                                radius: 16,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.nickname,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      '$completed / ${widget.session.holeCount} Holes Played',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
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
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppColors.goldLight,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Gross $gross',
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '$pts pts • $skinCount skins',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
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

  void _finishRound() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish & Save Round?'),
        content: Text(
          widget.session.isRoundComplete
              ? 'All ${widget.session.holeCount} holes completed! Would you like to finalize and view the official scorecard?'
              : 'Some holes are incomplete. Are you sure you want to finish and save this round now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue Playing'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Finalize Round'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final roundId = await widget.roundRepository.saveCompletedRound(widget.session);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RoundSummaryScreen(
              roundRepository: widget.roundRepository,
              roundId: roundId,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentHoleInfo = widget.session.getHole(_currentHole);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.session.courseName} • R${widget.session.roundNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard, color: AppColors.gold),
            tooltip: 'Live Leaderboard',
            onPressed: _showLiveLeaderboardSheet,
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: AppColors.goldLight),
            tooltip: 'Finish Round',
            onPressed: _finishRound,
          ),
        ],
      ),
      body: Column(
        children: [
          // Hole Navigation Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.darkGreen,
              border: Border(
                bottom: BorderSide(color: AppColors.cardBorder),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  color: _currentHole > 1 ? AppColors.gold : Colors.white24,
                  onPressed: _currentHole > 1 ? () => _goToHole(_currentHole - 1) : null,
                ),
                Column(
                  children: [
                    Text(
                      'HOLE $_currentHole',
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.goldLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.sageGreen.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PAR ${currentHoleInfo.par}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.cardBorder,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'HCP ${currentHoleInfo.strokeIndex}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.goldLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 20),
                  color: _currentHole < widget.session.holeCount
                      ? AppColors.gold
                      : Colors.white24,
                  onPressed: _currentHole < widget.session.holeCount
                      ? () => _goToHole(_currentHole + 1)
                      : null,
                ),
              ],
            ),
          ),

          // Horizontal Hole Selector Bar
          Container(
            height: 48,
            color: const Color(0xFF061812),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              itemCount: widget.session.holeCount,
              itemBuilder: (context, idx) {
                final holeNum = idx + 1;
                final isSelected = holeNum == _currentHole;
                final isComplete = widget.session.isHoleComplete(holeNum);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(
                      '$holeNum${isComplete ? ' ✓' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.black : Colors.white,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.gold,
                    backgroundColor: isComplete
                        ? AppColors.sageGreen.withValues(alpha: 0.4)
                        : AppColors.cardDark,
                    onSelected: (sel) {
                      if (sel) _goToHole(holeNum);
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              },
            ),
          ),

          // Player Scoring Cards List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              itemCount: widget.session.players.length,
              itemBuilder: (context, idx) {
                final player = widget.session.players[idx];
                final gross = widget.session.getGrossScore(player.playerId, _currentHole);
                final strokes = widget.session.strokesForPlayer(player.playerId, _currentHole);
                final net = widget.session.netScoreForPlayer(player.playerId, _currentHole);
                final pts = widget.session.stablefordForPlayer(player.playerId, _currentHole);
                final putts = widget.session.getPutts(player.playerId, _currentHole);
                final isGreenie = widget.session.hasGreenie(player.playerId, _currentHole);
                final isSandie = widget.session.hasSandie(player.playerId, _currentHole);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            PlayerAvatar(
                              initials: player.initials,
                              radius: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        player.nickname,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (strokes > 0) ...[
                                        const SizedBox(width: 6),
                                        HandDots(count: strokes),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    '${player.teeName} Tee • Course HCP ${player.courseHandicap}',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Score Indicator / Pill
                            if (gross > 0 && net != null) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  ScoreBadge(
                                    score: net,
                                    par: currentHoleInfo.par,
                                    isNet: true,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '+$pts pts',
                                    style: const TextStyle(
                                      color: AppColors.goldLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                            ],
                            // +/- Quick Adjust Buttons & Big Score Tap
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: gross > 1 ? Colors.white70 : Colors.white24,
                                  onPressed: () => _adjustScore(player.playerId, -1),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _showQuickScoreSheet(
                                    player.playerId,
                                    player.nickname,
                                    gross,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: gross > 0
                                          ? AppColors.gold
                                          : const Color(0xFF061812),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: gross > 0
                                            ? Colors.transparent
                                            : AppColors.cardBorder,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      gross > 0 ? '$gross' : '-',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: gross > 0
                                            ? Colors.black
                                            : Colors.white38,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: Colors.white70,
                                  onPressed: () => _adjustScore(player.playerId, 1),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Secondary Options: Putts & Bonuses (Greenie on par 3, Sandie)
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Putts
                            Text(
                              'Putts: $putts',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove, size: 14),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              onPressed: () => _adjustPutts(player.playerId, -1),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 14),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              onPressed: () => _adjustPutts(player.playerId, 1),
                            ),
                            const Spacer(),
                            // Greenie toggle on Par 3s
                            if (currentHoleInfo.par == 3) ...[
                              FilterChip(
                                label: const Text('Greenie 🎯', style: TextStyle(fontSize: 11)),
                                selected: isGreenie,
                                selectedColor: AppColors.sageGreen,
                                onSelected: (sel) {
                                  setState(() {
                                    widget.session.toggleGreenie(
                                      player.playerId,
                                      _currentHole,
                                    );
                                  });
                                  _saveDraft();
                                },
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                              const SizedBox(width: 6),
                            ],
                            // Sandie toggle
                            FilterChip(
                              label: const Text('Sandie 🏖️', style: TextStyle(fontSize: 11)),
                              selected: isSandie,
                              selectedColor: AppColors.warmSand,
                              onSelected: (sel) {
                                setState(() {
                                  widget.session.toggleSandie(
                                    player.playerId,
                                    _currentHole,
                                  );
                                });
                                _saveDraft();
                              },
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
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
      ),
    );
  }
}
