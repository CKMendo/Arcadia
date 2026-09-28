import 'active_round_session.dart';

class BirdieOccurrence {
  final String playerId;
  final String playerName;
  final int holeNumber;
  final int grossScore;
  final int par;
  final int roundNumber;

  const BirdieOccurrence({
    required this.playerId,
    required this.playerName,
    required this.holeNumber,
    required this.grossScore,
    required this.par,
    required this.roundNumber,
  });

  bool get isEagleOrBetter => grossScore <= par - 2;
  String get scoreName => isEagleOrBetter ? 'Eagle' : 'Birdie';
}

class RoundBirdiePot {
  final int roundNumber;
  final int totalBirdies;
  final double costPerBirdie; // $2.00
  final int playerCount; // 8
  final List<BirdieOccurrence> birdies; // All birdies made in this round
  final int? lastBirdieHole; // Highest hole number where a birdie was recorded
  final List<String> winnerPlayerIds;
  final List<String> winnerNames;
  final double roundPotTotal; // $1.00 * playerCount * totalBirdies
  final double cumulativeContribution; // $1.00 * playerCount * totalBirdies
  final double payoutPerWinner;

  const RoundBirdiePot({
    required this.roundNumber,
    required this.totalBirdies,
    this.costPerBirdie = 2.0,
    this.playerCount = 8,
    required this.birdies,
    this.lastBirdieHole,
    required this.winnerPlayerIds,
    required this.winnerNames,
    required this.roundPotTotal,
    required this.cumulativeContribution,
    required this.payoutPerWinner,
  });

  /// Dues owed by every player for this round ($2 per birdie across all 8 players)
  double get duesPerPlayer => totalBirdies * costPerBirdie;

  /// Total dollars collected for this round (duesPerPlayer * playerCount)
  double get totalCollected => duesPerPlayer * playerCount;

  bool get hasBirdies => totalBirdies > 0;
  bool get isTied => winnerPlayerIds.length > 1;

  factory RoundBirdiePot.calculate(ActiveRoundSession session, {int totalFieldSize = 8}) {
    final birdies = <BirdieOccurrence>[];

    for (var h = 1; h <= session.holeCount; h++) {
      final hole = session.getHole(h);
      for (final p in session.players) {
        final gross = session.getGrossScore(p.playerId, h);
        // Birdie or better: gross > 0 and gross <= par - 1
        if (gross > 0 && gross <= hole.par - 1) {
          birdies.add(BirdieOccurrence(
            playerId: p.playerId,
            playerName: p.nickname.isNotEmpty ? p.nickname : p.name,
            holeNumber: h,
            grossScore: gross,
            par: hole.par,
            roundNumber: session.roundNumber,
          ));
        }
      }
    }

    final totalCount = birdies.length;
    final roundPot = totalCount * 1.0 * totalFieldSize;
    final cumContr = totalCount * 1.0 * totalFieldSize;

    if (birdies.isEmpty) {
      return RoundBirdiePot(
        roundNumber: session.roundNumber,
        totalBirdies: 0,
        playerCount: totalFieldSize,
        birdies: const [],
        lastBirdieHole: null,
        winnerPlayerIds: const [],
        winnerNames: const [],
        roundPotTotal: 0.0,
        cumulativeContribution: 0.0,
        payoutPerWinner: 0.0,
      );
    }

    // Find the latest hole number on which at least one birdie was made
    var maxHole = 0;
    for (final b in birdies) {
      if (b.holeNumber > maxHole) {
        maxHole = b.holeNumber;
      }
    }

    // All players who birdied this latest hole
    final winners = birdies.where((b) => b.holeNumber == maxHole).toList();
    final winnerIds = winners.map((w) => w.playerId).toSet().toList();
    final winnerNames = winners.map((w) => w.playerName).toSet().toList();
    final payout = winnerIds.isNotEmpty ? (roundPot / winnerIds.length) : 0.0;

    return RoundBirdiePot(
      roundNumber: session.roundNumber,
      totalBirdies: totalCount,
      playerCount: totalFieldSize,
      birdies: birdies,
      lastBirdieHole: maxHole,
      winnerPlayerIds: winnerIds,
      winnerNames: winnerNames,
      roundPotTotal: roundPot,
      cumulativeContribution: cumContr,
      payoutPerWinner: payout,
    );
  }
}

class PlayerLedgerSummary {
  final String playerId;
  final String playerName;
  final int totalBirdiesMade;
  final double totalDuesOwed; // Sum of $2 * birdies in each round
  final double totalRoundPotsWon; // Sum of round pot winnings
  final double cumulativePotWon; // Cumulative trip pot winnings
  
  const PlayerLedgerSummary({
    required this.playerId,
    required this.playerName,
    required this.totalBirdiesMade,
    required this.totalDuesOwed,
    required this.totalRoundPotsWon,
    required this.cumulativePotWon,
  });

  double get totalWon => totalRoundPotsWon + cumulativePotWon;
  double get netBalance => totalWon - totalDuesOwed;
}

class TripBirdiePotLedger {
  final List<RoundBirdiePot> roundPots;
  final double totalCumulativePot;
  final int? tripWinningRoundNumber;
  final int? tripWinningHole;
  final List<String> tripWinnerPlayerIds;
  final List<String> tripWinnerNames;
  final double payoutPerTripWinner;
  final Map<String, PlayerLedgerSummary> playerLedgers;

  const TripBirdiePotLedger({
    required this.roundPots,
    required this.totalCumulativePot,
    this.tripWinningRoundNumber,
    this.tripWinningHole,
    required this.tripWinnerPlayerIds,
    required this.tripWinnerNames,
    required this.payoutPerTripWinner,
    required this.playerLedgers,
  });

  int get totalTripBirdies => roundPots.fold(0, (sum, r) => sum + r.totalBirdies);

  factory TripBirdiePotLedger.calculate(List<ActiveRoundSession> sessions, {int totalFieldSize = 8}) {
    // Sort sessions chronologically / by roundNumber
    final sortedSessions = List<ActiveRoundSession>.from(sessions)
      ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));

    final roundPots = sortedSessions.map((s) => RoundBirdiePot.calculate(s, totalFieldSize: totalFieldSize)).toList();

    var cumPot = 0.0;
    for (final rp in roundPots) {
      cumPot += rp.cumulativeContribution;
    }

    // Cumulative Pot Winner:
    // The LAST birdie made at the end of the trip wins the cumulative pot.
    // Search backward from the latest round to the earliest round
    int? winRound;
    int? winHole;
    List<String> winIds = [];
    List<String> winNames = [];
    double tripPayout = 0.0;

    for (var i = roundPots.length - 1; i >= 0; i--) {
      final rp = roundPots[i];
      if (rp.hasBirdies && rp.lastBirdieHole != null) {
        winRound = rp.roundNumber;
        winHole = rp.lastBirdieHole;
        winIds = rp.winnerPlayerIds;
        winNames = rp.winnerNames;
        tripPayout = winIds.isNotEmpty ? (cumPot / winIds.length) : 0.0;
        break;
      }
    }

    // Build ledger per player
    final allPlayerMap = <String, String>{};
    for (final s in sortedSessions) {
      for (final p in s.players) {
        allPlayerMap[p.playerId] = p.nickname.isNotEmpty ? p.nickname : p.name;
      }
    }

    final ledgers = <String, PlayerLedgerSummary>{};

    for (final entry in allPlayerMap.entries) {
      final pId = entry.key;
      final pName = entry.value;

      var birdiesMade = 0;
      var duesOwed = 0.0;
      var roundPotsWon = 0.0;

      for (final rp in roundPots) {
        // Player owes dues for this round ($2 * total birdies in round)
        duesOwed += rp.duesPerPlayer;

        // Birdies made by this player
        birdiesMade += rp.birdies.where((b) => b.playerId == pId).length;

        // Did player win this round pot?
        if (rp.winnerPlayerIds.contains(pId)) {
          roundPotsWon += rp.payoutPerWinner;
        }
      }

      // Did player win cumulative trip pot?
      final cumWon = winIds.contains(pId) ? tripPayout : 0.0;

      ledgers[pId] = PlayerLedgerSummary(
        playerId: pId,
        playerName: pName,
        totalBirdiesMade: birdiesMade,
        totalDuesOwed: duesOwed,
        totalRoundPotsWon: roundPotsWon,
        cumulativePotWon: cumWon,
      );
    }

    return TripBirdiePotLedger(
      roundPots: roundPots,
      totalCumulativePot: cumPot,
      tripWinningRoundNumber: winRound,
      tripWinningHole: winHole,
      tripWinnerPlayerIds: winIds,
      tripWinnerNames: winNames,
      payoutPerTripWinner: tripPayout,
      playerLedgers: ledgers,
    );
  }
}
