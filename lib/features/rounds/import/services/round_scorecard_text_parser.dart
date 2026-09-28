import '../models/round_score_import_draft.dart';

class RoundScorecardTextParser {
  const RoundScorecardTextParser();

  ImportedPlayerScoreRow? recoverBestIncompleteRow(
    String rawText, {
    required int holeCount,
    required Set<String> excludedSignatures,
  }) {
    ImportedPlayerScoreRow? best;
    for (final rawLine in rawText.split(RegExp(r'[\r\n]+'))) {
      final line = rawLine.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (line.isEmpty || _isHeader(line, holeCount)) continue;
      final matches = RegExp(
        r'(?<!\d)(?:1[0-5]|[1-9])(?!\d)',
      ).allMatches(line).toList();
      if (matches.length < 7 || matches.length >= holeCount) continue;
      final values = matches
          .map((match) => int.parse(match.group(0)!))
          .toList();
      final padded = <int?>[
        ...values.take(holeCount),
        ...List<int?>.filled(
          (holeCount - values.length).clamp(0, holeCount),
          null,
        ),
      ];
      if (excludedSignatures.contains(padded.join(','))) continue;
      var label = line.substring(0, matches.first.start).trim();
      label = label.replaceAll(RegExp(r'[:|\-–—]+$'), '').trim();
      final candidate = ImportedPlayerScoreRow(
        sourceLabel: label.isEmpty ? 'Partially detected row' : label,
        scores: padded,
        sourceText: line,
      );
      if (best == null ||
          candidate.enteredScoreCount > best.enteredScoreCount) {
        best = candidate;
      }
    }
    return best;
  }

  RoundScoreImportDraft parse(String rawText, {required int holeCount}) {
    final rows = <ImportedPlayerScoreRow>[];
    for (final rawLine in rawText.split(RegExp(r'[\r\n]+'))) {
      final line = rawLine
          .replaceAll(RegExp(r'[|•·]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (line.isEmpty || _isHeader(line, holeCount)) continue;
      final matches = RegExp(
        r'(?<!\d)(?:20|1[0-9]|[1-9])(?!\d)',
      ).allMatches(line).toList();
      if (matches.length < (holeCount == 9 ? 7 : 9)) continue;
      final numbers = matches
          .map((match) => int.parse(match.group(0)!))
          .toList();
      final scores = _scores(numbers, holeCount);
      if (scores == null) continue;
      var label = line.substring(0, matches.first.start).trim();
      label = label.replaceAll(RegExp(r'[:|\-–—]+$'), '').trim();
      rows.add(
        ImportedPlayerScoreRow(
          sourceLabel: label.isEmpty
              ? 'Detected row ${rows.length + 1}'
              : label,
          sourceText: line,
          scores: scores.map<int?>((score) => score).toList(),
        ),
      );
    }
    if (rows.isEmpty) {
      throw const FormatException(
        'The offline reader found text, but could not identify complete player '
        'score rows. Try Gemini, ChatGPT, Claude or enter scores manually.',
      );
    }
    return RoundScoreImportDraft(
      holeCount: holeCount,
      rows: rows,
      warnings: [
        'Offline OCR was used. Verify every player row and every hole score.',
        '${rows.length} possible score rows were detected; confirm every row '
            'and assignment.',
      ],
    );
  }

  bool _isHeader(String line, int holeCount) {
    final lower = line.toLowerCase();
    if (lower.contains('hole') ||
        lower.contains('yards') ||
        lower.contains('handicap') ||
        lower.startsWith('par ')) {
      return true;
    }
    final values = RegExp(
      r'(?<!\d)(?:1[0-8]|[1-9])(?!\d)',
    ).allMatches(line).map((match) => int.parse(match.group(0)!)).toList();
    return values.length >= holeCount &&
        List.generate(
          holeCount,
          (index) => index + 1,
        ).every((hole) => values[hole - 1] == hole);
  }

  List<int>? _scores(List<int> numbers, int holeCount) {
    if (numbers.length == holeCount && _valid(numbers)) return numbers;
    if (holeCount == 18 && numbers.length >= 20) {
      for (
        var frontStart = 0;
        frontStart <= numbers.length - 20;
        frontStart++
      ) {
        final front = numbers.skip(frontStart).take(9).toList();
        if (!_valid(front)) continue;
        for (
          var backStart = frontStart + 10;
          backStart <= numbers.length - 9;
          backStart++
        ) {
          final back = numbers.skip(backStart).take(9).toList();
          if (_valid(back)) return [...front, ...back];
        }
      }
    }
    for (var start = 0; start <= numbers.length - holeCount; start++) {
      final candidate = numbers.skip(start).take(holeCount).toList();
      if (_valid(candidate)) return candidate;
    }
    return null;
  }

  bool _valid(List<int> scores) =>
      scores.every((score) => score >= 1 && score <= 15);
}
