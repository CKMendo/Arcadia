import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/round_score_import_draft.dart';
import 'round_scorecard_text_parser.dart';

class OnDeviceTextRecognitionResult {
  const OnDeviceTextRecognitionResult({
    required this.text,
    required this.lineCount,
  });

  final String text;
  final int lineCount;
}

class OnDeviceTextRecognitionService {
  const OnDeviceTextRecognitionService();

  /// Primary high-level offline OCR entry point for scorecard image import.
  /// 1. Tries 2D spatial grid extraction using bounding boxes (customized for 18Birdies 2-row layout).
  /// 2. If spatial analysis doesn't find complete rows, falls back to text parsing.
  Future<RoundScoreImportDraft> analyzeScorecard(
    String imagePath, {
    required int holeCount,
  }) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );

      final elements = result.blocks
          .expand((block) => block.lines)
          .expand((line) => line.elements)
          .where((element) => element.text.trim().isNotEmpty)
          .toList();

      if (elements.isEmpty) {
        throw const FormatException(
          'The offline reader did not find any text in this photo.',
        );
      }

      for (final e in elements) {
        debugPrint('MLKit element: "${e.text}" at (${e.boundingBox.left.round()}, ${e.boundingBox.top.round()})');
      }

      // Priority 1: Direct 2D spatial analysis of score boxes
      try {
        final spatialDraft = extractFromSpatialElements(
          elements: elements,
          holeCount: holeCount >= 18 ? holeCount : 18,
        );
        if (spatialDraft != null && spatialDraft.rows.isNotEmpty) {
          debugPrint('Offline OCR: Successfully extracted ${spatialDraft.rows.length} rows via 2D spatial analysis');
          if (holeCount < 18) {
            return RoundScoreImportDraft(
              holeCount: holeCount,
              rows: spatialDraft.rows.map((r) => ImportedPlayerScoreRow(
                sourceLabel: r.sourceLabel,
                scores: r.scores.take(holeCount).toList(),
                sourceText: r.sourceText,
              )).toList(),
              warnings: spatialDraft.warnings,
            );
          }
          return spatialDraft;
        }
      } catch (e) {
        debugPrint('Spatial extraction fallback: $e');
      }

      // Priority 2: Text reconstruction and line-based parser
      final rows = _groupIntoPhysicalRows(elements);
      final text = rows
          .map(
            (row) => row
                .map((element) => RoundScorecardTextParser.normalizeOcrText(element.text.trim()))
                .where((value) => value.isNotEmpty)
                .join(' '),
          )
          .where((row) => row.isNotEmpty)
          .join('\n');

      return const RoundScorecardTextParser().parse(text, holeCount: holeCount);
    } finally {
      await recognizer.close();
    }
  }

  Future<OnDeviceTextRecognitionResult> recognize(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      final elements = result.blocks
          .expand((block) => block.lines)
          .expand((line) => line.elements)
          .where((element) => element.text.trim().isNotEmpty)
          .toList();
      final rows = _groupIntoPhysicalRows(elements);
      final text = rows
          .map(
            (row) => row
                .map((element) => RoundScorecardTextParser.normalizeOcrText(element.text.trim()))
                .where((value) => value.isNotEmpty)
                .join(' '),
          )
          .where((row) => row.isNotEmpty)
          .join('\n');
      if (text.isEmpty) {
        throw const FormatException(
          'The offline reader did not find any text in this photo.',
        );
      }
      return OnDeviceTextRecognitionResult(text: text, lineCount: rows.length);
    } finally {
      await recognizer.close();
    }
  }

  /// 2D spatial grid extraction designed for 18Birdies scorecards:
  /// - Extracts all score digit bounding boxes
  /// - Groups them into 4 horizontal rows (Front 9 & Back 9 for Player 1 & 2)
  /// - Identifies player names to the left of the score grid
  /// - Pairs Front 9 (Holes 1..9) and Back 9 (Holes 10..18)
  static RoundScoreImportDraft? extractFromSpatialElements({
    required List<TextElement> elements,
    required int holeCount,
  }) {
    if (elements.isEmpty) return null;

    var maxX = 0.0;
    for (final e in elements) {
      if (e.boundingBox.right > maxX) maxX = e.boundingBox.right;
    }

    // 1. Identify bottom share sheet top boundary if present
    double? shareSheetTop;
    for (final e in elements) {
      final t = e.text.toLowerCase();
      if (t.contains('share to') ||
          t.contains('instagram') ||
          t.contains('facebook') ||
          t.contains('tiktok') ||
          t.contains('download') ||
          t.contains('copy link')) {
        if (shareSheetTop == null || e.boundingBox.top < shareSheetTop) {
          shareSheetTop = e.boundingBox.top;
        }
      }
    }

    // 2. Find all score digit candidates within scorecard area
    final scoreCandidates = <_SpatialScoreElement>[];
    for (final e in elements) {
      if (shareSheetTop != null && e.boundingBox.center.dy >= shareSheetTop - 15) {
        continue;
      }

      final lower = e.text.toLowerCase();
      if (lower.contains('/') ||
          lower.contains('hole') ||
          lower.contains('mph') ||
          lower.contains('temp') ||
          lower.contains('wind') ||
          lower.contains('°')) {
        continue;
      }

      final norm = RoundScorecardTextParser.normalizeOcrText(e.text).trim();
      final singleDigit = _tryParseScoreDigit(norm);
      if (singleDigit != null) {
        scoreCandidates.add(
          _SpatialScoreElement(
            digit: singleDigit,
            text: norm,
            x: e.boundingBox.center.dx,
            y: e.boundingBox.center.dy,
            box: e.boundingBox,
          ),
        );
      } else {
        // Multi-digit elements (e.g. MLKit grouped "755", "67", "63", "35", "66", "36")
        final digitMatches = RegExp(r'[1-9]').allMatches(norm).toList();
        if (digitMatches.isNotEmpty && digitMatches.length <= 9) {
          final count = digitMatches.length;
          for (var i = 0; i < count; i++) {
            final m = digitMatches[i];
            final val = int.parse(m.group(0)!);
            final fraction = (i + 0.5) / count;
            final digitX = e.boundingBox.left + (e.boundingBox.width * fraction);
            scoreCandidates.add(
              _SpatialScoreElement(
                digit: val,
                text: m.group(0)!,
                x: digitX,
                y: e.boundingBox.center.dy,
                box: Rect.fromLTWH(
                  e.boundingBox.left + (e.boundingBox.width * i / count),
                  e.boundingBox.top,
                  e.boundingBox.width / count,
                  e.boundingBox.height,
                ),
              ),
            );
          }
        }
      }
    }

    // Collect subtotal candidates (OUT/IN subtotals, typically 25..85 at the right edge of rows)
    final subtotalCandidates = <_SubtotalCandidate>[];
    for (final e in elements) {
      if (shareSheetTop != null && e.boundingBox.center.dy >= shareSheetTop - 15) {
        continue;
      }
      final norm = RoundScorecardTextParser.normalizeOcrText(e.text).trim();
      final subVal = int.tryParse(norm);
      if (subVal != null && subVal >= 25 && subVal <= 95) {
        subtotalCandidates.add(
          _SubtotalCandidate(
            value: subVal,
            x: e.boundingBox.center.dx,
            y: e.boundingBox.center.dy,
          ),
        );
      }
    }

    if (scoreCandidates.length < 10) {
      return null;
    }

    // 3. Cluster score digits into horizontal rows by Y coordinate
    scoreCandidates.sort((a, b) => a.y.compareTo(b.y));

    final rowClusters = <List<_SpatialScoreElement>>[];
    final heights = scoreCandidates.map((e) => e.box.height).where((h) => h > 0).toList()..sort();
    final medianHeight = heights.isEmpty ? 25.0 : heights[heights.length ~/ 2];
    final rowTolerance = (medianHeight * 0.70).clamp(24.0, 50.0);

    for (final el in scoreCandidates) {
      var foundRow = false;
      for (final cluster in rowClusters) {
        final clusterY = cluster.map((e) => e.y).reduce((a, b) => a + b) / cluster.length;
        if ((el.y - clusterY).abs() <= rowTolerance) {
          cluster.add(el);
          foundRow = true;
          break;
        }
      }
      if (!foundRow) {
        rowClusters.add([el]);
      }
    }

    // Filter clusters that contain at least 5 score digits
    final scoreRows = <List<_SpatialScoreElement>>[];
    for (final cluster in rowClusters) {
      if (cluster.length >= 5) {
        // Sort from left to right (X coordinate)
        cluster.sort((a, b) => a.x.compareTo(b.x));
        // Deduplicate elements with virtually identical X coordinates (< 10px)
        final deduped = <_SpatialScoreElement>[];
        for (final el in cluster) {
          if (deduped.isEmpty || (el.x - deduped.last.x).abs() >= 10.0) {
            deduped.add(el);
          }
        }
        scoreRows.add(deduped);
      }
    }

    // Sort the filtered rows from top to bottom
    scoreRows.sort((a, b) {
      final aY = a.map((e) => e.y).reduce((x, y) => x + y) / a.length;
      final bY = b.map((e) => e.y).reduce((x, y) => x + y) / b.length;
      return aY.compareTo(bY);
    });

    if (scoreRows.length < (holeCount == 18 ? 2 : 1)) {
      return null;
    }

    // Determine master column positions across 9 holes
    List<double>? masterColumns;
    final valid9Rows = scoreRows.where((r) {
      if (r.length != 9) return false;
      final span = r.last.x - r.first.x;
      if (span <= 50) return false;
      final avgStep = span / 8.0;
      for (var i = 0; i < 8; i++) {
        final step = r[i + 1].x - r[i].x;
        if ((step - avgStep).abs() > avgStep * 0.65) return false;
      }
      return true;
    }).toList();

    if (valid9Rows.isNotEmpty) {
      masterColumns = List.generate(9, (col) {
        final sum = valid9Rows.map((r) => r[col].x).reduce((a, b) => a + b);
        return sum / valid9Rows.length;
      });
    } else {
      final allSteps = <double>[];
      for (final r in scoreRows) {
        for (var i = 0; i < r.length - 1; i++) {
          final diff = r[i + 1].x - r[i].x;
          if (diff > 15.0 && diff < 150.0) {
            allSteps.add(diff);
          }
        }
      }
      if (allSteps.isNotEmpty) {
        allSteps.sort();
        final medianStep = allSteps[allSteps.length ~/ 2];
        final candidateMinX = scoreRows.where((r) => r.length >= 6).map((r) => r.first.x).toList();
        candidateMinX.sort();
        final startX = candidateMinX.isNotEmpty ? candidateMinX[candidateMinX.length ~/ 2] : scoreRows.first.first.x;
        masterColumns = List.generate(9, (i) => startX + i * medianStep);
      }
    }

    // 4. Extract player names from text elements to the left of the score grid
    final gridLeft = scoreRows.map((r) => r.first.x).reduce((a, b) => a < b ? a : b);
    final nameCandidates = elements.where((e) {
      if (shareSheetTop != null && e.boundingBox.center.dy >= shareSheetTop - 15) return false;
      if (e.boundingBox.right > gridLeft + 15) return false;
      final t = e.text.trim();
      return _isLikelyPlayerName(t);
    }).toList();

    // Check if scorecard is a Gross/Net table layout (requires 'net' row label within scorecard bounds)
    final isGrossNetTable = elements.any((e) {
      if (shareSheetTop != null && e.boundingBox.center.dy >= shareSheetTop - 15) return false;
      final t = e.text.trim().toLowerCase();
      return t == 'net';
    });

    // Filter out header/weather/metadata rows: a genuine score row must map to >= 5 master columns
    final validScoreRows = <List<_SpatialScoreElement>>[];
    for (final r in scoreRows) {
      final scores = _extract9Scores(r, masterColumns);
      final count = scores.where((s) => s != null).length;
      if (count >= 5) {
        validScoreRows.add(r);
      } else {
        debugPrint('Offline OCR filtered non-score row at Y=${r.first.y.round()} (only $count scores mapped to grid)');
      }
    }

    if (validScoreRows.length < (holeCount == 18 ? 2 : 1)) {
      return null;
    }

    final resultRows = <ImportedPlayerScoreRow>[];

    if (isGrossNetTable) {
      // In Gross/Net table layout, each player has a Gross row and a Net row.
      // We want to KEEP ONLY the Gross rows!
      for (final row in validScoreRows) {
        final rowY = row.map((e) => e.y).reduce((a, b) => a + b) / row.length;
        final rowHeight = row.map((e) => e.box.height).reduce((a, b) => a + b) / row.length;
        final maxDy = (rowHeight * 0.85).clamp(24.0, 55.0);
        final isNetRow = elements.any((e) {
          final dy = (e.boundingBox.center.dy - rowY).abs();
          return dy <= maxDy && e.text.trim().toLowerCase() == 'net';
        });
        if (isNetRow) {
          continue; // Skip Net row completely!
        }

        var scores9 = _extract9Scores(row, masterColumns);
        scores9 = _reconcileWithSubtotal(scores9, rowY, rowTolerance, masterColumns, subtotalCandidates);
        final playerTop = row.map((e) => e.box.top).reduce((a, b) => a < b ? a : b) - 45;
        final playerBottom = row.map((e) => e.box.bottom).reduce((a, b) => a > b ? a : b) + 45;

        var playerName = '';
        for (final nc in nameCandidates) {
          final ny = nc.boundingBox.center.dy;
          if (ny >= playerTop && ny <= playerBottom) {
            playerName = nc.text.trim();
            break;
          }
        }
        if (playerName.isEmpty) {
          playerName = 'Detected player ${resultRows.length + 1}';
        }

        final fullScores = holeCount == 18
            ? [...scores9, ...List<int?>.filled(9, null)]
            : scores9.take(holeCount).toList();

        resultRows.add(
          ImportedPlayerScoreRow(
            sourceLabel: playerName,
            scores: fullScores,
            sourceText: scores9.join(' '),
          ),
        );
      }
    } else if (holeCount == 18) {
      // Pair rows: [0]+[1] = Player 1, [2]+[3] = Player 2
      for (var i = 0; i + 1 < validScoreRows.length; i += 2) {
        final frontRow = validScoreRows[i];
        final backRow = validScoreRows[i + 1];

        var frontScores = _extract9Scores(frontRow, masterColumns);
        var backScores = _extract9Scores(backRow, masterColumns);

        final frontY = frontRow.map((e) => e.y).reduce((a, b) => a + b) / frontRow.length;
        final backY = backRow.map((e) => e.y).reduce((a, b) => a + b) / backRow.length;

        frontScores = _reconcileWithSubtotal(frontScores, frontY, rowTolerance, masterColumns, subtotalCandidates);
        backScores = _reconcileWithSubtotal(backScores, backY, rowTolerance, masterColumns, subtotalCandidates);

        final playerTop = frontRow.map((e) => e.box.top).reduce((a, b) => a < b ? a : b) - 40;
        final playerBottom = backRow.map((e) => e.box.bottom).reduce((a, b) => a > b ? a : b) + 55;

        var playerName = '';
        for (final nc in nameCandidates) {
          final ny = nc.boundingBox.center.dy;
          if (ny >= playerTop && ny <= playerBottom) {
            playerName = nc.text.trim();
            break;
          }
        }

        if (playerName.isEmpty) {
          playerName = 'Detected player ${resultRows.length + 1}';
        }

        resultRows.add(
          ImportedPlayerScoreRow(
            sourceLabel: playerName,
            scores: [...frontScores, ...backScores],
            sourceText: 'Front: ${frontScores.join(" ")}\nBack: ${backScores.join(" ")}',
          ),
        );
      }
    } else {
      // 9-hole round: each row is a player
      for (var i = 0; i < validScoreRows.length; i++) {
        final row = validScoreRows[i];
        var scores = _extract9Scores(row, masterColumns);
        final rowY = row.map((e) => e.y).reduce((a, b) => a + b) / row.length;
        scores = _reconcileWithSubtotal(scores, rowY, rowTolerance, masterColumns, subtotalCandidates);
        final rowTop = row.map((e) => e.box.top).reduce((a, b) => a < b ? a : b) - 40;
        final rowBottom = row.map((e) => e.box.bottom).reduce((a, b) => a > b ? a : b) + 45;

        var playerName = '';
        for (final nc in nameCandidates) {
          final ny = nc.boundingBox.center.dy;
          if (ny >= rowTop && ny <= rowBottom) {
            playerName = nc.text.trim();
            break;
          }
        }
        if (playerName.isEmpty) {
          playerName = 'Detected player ${resultRows.length + 1}';
        }

        resultRows.add(
          ImportedPlayerScoreRow(
            sourceLabel: playerName,
            scores: scores,
            sourceText: scores.join(' '),
          ),
        );
      }
    }

    if (resultRows.isEmpty) return null;

    for (final row in resultRows) {
      debugPrint('Offline OCR parsed row for ${row.sourceLabel}: ${row.scores}');
    }

    return RoundScoreImportDraft(
      holeCount: holeCount,
      rows: resultRows,
      warnings: [
        'On-device offline OCR was used.',
        '${resultRows.length} player row${resultRows.length == 1 ? '' : 's'} detected; verify row assignments and scores.',
      ],
    );
  }

  static List<int?> _extract9Scores(
    List<_SpatialScoreElement> row, [
    List<double>? masterColumns,
  ]) {
    if (row.isEmpty) return List<int?>.filled(9, null);

    // If master columns are available, assign each detected element to its closest column
    if (masterColumns != null && masterColumns.length == 9) {
      final colWidth = masterColumns.length >= 2
          ? (masterColumns[1] - masterColumns[0]).abs()
          : 45.0;
      final maxTolerance = colWidth * 0.70;

      final result = List<int?>.filled(9, null);
      final bestDiffs = List<double>.filled(9, double.infinity);

      for (final el in row) {
        var bestCol = -1;
        var minDiff = double.infinity;
        for (var c = 0; c < 9; c++) {
          final diff = (el.x - masterColumns[c]).abs();
          if (diff < minDiff) {
            minDiff = diff;
            bestCol = c;
          }
        }

        if (bestCol >= 0 && minDiff <= maxTolerance) {
          if (minDiff < bestDiffs[bestCol]) {
            bestDiffs[bestCol] = minDiff;
            result[bestCol] = el.digit;
          }
        }
      }
      return result;
    }

    if (row.length == 9) return row.map((e) => e.digit).toList();
    if (row.length >= 10) return row.take(9).map((e) => e.digit).toList();
    return [
      ...row.take(9).map((e) => e.digit),
      ...List<int?>.filled(9 - row.length, null),
    ];
  }

  static int? _tryParseScoreDigit(String text) {
    final direct = int.tryParse(text);
    if (direct != null && direct >= 1 && direct <= 15) {
      return direct;
    }
    final match = RegExp(r'^(?:[\[\(\{]?([1-9]|1[0-5])[\]\)\}]?)$').firstMatch(text);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    final cleaned = text.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').trim();
    final cleanedDirect = int.tryParse(cleaned);
    if (cleanedDirect != null && cleanedDirect >= 1 && cleanedDirect <= 15) {
      return cleanedDirect;
    }
    if (cleaned == 'S' || cleaned == 's') return 5;
    if (cleaned == 'B') return 8;
    if (cleaned == 'b') return 6;
    if (cleaned == 'q' || cleaned == 'g') return 9;
    if (cleaned == 'A' || cleaned == 'a') return 4;
    return null;
  }

  static bool _isLikelyPlayerName(String text) {
    if (text.isEmpty || text.length > 25) return false;
    final lower = text.toLowerCase();
    if (lower.contains('course') ||
        lower.contains('wind') ||
        lower.contains('temp') ||
        lower.contains('hole') ||
        lower.contains('share') ||
        lower.contains('download') ||
        lower.contains('copy') ||
        lower.contains('more') ||
        lower.contains('gross') ||
        lower.contains('net') ||
        lower.contains('to par')) {
      return false;
    }
    return RegExp(r'[a-zA-Z]').hasMatch(text);
  }

  List<List<TextElement>> _groupIntoPhysicalRows(List<TextElement> elements) {
    if (elements.isEmpty) return const [];
    final heights =
        elements
            .map((element) => element.boundingBox.height)
            .where((height) => height > 0)
            .toList()
          ..sort();
    final medianHeight = heights.isEmpty ? 16.0 : heights[heights.length ~/ 2];
    final tolerance = (medianHeight * 0.70).clamp(14.0, 45.0);
    final ordered = List<TextElement>.of(elements)
      ..sort(
        (left, right) =>
            left.boundingBox.center.dy.compareTo(right.boundingBox.center.dy),
      );
    final rows = <List<TextElement>>[];
    for (final element in ordered) {
      final center = element.boundingBox.center.dy;
      var bestRow = -1;
      var bestDistance = double.infinity;
      for (var index = 0; index < rows.length; index++) {
        final rowCenter = rows[index]
            .map((item) => item.boundingBox.center.dy)
            .reduce((left, right) => left + right) /
            rows[index].length;
        final distance = (rowCenter - center).abs();
        if (distance <= tolerance && distance < bestDistance) {
          bestRow = index;
          bestDistance = distance;
        }
      }
      if (bestRow < 0) {
        rows.add([element]);
      } else {
        rows[bestRow].add(element);
      }
    }
    rows.sort((a, b) {
      final aY = a.map((e) => e.boundingBox.center.dy).reduce((x, y) => x + y) / a.length;
      final bY = b.map((e) => e.boundingBox.center.dy).reduce((x, y) => x + y) / b.length;
      return aY.compareTo(bY);
    });
    return rows
        .map((row) {
          final sorted = List<TextElement>.of(row)
            ..sort(
              (left, right) =>
                  left.boundingBox.left.compareTo(right.boundingBox.left),
            );
          return sorted;
        })
        .toList(growable: false);
  }

  static List<int?> _reconcileWithSubtotal(
    List<int?> scores9,
    double rowY,
    double rowTolerance,
    List<double>? masterColumns,
    List<_SubtotalCandidate> subtotalCandidates,
  ) {
    if (masterColumns == null || masterColumns.length != 9) return scores9;
    final lastColX = masterColumns.last;

    // Check if exactly 1 hole is missing (8 holes detected)
    final nullIndices = <int>[];
    for (var i = 0; i < 9; i++) {
      if (scores9[i] == null) nullIndices.add(i);
    }
    if (nullIndices.length != 1) return scores9;

    // Find the subtotal element on this row (to the right of hole 9)
    _SubtotalCandidate? bestSubtotal;
    var minDiffY = double.infinity;
    for (final sub in subtotalCandidates) {
      final dy = (sub.y - rowY).abs();
      if (dy <= rowTolerance * 1.3 && sub.x > lastColX + 15) {
        if (dy < minDiffY) {
          minDiffY = dy;
          bestSubtotal = sub;
        }
      }
    }

    if (bestSubtotal != null) {
      final knownSum = scores9.whereType<int>().reduce((a, b) => a + b);
      final missingScore = bestSubtotal.value - knownSum;
      if (missingScore >= 1 && missingScore <= 15) {
        final result = List<int?>.from(scores9);
        result[nullIndices.first] = missingScore;
        debugPrint(
          'Offline OCR subtotal reconciliation: filled hole ${nullIndices.first + 1} with $missingScore '
          '(subtotal: ${bestSubtotal.value}, known sum: $knownSum)',
        );
        return result;
      }
    }

    return scores9;
  }
}

class _SpatialScoreElement {
  final int digit;
  final String text;
  final double x;
  final double y;
  final Rect box;

  const _SpatialScoreElement({
    required this.digit,
    required this.text,
    required this.x,
    required this.y,
    required this.box,
  });
}

class _SubtotalCandidate {
  final int value;
  final double x;
  final double y;

  const _SubtotalCandidate({
    required this.value,
    required this.x,
    required this.y,
  });
}
