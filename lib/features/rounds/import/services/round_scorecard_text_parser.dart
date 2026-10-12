import '../models/round_score_import_draft.dart';

class RoundScorecardTextParser {
  const RoundScorecardTextParser();

  /// Normalizes OCR text:
  /// - Converts circled unicode numbers (e.g., ①-⑳, ❶-❿, ➀-➉, ➊-➓, ⑴-⑼) to ASCII digits
  /// - Strips enclosing brackets/parentheses around single/double digits (e.g., `[5]` -> ` 5 `, `(4)` -> ` 4 `)
  /// - Replaces OCR line bullets/pipes with spaces
  static String normalizeOcrText(String input) {
    var text = input;

    // Circled digits 1-20
    const circled = {
      '①': ' 1 ', '②': ' 2 ', '③': ' 3 ', '④': ' 4 ', '⑤': ' 5 ',
      '⑥': ' 6 ', '⑦': ' 7 ', '⑧': ' 8 ', '⑨': ' 9 ', '⑩': ' 10 ',
      '⑪': ' 11 ', '⑫': ' 12 ', '⑬': ' 13 ', '⑭': ' 14 ', '⑮': ' 15 ',
      '⑯': ' 16 ', '⑰': ' 17 ', '⑱': ' 18 ', '⑲': ' 19 ', '⑳': ' 20 ',
      // Filled circled digits 1-10
      '❶': ' 1 ', '❷': ' 2 ', '❸': ' 3 ', '❹': ' 4 ', '❺': ' 5 ',
      '❻': ' 6 ', '❼': ' 7 ', '❽': ' 8 ', '❾': ' 9 ', '❿': ' 10 ',
      // Sans-serif circled digits 1-10
      '➀': ' 1 ', '➁': ' 2 ', '➂': ' 3 ', '➃': ' 4 ', '➄': ' 5 ',
      '➅': ' 6 ', '➆': ' 7 ', '➇': ' 8 ', '➈': ' 9 ', '➉': ' 10 ',
      // Sans-serif filled circled digits 1-10
      '➊': ' 1 ', '➋': ' 2 ', '➌': ' 3 ', '➍': ' 4 ', '➎': ' 5 ',
      '➏': ' 6 ', '➐': ' 7 ', '➑': ' 8 ', '➒': ' 9 ', '➓': ' 10 ',
      // Parenthesized digits 1-9
      '⑴': ' 1 ', '⑵': ' 2 ', '⑶': ' 3 ', '⑷': ' 4 ', '⑸': ' 5 ',
      '⑹': ' 6 ', '⑺': ' 7 ', '⑻': ' 8 ', '⑼': ' 9 ',
    };

    circled.forEach((k, v) {
      if (text.contains(k)) {
        text = text.replaceAll(k, v);
      }
    });

    // Boxed, parenthesized, or bracketed numbers/tokens (e.g., [5], [[7]], (4), [ 5 ], [5, 5])
    text = text.replaceAll(RegExp(r'[\[\]\(\)\{\}|•·]'), ' ');

    return text;
  }

  ImportedPlayerScoreRow? recoverBestIncompleteRow(
    String rawText, {
    required int holeCount,
    required Set<String> excludedSignatures,
  }) {
    ImportedPlayerScoreRow? best;
    final normalized = normalizeOcrText(rawText);
    for (final rawLine in normalized.split(RegExp(r'[\r\n]+'))) {
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
    final normalized = normalizeOcrText(rawText);
    final rows = <ImportedPlayerScoreRow>[];

    // 1. Try single-line 18-hole or 9-hole score detection (classical scorecard format)
    for (final rawLine in normalized.split(RegExp(r'[\r\n]+'))) {
      final line = rawLine.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (line.isEmpty || _isHeader(line, holeCount)) continue;
      final matches = RegExp(
        r'(?<!\d)(?:20|1[0-9]|[1-9])(?!\d)',
      ).allMatches(line).toList();
      if (matches.length < (holeCount == 9 ? 7 : 18)) continue;
      final numbers = matches
          .map((match) => int.parse(match.group(0)!))
          .toList();
      final scores = _scores(numbers, holeCount);
      if (scores == null) continue;
      var label = line.substring(0, matches.first.start).trim();
      label = _cleanPlayerLabel(label);
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

    // 2. If no single-row format matched, try 18Birdies 2-row format
    if (rows.isEmpty) {
      final splitRows = _parseTwoRowScorecard(normalized, holeCount: holeCount);
      rows.addAll(splitRows);
    }

    // 3. If rows is still empty, check for 9-hole candidate lines
    if (rows.isEmpty) {
      final nineRows = _parseNineHoleLines(normalized);
      rows.addAll(nineRows);
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
        '${rows.length} score row${rows.length == 1 ? '' : 's'} detected; '
            'confirm row assignments and scores.',
      ],
    );
  }

  /// Parses 18Birdies and digital 2-row scorecards where each player has:
  /// - Front 9 (Holes 1 to 9) on the TOP row, followed by subtotal (OUT)
  /// - Back 9 (Holes 10 to 18) on the BOTTOM row, followed by subtotal (IN)
  /// - Player name on the left (on row 1, row 2, or line preceding row 1)
  List<ImportedPlayerScoreRow> _parseTwoRowScorecard(
    String normalizedText, {
    required int holeCount,
  }) {
    final candidateLines = <_NineHoleLine>[];
    String? pendingPlayerName;

    for (final rawLine in normalizedText.split(RegExp(r'[\r\n]+'))) {
      final line = rawLine.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (line.isEmpty || _isHeader(line, 9)) {
        continue;
      }

      // Check if this line is an isolated player name line (e.g. "Chet M.", "Neal P.")
      final numbersMatch = RegExp(r'(?<!\d)(?:[1-9]|1[0-9]|20)(?!\d)').allMatches(line).toList();
      if (numbersMatch.length < 5) {
        final clean = _cleanPlayerLabel(line);
        if (_isLikelyPlayerName(clean)) {
          pendingPlayerName = clean;
        }
        continue;
      }

      // Extract all numbers on this line
      final allIntMatches = RegExp(r'\b\d+\b').allMatches(line).toList();
      final allNumbers = allIntMatches.map((m) => int.parse(m.group(0)!)).toList();

      // Look for a 9-score segment
      final segment = _findNineHoleSegment(allNumbers);
      if (segment != null) {
        var label = '';
        final firstScoreIndex = line.indexOf(segment.scores.first.toString());
        if (firstScoreIndex > 0) {
          label = _cleanPlayerLabel(line.substring(0, firstScoreIndex));
        }

        // If line didn't have label, use pending player name
        if (label.isEmpty && pendingPlayerName != null) {
          label = pendingPlayerName;
          pendingPlayerName = null;
        }

        candidateLines.add(
          _NineHoleLine(
            label: label,
            line: line,
            scores: segment.scores,
            subtotal: segment.subtotal,
          ),
        );
      }
    }

    final rows = <ImportedPlayerScoreRow>[];

    // Pair consecutive 9-hole lines: [0]+[1] = Player 1, [2]+[3] = Player 2
    for (var i = 0; i + 1 < candidateLines.length; i += 2) {
      final front = candidateLines[i];
      final back = candidateLines[i + 1];

      final label = front.label.isNotEmpty
          ? front.label
          : (back.label.isNotEmpty ? back.label : 'Detected player ${rows.length + 1}');

      final all18Scores = [...front.scores, ...back.scores].map<int?>((s) => s).toList();
      final finalScores = (holeCount < 18 && holeCount >= 9 && all18Scores.length >= holeCount)
          ? all18Scores.take(holeCount).toList()
          : all18Scores;

      rows.add(
        ImportedPlayerScoreRow(
          sourceLabel: label,
          sourceText: '${front.line}\n${back.line}',
          scores: finalScores,
        ),
      );
    }

    return rows;
  }

  /// Parses 9-hole scorecards
  List<ImportedPlayerScoreRow> _parseNineHoleLines(String normalizedText) {
    final rows = <ImportedPlayerScoreRow>[];
    String? pendingName;

    for (final rawLine in normalizedText.split(RegExp(r'[\r\n]+'))) {
      final line = rawLine.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (line.isEmpty || _isHeader(line, 9)) continue;

      final allNumbers = RegExp(r'\b\d+\b')
          .allMatches(line)
          .map((m) => int.parse(m.group(0)!))
          .toList();

      if (allNumbers.length < 7) {
        final clean = _cleanPlayerLabel(line);
        if (_isLikelyPlayerName(clean)) {
          pendingName = clean;
        }
        continue;
      }

      final segment = _findNineHoleSegment(allNumbers);
      if (segment != null) {
        var label = '';
        final idx = line.indexOf(segment.scores.first.toString());
        if (idx > 0) {
          label = _cleanPlayerLabel(line.substring(0, idx));
        }
        if (label.isEmpty && pendingName != null) {
          label = pendingName;
          pendingName = null;
        }
        rows.add(
          ImportedPlayerScoreRow(
            sourceLabel: label.isNotEmpty ? label : 'Detected player ${rows.length + 1}',
            sourceText: line,
            scores: segment.scores.map<int?>((s) => s).toList(),
          ),
        );
      }
    }
    return rows;
  }

  _NineHoleSegment? _findNineHoleSegment(List<int> numbers) {
    if (numbers.length < 7) return null;

    // 1. First priority: 9 scores whose sum equals the next number (subtotal)
    if (numbers.length >= 10) {
      for (var i = 0; i <= numbers.length - 10; i++) {
        final candidate = numbers.sublist(i, i + 9);
        if (_valid(candidate)) {
          final sum = candidate.reduce((a, b) => a + b);
          final subtotal = numbers[i + 9];
          if (sum == subtotal) {
            return _NineHoleSegment(scores: candidate, subtotal: subtotal);
          }
        }
      }
    }

    // 2. Second priority: 9 consecutive scores where all are valid golf scores
    if (numbers.length >= 9) {
      for (var i = 0; i <= numbers.length - 9; i++) {
        final candidate = numbers.sublist(i, i + 9);
        if (_valid(candidate)) {
          final subtotal = (i + 9 < numbers.length) ? numbers[i + 9] : null;
          return _NineHoleSegment(scores: candidate, subtotal: subtotal);
        }
      }
    }

    // 3. Third priority: 5 to 8 consecutive golf scores (pad to 9)
    final scoresOnly = numbers.where((n) => n >= 1 && n <= 15).toList();
    if (scoresOnly.length >= 5) {
      final subtotal = numbers.where((n) => n > 15).firstOrNull;
      return _NineHoleSegment(
        scores: [
          ...scoresOnly.take(9),
          ...List<int?>.filled((9 - scoresOnly.length).clamp(0, 9), null),
        ],
        subtotal: subtotal,
      );
    }

    return null;
  }

  bool _isHeader(String line, int holeCount) {
    final lower = line.toLowerCase();
    if (lower.contains('hole') ||
        lower.contains('yards') ||
        lower.contains('handicap') ||
        lower.startsWith('par ') ||
        lower.contains('golf course') ||
        lower.contains('wind ') ||
        lower.contains('temp ') ||
        lower.contains('share to') ||
        lower.contains('instagram') ||
        lower.contains('facebook') ||
        lower.contains('tiktok') ||
        lower.contains('download') ||
        lower.contains('copy link') ||
        lower.contains('message') ||
        lower == '18birdies') {
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

  String _cleanPlayerLabel(String label) {
    var clean = label
        .replaceAll(RegExp(r'[:|\-–—_]+$'), '')
        .replaceAll(RegExp(r'^[:|\-–—_]+'), '')
        .replaceAll(RegExp(r'\bto par\b.*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bgross\b.*', caseSensitive: false), '')
        .trim();
    return clean;
  }

  bool _isLikelyPlayerName(String text) {
    if (text.isEmpty || text.length > 30) return false;
    final lower = text.toLowerCase();
    if (lower.contains('course') ||
        lower.contains('wind') ||
        lower.contains('temp') ||
        lower.contains('hole') ||
        lower.contains('share') ||
        lower.contains('download') ||
        lower.contains('copy') ||
        lower.contains('more') ||
        lower.contains('to par')) {
      return false;
    }
    // Player name typically contains letters (e.g. "Chet M.", "Neal P.")
    return RegExp(r'[a-zA-Z]').hasMatch(text);
  }

  List<int>? _scores(List<int> numbers, int holeCount) {
    if (numbers.length == holeCount && _valid(numbers)) return numbers;
    if (holeCount == 18 && numbers.length >= 20) {
      for (var frontStart = 0; frontStart <= numbers.length - 20; frontStart++) {
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

class _NineHoleSegment {
  final List<int?> scores;
  final int? subtotal;

  const _NineHoleSegment({required this.scores, this.subtotal});
}

class _NineHoleLine {
  final String label;
  final String line;
  final List<int?> scores;
  final int? subtotal;

  const _NineHoleLine({
    required this.label,
    required this.line,
    required this.scores,
    this.subtotal,
  });
}
