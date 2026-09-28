import 'package:flutter/material.dart';
import '../../../database/app_database.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/player_avatar.dart';
import '../../rounds/models/active_round_session.dart';
import '../services/tournament_pairings_engine.dart';

class FinalRoundDraftScreen extends StatefulWidget {
  final List<Player> players;
  final List<ActiveRoundSession> pastRounds;
  final int roundNumber;
  final Function(RoundPairingPlan plan) onConfirmPlan;

  const FinalRoundDraftScreen({
    super.key,
    required this.players,
    required this.pastRounds,
    required this.roundNumber,
    required this.onConfirmPlan,
  });

  @override
  State<FinalRoundDraftScreen> createState() => _FinalRoundDraftScreenState();
}

class _FinalRoundDraftScreenState extends State<FinalRoundDraftScreen> {
  final TournamentPairingsEngine _engine = TournamentPairingsEngine();
  late List<PlayerStandingSeed> _rankings;
  late List<PlayerStandingSeed> _captains; // Seeds 1..4
  late List<PlayerStandingSeed> _pool; // Seeds 5..8

  // captainId -> selectedPartnerId
  final Map<String, String> _draftedPartners = {};

  @override
  void initState() {
    super.initState();
    _rankings = _engine.computeRankings(widget.players, widget.pastRounds);
    if (_rankings.length >= 8) {
      _captains = _rankings.sublist(0, 4);
      _pool = _rankings.sublist(4, 8);
      // Default initial auto-pair: 1->5, 2->6, 3->7, 4->8
      _autoDraft();
    } else {
      _captains = [];
      _pool = [];
    }
  }

  void _autoDraft() {
    setState(() {
      _draftedPartners.clear();
      for (var i = 0; i < 4; i++) {
        _draftedPartners[_captains[i].player.id] = _pool[i].player.id;
      }
    });
  }

  void _onSelectPartner(String captainId, String partnerId) {
    setState(() {
      // If another captain already selected this partner, swap
      String? otherCaptainId;
      for (final entry in _draftedPartners.entries) {
        if (entry.value == partnerId && entry.key != captainId) {
          otherCaptainId = entry.key;
          break;
        }
      }

      final prevPartnerId = _draftedPartners[captainId];
      _draftedPartners[captainId] = partnerId;

      if (otherCaptainId != null && prevPartnerId != null) {
        _draftedPartners[otherCaptainId] = prevPartnerId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_rankings.length < 8) {
      return Scaffold(
        appBar: AppBar(title: const Text('Final Round Draft')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              '8 players are required to run the Final Round Partner Selection Draft.',
              style: TextStyle(fontSize: 18, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final isFullyDrafted = _draftedPartners.length == 4 &&
        _draftedPartners.values.toSet().length == 4;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Final Round Draft'),
        actions: [
          TextButton.icon(
            onPressed: _autoDraft,
            icon: const Icon(Icons.bolt, color: AppColors.lakeCyan, size: 22),
            label: const Text('Auto-Draft', style: TextStyle(color: AppColors.lakeCyan, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner with Tournament Crest
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D251A), Color(0xFF06130D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.duneSand.withValues(alpha: 0.6), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.duneSand, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/images/arcadia_cup_crest.jpg', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FINAL ROUND SELECTION',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: AppColors.cyanLight,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '#1 picks first from bottom 4 (#5..#8). #2 picks next, etc.',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Modified Rules Notice
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MODIFIED STABLEFORD ACTIVE FOR FINAL ROUND',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.redAccent, letterSpacing: 0.8),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Double Bogey = -1 pt  •  Bogey = 0  •  Par = +1  •  Birdie = +2  •  Eagle = +3\nBad holes penalize your score, making partner selection critical!',
                        style: TextStyle(fontSize: 13, color: Colors.white, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'CAPTAIN PARTNER SELECTION',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: AppColors.cyanLight),
          ),
          const SizedBox(height: 12),

          // 4 Draft Match Cards
          ...List.generate(4, (idx) {
            final captainSeed = _captains[idx];
            final captain = captainSeed.player;
            final selectedPartnerId = _draftedPartners[captain.id];
            final partnerSeed = _pool.where((p) => p.player.id == selectedPartnerId).firstOrNull;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.duneSand.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'TEAM ${idx + 1} • PICK #${idx + 1}',
                          style: const TextStyle(color: AppColors.duneSand, fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ),
                      Text(
                        '${captainSeed.totalStablefordPoints + (partnerSeed?.totalStablefordPoints ?? 0)} Total Pts',
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Captain
                      Expanded(
                        child: Row(
                          children: [
                            PlayerAvatar(
                              initials: captain.initials,
                              photoPath: captain.photoPath,
                              radius: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '#${captainSeed.rank} ${captain.nickname.isNotEmpty ? captain.nickname : captain.fullName}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${captainSeed.totalStablefordPoints} pts • HCP ${captain.handicapIndex.toStringAsFixed(1)}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.duneSand),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('&', style: TextStyle(color: AppColors.lakeCyan, fontSize: 20, fontWeight: FontWeight.w900)),
                      ),
                      // Partner selector
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.lakeCyan.withValues(alpha: 0.7)),
                          ),
                          child: DropdownButton<String>(
                            value: selectedPartnerId,
                            isExpanded: true,
                            dropdownColor: AppColors.cardDark,
                            underline: const SizedBox.shrink(),
                            hint: const Text('Select Partner', style: TextStyle(color: Colors.white60, fontSize: 14)),
                            items: _pool.map((pSeed) {
                              final p = pSeed.player;
                              return DropdownMenuItem<String>(
                                value: p.id,
                                child: Text(
                                  '#${pSeed.rank} ${p.nickname.isNotEmpty ? p.nickname : p.fullName.split(' ').first} (${pSeed.totalStablefordPoints}p)',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (newId) {
                              if (newId != null) {
                                _onSelectPartner(captain.id, newId);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 10),
          // Confirm Button
          ElevatedButton.icon(
            onPressed: isFullyDrafted
                ? () {
                    final plan = _engine.generateFinalRoundPairings(
                      players: widget.players,
                      pastRounds: widget.pastRounds,
                      roundNumber: widget.roundNumber,
                      draftedPairs: _draftedPartners,
                    );
                    widget.onConfirmPlan(plan);
                    Navigator.pop(context, plan);
                  }
                : null,
            icon: const Icon(Icons.check_circle, size: 26),
            label: const Text(
              'Confirm Final Championship Teams',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.lakeCyan,
              foregroundColor: const Color(0xFF06111D),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
