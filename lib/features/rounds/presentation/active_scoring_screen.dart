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
                '$playerName • Hole $_currentHole (Par ${hole.par})',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'TAP SCORE',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.cyanLight,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: List.generate(10, (idx) {
                  final score = idx + 1;
                  final isSelected = score == currentScore;
                  final diff = score - hole.par;
                  Color btnColor = AppColors.surfaceElevated;
                  if (diff <= -1) btnColor = AppColors.scoreBirdie;
                  if (diff == 0) btnColor = AppColors.scorePar;
                  if (diff == 1) btnColor = AppColors.scoreBogey;
                  if (diff >= 2) btnColor = AppColors.scoreDouble;

                  return InkWell(
                    onTap: () {
                      _setScoreDirect(playerId, score);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 64,
                      height: 64,
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
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? const Color(0xFF06111D) : Colors.white,
                        ),
                      ),
                    ),
                  );
                }),
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

  void _finishRound() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish & Save Round?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        content: Text(
          widget.session.isRoundComplete
              ? 'All ${widget.session.holeCount} holes completed! Would you like to finalize and view the official scorecard?'
              : 'Some holes are incomplete. Are you sure you want to finish and save this round now?',
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue Playing', style: TextStyle(fontSize: 17)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Finalize Round', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
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
        title: Text(
          '${widget.session.courseName} • R${widget.session.roundNumber}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard, size: 28, color: AppColors.lakeCyan),
            tooltip: 'Live Leaderboard',
            onPressed: _showLiveLeaderboardSheet,
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline, size: 28, color: AppColors.cyanLight),
            tooltip: 'Finish Round',
            onPressed: _finishRound,
          ),
        ],
      ),
      body: Column(
        children: [
          // Large High-Legibility Hole Navigation Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.appBarDark,
              border: Border(
                bottom: BorderSide(color: AppColors.cardBorder, width: 1.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 30),
                  color: _currentHole > 1 ? AppColors.lakeCyan : Colors.white24,
                  padding: const EdgeInsets.all(12),
                  onPressed: _currentHole > 1 ? () => _goToHole(_currentHole - 1) : null,
                ),
                Column(
                  children: [
                    Text(
                      'HOLE $_currentHole',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
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
                              color: AppColors.duneSand,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 30),
                  color: _currentHole < widget.session.holeCount
                      ? AppColors.lakeCyan
                      : Colors.white24,
                  padding: const EdgeInsets.all(12),
                  onPressed: _currentHole < widget.session.holeCount
                      ? () => _goToHole(_currentHole + 1)
                      : null,
                ),
              ],
            ),
          ),

          // Horizontal Hole Selector Bar with Large Touch Targets
          Container(
            height: 56,
            color: AppColors.appBarDark,
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
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w900 : FontWeight.w700,
                        color: isSelected ? const Color(0xFF06111D) : Colors.white,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.lakeCyan,
                    backgroundColor: isComplete
                        ? AppColors.lakeDeep.withValues(alpha: 0.3)
                        : AppColors.surfaceElevated,
                    side: BorderSide(
                      color: isSelected ? AppColors.lakeCyan : AppColors.cardBorder,
                      width: isSelected ? 2 : 1,
                    ),
                    onSelected: (sel) {
                      if (sel) _goToHole(holeNum);
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                );
              },
            ),
          ),

          // Live Birdie Pot Status Bar
          Builder(
            builder: (context) {
              final pot = widget.session.roundBirdiePot();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D1E16),
                  border: Border(bottom: BorderSide(color: Color(0xFF264734), width: 1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFD4AF37)),
                      ),
                      child: const Text('💰 BIRDIE POT', style: TextStyle(color: Color(0xFFE5C07B), fontWeight: FontWeight.w900, fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        pot.hasBirdies
                            ? '\$${pot.roundPotTotal.toStringAsFixed(0)} Pot • Last: H${pot.lastBirdieHole} (${pot.winnerNames.join(', ')})'
                            : 'No birdies yet (\$0 in pot) • \$2/birdie per player',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.session.isFinalRound)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.redAccent, width: 1),
                        ),
                        child: const Text('FINAL', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                  ],
                ),
              );
            },
          ),

          // Player Scoring Cards List with Big Touch Targets
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            PlayerAvatar(
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
                                            fontSize: 22,
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
                                  Text(
                                    '${player.teeName} Tee • HCP ${player.courseHandicap}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
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
                                  const SizedBox(height: 3),
                                  Text(
                                    '+$pts pts',
                                    style: const TextStyle(
                                      color: AppColors.duneSand,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                            ],
                            // +/- Quick Adjust Buttons & Huge Score Tap
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 36),
                                  color: gross > 1 ? AppColors.lakeCyan : Colors.white24,
                                  onPressed: () => _adjustScore(player.playerId, -1),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 46,
                                    minHeight: 46,
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _showQuickScoreSheet(
                                    player.playerId,
                                    player.nickname,
                                    gross,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 60,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: gross > 0
                                          ? AppColors.lakeCyan
                                          : AppColors.backgroundDark,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: gross > 0
                                            ? Colors.transparent
                                            : AppColors.cardBorder,
                                        width: 1.5,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      gross > 0 ? '$gross' : '-',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: gross > 0
                                            ? const Color(0xFF06111D)
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 36),
                                  color: AppColors.lakeCyan,
                                  onPressed: () => _adjustScore(player.playerId, 1),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 46,
                                    minHeight: 46,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Secondary Options: Putts & Bonuses (large and clear)
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // Putts
                            Text(
                              'Putts: $putts',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.remove, size: 22),
                              color: putts > 0 ? AppColors.lakeCyan : Colors.white24,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              onPressed: () => _adjustPutts(player.playerId, -1),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 22),
                              color: AppColors.lakeCyan,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              onPressed: () => _adjustPutts(player.playerId, 1),
                            ),
                            const Spacer(),
                            // Greenie toggle on Par 3s
                            if (currentHoleInfo.par == 3) ...[
                              FilterChip(
                                label: const Text('Greenie 🎯', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                selected: isGreenie,
                                selectedColor: AppColors.lakeDeep,
                                onSelected: (sel) {
                                  setState(() {
                                    widget.session.toggleGreenie(
                                      player.playerId,
                                      _currentHole,
                                    );
                                  });
                                  _saveDraft();
                                },
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              const SizedBox(width: 8),
                            ],
                            // Sandie toggle
                            FilterChip(
                              label: const Text('Sandie 🏖️', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              selected: isSandie,
                              selectedColor: AppColors.duneSand,
                              labelStyle: TextStyle(
                                color: isSandie ? const Color(0xFF06111D) : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              onSelected: (sel) {
                                setState(() {
                                  widget.session.toggleSandie(
                                    player.playerId,
                                    _currentHole,
                                  );
                                });
                                _saveDraft();
                              },
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
