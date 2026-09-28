import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../database/app_database.dart';
import '../../../shared/services/device_communication_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../players/repository/player_repository.dart';

class RulesScreen extends StatelessWidget {
  final PlayerRepository? playerRepository;

  const RulesScreen({super.key, this.playerRepository});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Rules'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.cyanLight, size: 24),
            tooltip: 'Share Rules to Players / Group',
            onPressed: () => _openShareRulesDialog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // Prominent Button at Top: Share Rules to Players / Entire Group
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.sms_outlined, size: 20, color: Color(0xFF04110A)),
              label: const Text(
                'SHARE RULES TO PLAYERS / GROUP',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF04110A),
                  fontSize: 13.5,
                  letterSpacing: 0.8,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyanLight,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _openShareRulesDialog(context),
            ),
          ),

          // Crest & Tournament Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F241B), Color(0xFF06130D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.duneSand.withValues(alpha: 0.7), width: 1.6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.duneSand, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.duneSand.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/arcadia_cup_crest.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ARCADIA CUP',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                          color: AppColors.cyanLight,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Official Tournament & Betting Format',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.duneSand,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '8-Player Roster • 2-Man Best Ball • Partner Draft',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Quick Navigation Pills
          const Text(
            'OFFICIAL TOURNAMENT RULES',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: AppColors.cyanLight,
            ),
          ),
          const SizedBox(height: 12),

          // RULE 1: AI Balanced 4-somes
          _buildRuleCard(
            number: '1',
            title: 'AI 4-somes & Partner Rotation',
            badge: 'EQUAL PLAYING TIME',
            badgeColor: AppColors.lakeCyan,
            icon: Icons.groups,
            children: [
              const Text(
                'The 8 golfers are split into two 4-somes for every round. An AI optimization engine tracks group history to ensure every player spends equal time playing with all 7 other golfers over the trip.',
                style: TextStyle(fontSize: 15, color: Colors.white, height: 1.4),
              ),
              const SizedBox(height: 10),
              _buildBullet(
                'Maximizes Randomness & Variety',
                'Pairing schedules are generated algorithmically to prevent repeat foursomes while keeping matches exciting and fresh.',
              ),
              _buildBullet(
                'Equal Rotation Across Trip',
                'By the end of preliminary play, every golfer will have shared a 4-some with every single participant.',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // RULE 2: 2-Man Stableford
          _buildRuleCard(
            number: '2',
            title: '2-Man Best Ball Stableford',
            badge: 'NET ADJUSTED',
            badgeColor: AppColors.duneSand,
            icon: Icons.sports_golf,
            children: [
              const Text(
                'Within each 4-some, an AI-randomized 2-man team is determined. That 2-man team plays a Stableford scoring system on a net-adjusted basis (handicap strokes received per hole).',
                style: TextStyle(fontSize: 15, color: Colors.white, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text(
                'Standard Stableford Point Scale (Rounds 1 to N-1):',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.duneSand),
              ),
              const SizedBox(height: 8),
              _buildPointsTable([
                const PointsRow('Double Eagle / Albatross', '3 under net', '+5 pts'),
                const PointsRow('Eagle', '2 under net', '+4 pts'),
                const PointsRow('Birdie', '1 under net', '+3 pts'),
                const PointsRow('Par', 'Even net', '+2 pts'),
                const PointsRow('Bogey', '1 over net', '+1 pt'),
                const PointsRow('Double Bogey or worse', '2+ over net', '0 pts (Max 0)'),
              ]),
              const SizedBox(height: 10),
              _buildBullet(
                '2-Man Best Ball on Every Hole',
                'The team score on each hole is the higher of the two teammates\' Stableford points (max of Player A and Player B).',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // RULE 3: End of Round Player Record
          _buildRuleCard(
            number: '3',
            title: 'End of Round Team Score Recording',
            badge: 'EQUAL TEAM CREDIT',
            badgeColor: AppColors.cyanLight,
            icon: Icons.military_tech,
            children: [
              const Text(
                'At the end of the round, each player on the 2-man team is credited with the team\'s total Stableford points for their individual tournament standing.',
                style: TextStyle(fontSize: 15, color: Colors.white, height: 1.4),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.lakeCyan.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.lakeCyan, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Example: If a team shoots well and posts 45 points, each of the 2 players records a 45 on their individual trip leaderboard.',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // RULE 4: Final Round Draft
          _buildRuleCard(
            number: '4',
            title: 'Final Round Partner Selection Draft',
            badge: 'SEEDS #1–#8 DRAFT',
            badgeColor: AppColors.duneSand,
            icon: Icons.how_to_reg,
            children: [
              const Text(
                'Entering the final championship round, cumulative Stableford points are tallied and all 8 golfers are ranked from #1 through #8.',
                style: TextStyle(fontSize: 15, color: Colors.white, height: 1.4),
              ),
              const SizedBox(height: 10),
              const Text(
                'The Selection Draft Order:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.duneSand),
              ),
              const SizedBox(height: 8),
              _buildDraftStep('1', '#1 Captain picks first', 'Can choose anyone from #5, #6, #7, or #8.'),
              _buildDraftStep('2', '#2 Captain picks next', 'Chooses from the remaining 3 players in the draft pool.'),
              _buildDraftStep('3', '#3 Captain picks next', 'Chooses from the remaining 2 players in the draft pool.'),
              _buildDraftStep('4', '#4 Captain is paired', 'Paired with the last remaining player from the draft pool.'),
              const SizedBox(height: 10),
              _buildBullet(
                'Championship Matches',
                'Team 1 vs Team 4 face off in Foursome 1, and Team 2 vs Team 3 face off in Foursome 2.',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // RULE 5: Modified Stableford in Final Round
          _buildRuleCard(
            number: '5',
            title: 'Final Round Modified Stableford',
            badge: 'PENALTY SCORING',
            badgeColor: Colors.redAccent,
            icon: Icons.warning_amber_rounded,
            children: [
              const Text(
                'For the final round, the scoring system shifts to Modified Stableford to penalize bad play and place maximum importance on partner chemistry and clutch shots.',
                style: TextStyle(fontSize: 15, color: Colors.white, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text(
                'Final Round Modified Point Scale:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.redAccent),
              ),
              const SizedBox(height: 8),
              _buildPointsTable([
                const PointsRow('Double Eagle / Albatross', '3 under net', '+4 pts'),
                const PointsRow('Eagle', '2 under net', '+3 pts'),
                const PointsRow('Birdie', '1 under net', '+2 pts'),
                const PointsRow('Par', 'Even net', '+1 pt'),
                const PointsRow('Bogey', '1 over net', '0 pts'),
                const PointsRow('Double Bogey or worse', '2+ over net', '-1 pt (Penalty!)', isNegative: true),
              ]),
              const SizedBox(height: 10),
              _buildBullet(
                'Negative Points for Bad Holes',
                'Double bogeys actively subtract 1 point from your total, adding intense pressure down the stretch!',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // RULE 6: Champion Determination
          _buildRuleCard(
            number: '6',
            title: 'Arcadia Cup Champion Determination',
            badge: 'TOURNAMENT TROPHY',
            badgeColor: AppColors.duneSand,
            icon: Icons.emoji_events,
            children: [
              const Text(
                'After all rounds are entered, the player with the highest cumulative Stableford points across all rounds of the trip is crowned the Arcadia Cup Champion.',
                style: TextStyle(fontSize: 15, color: Colors.white, height: 1.4),
              ),
              const SizedBox(height: 10),
              _buildBullet(
                'Tiebreaker Protocol',
                'In case of a tie for 1st place: 1) Final round score, 2) Back-9 score of final round, 3) Lower handicap index.',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // THE BIRDIE POT BETTING GAME
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E2206), Color(0xFF130E02)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5C07B), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE5C07B).withValues(alpha: 0.15),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5C07B).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5C07B)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.monetization_on, color: Color(0xFFE5C07B), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'BETTING PURSE',
                            style: TextStyle(
                              color: Color(0xFFE5C07B),
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      '\$2.00 / Birdie',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFF7D98C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'THE BIRDIE POT GAME',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: Color(0xFFF7D98C),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Every birdie recorded creates cash in both the Round Pot and the Trip Cumulative Pot.',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 14),

                _buildPotRule(
                  title: '1. The \$2.00 Per Birdie Entry',
                  text: 'For EVERY birdie made in that round across all 8 golfers, EVERY player contributes \$2.00.',
                ),
                _buildPotRule(
                  title: '2. The 50/50 Pot Split',
                  text: '• \$1.00 goes directly to that Round\'s Pot.\n• \$1.00 goes to the Trip Cumulative Pot.',
                ),
                _buildPotRule(
                  title: '3. Last Birdie Wins the Round Pot!',
                  text: 'THE LAST BIRDIE MADE FOR THAT ROUND WINS THE ROUND POT!\nThe player who makes a birdie on the latest hole of that round takes the entire round pot.',
                ),
                _buildPotRule(
                  title: '4. Last Birdie of Trip Wins Cumulative Pot!',
                  text: 'THE LAST BIRDIE MADE AT THE END OF THE TRIP WINS THE ENTIRE CUMULATIVE POT!\nUsually decided on the final holes of the final round.',
                ),
                _buildPotRule(
                  title: '5. Tie Splitting on the Last Hole',
                  text: 'If 2 or more golfers make a birdie on that last birdie hole, the pot is divided equally among those players.',
                ),
                const SizedBox(height: 10),

                // Example Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5C07B).withValues(alpha: 0.4)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💡 EXAMPLE CALCULATION:',
                        style: TextStyle(color: Color(0xFFE5C07B), fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• 5 birdies made in Round 1.\n• Each player owes: 5 × \$2 = \$10 (Total collected = \$80).\n• Round 1 Pot: \$40 (Won by golfer with last birdie).\n• Cumulative Pot Contribution: +\$40.\n• Across 4 rounds with 20 total birdies: Cumulative Pot reaches \$160 for the final trip winner!',
                        style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildRuleCard({
    required String number,
    required String title,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.lakeCyan,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: const TextStyle(color: Color(0xFF06111D), fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: badgeColor.withValues(alpha: 0.6)),
            ),
            child: Text(
              badge,
              style: TextStyle(color: badgeColor, fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildBullet(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.lakeCyan, fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.3),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftStep(String step, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.duneSand),
            ),
            alignment: Alignment.center,
            child: Text(step, style: const TextStyle(color: AppColors.duneSand, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.white70),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPotRule({required String title, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFF7D98C)),
          ),
          const SizedBox(height: 2),
          Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsTable(List<PointsRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: rows.map((r) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 3,
                  child: Text(r.scoreName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(r.netRelation, style: const TextStyle(fontSize: 13, color: Colors.white60)),
                ),
                Text(
                  r.points,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: r.isNegative ? Colors.redAccent : AppColors.cyanLight,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _openShareRulesDialog(BuildContext context) async {
    List<Player> players = [];
    if (playerRepository != null) {
      players = await playerRepository!.getAllPlayers();
      if (players.isEmpty) {
        await playerRepository!.seedSample8Players();
        players = await playerRepository!.getAllPlayers();
      }
    }

    if (!context.mounted) return;

    if (players.isEmpty) {
      Share.share(
        _officialRulesSummaryText,
        subject: '🏌️ Arcadia Cup 2026 – Official Tournament Rules',
      );
      return;
    }

    final selectedIds = players.map((p) => p.id).toSet();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final allSelected = selectedIds.length == players.length;
          final selectedPlayers = players.where((p) => selectedIds.contains(p.id)).toList();
          final validPhoneCount = selectedPlayers
              .where((p) => p.phoneNumber != null && p.phoneNumber!.trim().isNotEmpty)
              .length;

          return AlertDialog(
            backgroundColor: const Color(0xFF071520),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: AppColors.lakeCyan.withValues(alpha: 0.7), width: 1.5),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.lakeCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.share, color: AppColors.lakeCyan, size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'SHARE TOURNAMENT RULES',
                    style: TextStyle(
                      color: AppColors.cyanLight,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose active players from the roster or select the entire group. Send directly via SMS or share to your group chat (WhatsApp, GroupMe, Messages).',
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${selectedIds.length} of ${players.length} selected',
                              style: const TextStyle(
                                color: AppColors.cyanLight,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onPressed: () {
                              setDialogState(() {
                                if (allSelected) {
                                  selectedIds.clear();
                                } else {
                                  selectedIds.addAll(players.map((p) => p.id));
                                }
                              });
                            },
                            child: Text(
                              allSelected ? 'Clear All' : 'Select All',
                              style: const TextStyle(
                                color: AppColors.duneSand,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...players.map((player) {
                      final isSelected = selectedIds.contains(player.id);
                      final hasPhone = player.phoneNumber != null && player.phoneNumber!.trim().isNotEmpty;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.lakeCyan.withValues(alpha: 0.6)
                                : Colors.white12,
                          ),
                        ),
                        child: Material(
                          color: isSelected
                              ? AppColors.lakeCyan.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(9),
                          child: CheckboxListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            activeColor: AppColors.lakeCyan,
                            checkColor: const Color(0xFF04110A),
                            value: isSelected,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  selectedIds.add(player.id);
                                } else {
                                  selectedIds.remove(player.id);
                                }
                              });
                            },
                            secondary: CircleAvatar(
                              radius: 16,
                              backgroundColor: isSelected ? AppColors.lakeCyan : AppColors.surfaceElevated,
                              child: Text(
                                player.initials.isNotEmpty
                                    ? player.initials
                                    : (player.fullName.isNotEmpty ? player.fullName[0] : '?'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? const Color(0xFF04110A) : Colors.white,
                                ),
                              ),
                            ),
                            title: Text(
                              player.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Icon(
                                  hasPhone ? Icons.phone_android : Icons.phone_disabled,
                                  size: 13,
                                  color: hasPhone ? AppColors.cyanLight : Colors.white38,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    hasPhone ? player.phoneNumber! : 'No phone number entered',
                                    style: TextStyle(
                                      color: hasPhone ? Colors.white70 : Colors.white38,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    if (selectedPlayers.any((p) => p.phoneNumber == null || p.phoneNumber!.trim().isEmpty))
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'ℹ️ For players without a phone number, use "Share via Apps" to message them in your group chat.',
                          style: TextStyle(color: AppColors.duneSand, fontSize: 11.5),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.share, size: 16, color: AppColors.cyanLight),
                label: const Text(
                  'Share via Apps',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.cyanLight, fontSize: 12.5),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.lakeCyan),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  Share.share(
                    _officialRulesSummaryText,
                    subject: '🏌️ Arcadia Cup 2026 – Official Tournament Rules',
                  );
                },
              ),
              FilledButton.icon(
                icon: const Icon(Icons.sms_outlined, size: 16, color: Color(0xFF04110A)),
                label: Text(
                  'Compose Text ($validPhoneCount)',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF04110A), fontSize: 12.5),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.lakeCyan,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onPressed: validPhoneCount == 0
                    ? null
                    : () async {
                        Navigator.of(dialogCtx).pop();
                        final phoneNumbers = selectedPlayers
                            .where((p) => p.phoneNumber != null && p.phoneNumber!.trim().isNotEmpty)
                            .map((p) => p.phoneNumber!.trim())
                            .toList();

                        try {
                          const service = DeviceCommunicationService();
                          await service.sendSms(
                            phoneNumbers: phoneNumbers,
                            message: _officialRulesSummaryText,
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not launch SMS app: $e'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  static const String _officialRulesSummaryText = '''🏌️ ARCADIA CUP 2026 – OFFICIAL RULES SUMMARY

🏆 TOURNAMENT FORMAT:
• 8-Player Invitational at Arcadia Bluffs (The Bluffs & South Course)
• 2-Man Best Ball Stableford (Net Adjusted with GHIN handicaps)

1️⃣ AI 4-SOMES & PARTNER ROTATION:
• AI engine maximizes randomness while guaranteeing equal playing time with all 7 other golfers over the trip.

2️⃣ 2-MAN BEST BALL STABLEFORD:
• AI-randomized 2-man teams compete each round.
• Team hole score = higher Stableford points between the 2 partners.
• Points Scale (Rounds 1 to N-1):
  - Double Eagle / Albatross: +5 pts
  - Eagle: +4 pts
  - Birdie: +3 pts
  - Par: +2 pts
  - Bogey: +1 pt
  - Double Bogey or worse: 0 pts (Max 0)

3️⃣ END OF ROUND SCORE RECORDING:
• Both partners record the team's total Stableford points for their individual tournament standing (e.g. 45 pts earned = 45 pts to each player).

4️⃣ FINAL ROUND PARTNER SELECTION DRAFT:
• Cumulative scores rank golfers #1 thru #8.
• Captains #1, #2, #3 pick partners from the lower pool (#5–#8). #4 is paired with the last player.
• Team 1 vs Team 4 face off in Foursome 1; Team 2 vs Team 3 face off in Foursome 2.

5️⃣ FINAL ROUND MODIFIED STABLEFORD:
• Penalizes bad play down the stretch!
  - Albatross: +4 | Eagle: +3 | Birdie: +2 | Par: +1 | Bogey: 0 | Double Bogey or worse: -1 pt

6️⃣ ARCADIA CUP CHAMPION:
• Highest cumulative Stableford points across all rounds wins the trophy!

💰 THE BIRDIE POT BETTING GAME:
• Entry: \$2.00 per birdie made across all 8 golfers.
• Split: \$1.00 to Round Pot, \$1.00 to Trip Cumulative Pot.
• Round Pot: Won by the player with the LAST birdie made in that round!
• Cumulative Pot: Won by the player with the LAST birdie made on the trip!

🌐 Live Tournament Website & Standings:
https://staying-commercial-steven-ins.trycloudflare.com''';
}

class PointsRow {
  final String scoreName;
  final String netRelation;
  final String points;
  final bool isNegative;

  const PointsRow(this.scoreName, this.netRelation, this.points, {this.isNegative = false});
}
