import '../models/round_score_import_draft.dart';

class ImportPlayerCandidate {
  final String id;
  final String fullName;
  final String nickname;
  final String initials;

  const ImportPlayerCandidate({
    required this.id,
    required this.fullName,
    required this.nickname,
    required this.initials,
  });
}

class PlayerScoreRowMatch {
  const PlayerScoreRowMatch({required this.rowIndex, required this.confidence});

  final int rowIndex;
  final double confidence;
}

class PlayerScoreRowMatcher {
  const PlayerScoreRowMatcher();

  Map<String, PlayerScoreRowMatch> match({
    required List<ImportPlayerCandidate> players,
    required List<ImportedPlayerScoreRow> rows,
  }) {
    final candidates = <_Candidate>[];

    for (final player in players) {
      for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
        final score = _bestNameScore(player, rows[rowIndex].sourceLabel);
        if (score >= 0.35) {
          candidates.add(
            _Candidate(playerId: player.id, rowIndex: rowIndex, score: score),
          );
        }
      }
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    final usedPlayers = <String>{};
    final usedRows = <int>{};
    final result = <String, PlayerScoreRowMatch>{};

    for (final candidate in candidates) {
      if (usedPlayers.contains(candidate.playerId) ||
          usedRows.contains(candidate.rowIndex)) {
        continue;
      }
      usedPlayers.add(candidate.playerId);
      usedRows.add(candidate.rowIndex);
      result[candidate.playerId] = PlayerScoreRowMatch(
        rowIndex: candidate.rowIndex,
        confidence: candidate.score,
      );
    }

    return result;
  }

  double _bestNameScore(ImportPlayerCandidate player, String label) {
    final normalizedLabel = _normalize(label);
    if (normalizedLabel.isEmpty) {
      return 0;
    }

    final names = <String>{
      player.fullName,
      player.nickname,
      player.initials,
      ...player.fullName.split(RegExp(r'\s+')),
    }.map(_normalize).where((value) => value.isNotEmpty);

    var best = 0.0;
    for (final name in names) {
      if (normalizedLabel == name) {
        return 1;
      }
      if (normalizedLabel.contains(name) || name.contains(normalizedLabel)) {
        best = best < 0.9 ? 0.9 : best;
      }
      final similarity = _similarity(normalizedLabel, name);
      if (similarity > best) {
        best = similarity;
      }
    }
    return best;
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
  }

  double _similarity(String left, String right) {
    if (left.isEmpty || right.isEmpty) {
      return 0;
    }
    final distance = _levenshtein(left, right);
    final longest = left.length > right.length ? left.length : right.length;
    return 1 - (distance / longest);
  }

  int _levenshtein(String left, String right) {
    final previous = List<int>.generate(right.length + 1, (index) => index);
    final current = List<int>.filled(right.length + 1, 0);

    for (var i = 1; i <= left.length; i++) {
      current[0] = i;
      for (var j = 1; j <= right.length; j++) {
        final cost = left[i - 1] == right[j - 1] ? 0 : 1;
        final deletion = previous[j] + 1;
        final insertion = current[j - 1] + 1;
        final substitution = previous[j - 1] + cost;
        current[j] = deletion < insertion
            ? (deletion < substitution ? deletion : substitution)
            : (insertion < substitution ? insertion : substitution);
      }
      for (var j = 0; j <= right.length; j++) {
        previous[j] = current[j];
      }
    }
    return previous[right.length];
  }
}

class _Candidate {
  const _Candidate({
    required this.playerId,
    required this.rowIndex,
    required this.score,
  });

  final String playerId;
  final int rowIndex;
  final double score;
}
