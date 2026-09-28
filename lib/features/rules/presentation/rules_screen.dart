import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Rules'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
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
}

class PointsRow {
  final String scoreName;
  final String netRelation;
  final String points;
  final bool isNegative;

  const PointsRow(this.scoreName, this.netRelation, this.points, {this.isNegative = false});
}
