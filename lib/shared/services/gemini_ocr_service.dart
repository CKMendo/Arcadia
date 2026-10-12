import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../features/courses/services/course_import_service.dart';
import '../../features/rounds/import/models/round_score_import_draft.dart';
import '../../features/rounds/import/services/ai_response_json_decoder.dart';
import 'app_settings_service.dart';

/// Centralized Gemini OCR and AI engine for Arcadia.
/// Single source of truth for all Gemini vision scanning:
/// - Scoring entry scorecard OCR
/// - Course entry scorecard OCR
/// - API key verification & model failover
class GeminiOcrService {
  GeminiOcrService._();

  static const String primaryModel = 'gemini-3.8-flash';
  static const String backupModel = 'gemini-3.6-flash';
  static const String fallbackModel = 'gemini-3.5-flash-lite';

  static const String primaryModelLabel = 'Gemini 3.8 Flash';
  static const String backupModelLabel = 'Gemini 3.6 Flash';
  static const String fallbackModelLabel = 'Gemini 3.5 Flash-Lite';

  /// Validates a Gemini API key using the unified Gemini 3 family models.
  static Future<bool> validateApiKey(String apiKey) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) return false;

    final modelsToTry = [
      primaryModel,
      backupModel,
      fallbackModel,
      'gemini-flash-lite-latest',
    ];
    final pingPayload = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': 'ping'}
          ]
        }
      ]
    });

    for (final m in modelsToTry) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$m:generateContent?key=$trimmedKey',
        );
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: pingPayload,
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          return true;
        }

        // If Google servers respond with 503 (high demand) or 429 (quota),
        // the API key itself is authenticated and valid!
        if (response.statusCode == 503 || response.statusCode == 429) {
          debugPrint('Key is valid on $m (Google returned ${response.statusCode} demand status)');
          return true;
        }

        // 400 Bad Request could mean invalid argument or bad key. Check body.
        final body = response.body.toLowerCase();
        if (response.statusCode == 400 &&
            (body.contains('api_key_invalid') || body.contains('key not valid') || body.contains('api key not found'))) {
          debugPrint('Invalid Gemini API key: ${response.body}');
          return false;
        }

        if (response.statusCode == 403) {
          debugPrint('Gemini API key forbidden (403): ${response.body}');
          return false;
        }
      } catch (e) {
        debugPrint('Gemini key validation attempt on $m failed: $e');
      }
    }
    return false;
  }

  /// Core execution engine that sends an image and/or prompt to Gemini with
  /// automatic primary -> backup -> resilient fleet failover.
  static Future<GeminiOcrResult> generateWithFallback({
    required String prompt,
    List<int>? imageBytes,
    String? mimeType,
    double temperature = 0.1,
    Duration timeout = const Duration(seconds: 40),
    String? explicitPrimaryKey,
    String? explicitSecondaryKey,
  }) async {
    final primaryKey = explicitPrimaryKey ?? await AppSettingsService.getGeminiPrimaryApiKey();
    final secondaryKey = explicitSecondaryKey ?? await AppSettingsService.getGeminiSecondaryApiKey();

    if ((primaryKey == null || primaryKey.isEmpty) &&
        (secondaryKey == null || secondaryKey.isEmpty)) {
      throw const FormatException(
        'Gemini API key not configured. Tap Configure Key below to set your Primary (3.8) and Backup (3.6) keys, '
        'or use FREE ON-DEVICE OCR.',
      );
    }

    final parts = <Map<String, dynamic>>[
      {'text': prompt},
    ];

    if (imageBytes != null && imageBytes.isNotEmpty) {
      parts.add({
        'inline_data': {
          'mime_type': mimeType ?? 'image/jpeg',
          'data': base64Encode(imageBytes),
        }
      });
    }

    final payload = {
      'contents': [
        {'parts': parts}
      ],
      'generationConfig': {
        'response_mime_type': 'application/json',
        'temperature': temperature,
      }
    };

    // Resilient fleet plan prioritizing high availability & speed without deprecated models:
    // 1. Primary Model: gemini-3.8-flash (Primary Key, then Secondary Key)
    // 2. Backup Model: gemini-3.6-flash (Primary Key, then Secondary Key)
    // 3. Fallback Model: gemini-3.5-flash-lite (Primary Key, then Secondary Key)
    // 4. Fleet Fallback: gemini-flash-lite-latest (Primary Key, then Secondary Key)
    // 5. Preview Fallback: gemini-3-flash-preview (Primary Key, then Secondary Key)
    final fleetModels = [
      (model: primaryModel, label: primaryModelLabel),
      (model: backupModel, label: backupModelLabel),
      (model: fallbackModel, label: fallbackModelLabel),
      (model: 'gemini-flash-lite-latest', label: 'Gemini Flash-Lite Latest'),
      (model: 'gemini-3-flash-preview', label: 'Gemini 3 Flash Preview'),
    ];

    final plan = <_GeminiAttemptPlan>[];
    for (final item in fleetModels) {
      if (primaryKey != null && primaryKey.isNotEmpty) {
        plan.add(_GeminiAttemptPlan(model: item.model, apiKey: primaryKey, label: '${item.label} (Primary Key)'));
      }
      if (secondaryKey != null && secondaryKey.isNotEmpty && secondaryKey != primaryKey) {
        plan.add(_GeminiAttemptPlan(model: item.model, apiKey: secondaryKey, label: '${item.label} (Secondary Key)'));
      }
    }

    String? lastErrorDetail;
    int lastStatusCode = 0;
    const attemptTimeout = Duration(seconds: 14);

    for (final step in plan) {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/${step.model}:generateContent?key=${step.apiKey}',
      );

      try {
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(attemptTimeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List?;
          if (candidates == null || candidates.isEmpty) {
            throw const FormatException('Gemini did not return any candidates.');
          }

          final firstCandidate = candidates.first as Map<String, dynamic>;
          final content = firstCandidate['content'] as Map<String, dynamic>?;
          final candidateParts = content?['parts'] as List?;
          final text = candidateParts?.first?['text'] as String?;

          if (text == null || text.trim().isEmpty) {
            throw const FormatException('Gemini returned empty text.');
          }

          final wasFallback = step.model != primaryModel;
          final fallbackNotice = wasFallback
              ? 'Gemini 3.8 Flash was unavailable; automatically analyzed using ${step.model == backupModel ? 'Gemini 3.6 Flash' : step.model}.'
              : null;

          return GeminiOcrResult(
            text: text,
            model: step.model,
            keyLabel: step.label,
            wasFallback: wasFallback,
            warning: fallbackNotice,
          );
        }

        lastStatusCode = response.statusCode;
        final errorBody = response.body;
        String extractedMsg = errorBody;
        try {
          final parsed = jsonDecode(errorBody);
          if (parsed is Map && parsed['error'] is Map) {
            extractedMsg = parsed['error']['message'] ?? errorBody;
          }
        } catch (_) {}
        lastErrorDetail = _sanitizeError(extractedMsg);

        if (response.statusCode == 503 || response.statusCode == 429) {
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      } on SocketException catch (e) {
        debugPrint('Gemini network socket failure: $e');
        throw const FormatException(
          'Unable to connect to Google Gemini (Network/DNS error). '
          'Please check your internet connection or Wi-Fi, or switch to FREE ON-DEVICE OCR.',
        );
      } catch (e) {
        final errStr = e.toString();
        if (errStr.contains('SocketException') || errStr.contains('Failed host lookup')) {
          throw const FormatException(
            'Unable to connect to Google Gemini (Network/DNS error). '
            'Please check your internet connection or Wi-Fi, or switch to FREE ON-DEVICE OCR.',
          );
        }
        lastErrorDetail = _sanitizeError(errStr);
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    if (lastStatusCode == 503) {
      throw const FormatException(
        'Google Gemini is currently experiencing high demand (503 UNAVAILABLE). '
        'Google AI servers are temporarily overloaded. '
        'Please switch to FREE ON-DEVICE OCR (which works offline with zero server wait) '
        'or wait a moment and tap RE-READ WITH GEMINI.',
      );
    } else if (lastStatusCode == 429) {
      throw const FormatException(
        'Gemini API request rate limit reached (429 RESOURCE_EXHAUSTED). '
        'Tried all configured keys and models. Please wait a moment and tap RE-READ WITH GEMINI, '
        'or switch to FREE ON-DEVICE OCR.',
      );
    } else {
      throw FormatException(
        'Gemini API error ($lastStatusCode): ${_sanitizeError(lastErrorDetail ?? 'Service temporarily unavailable.')}',
      );
    }
  }

  static String _sanitizeError(String msg) {
    return msg.replaceAll(RegExp(r'key=[A-Za-z0-9_\-\.]+'), 'key=[REDACTED]');
  }

  /// SCORING OCR: Analyzes completed golf scorecard photo and extracts player gross scores.
  static Future<RoundScoreImportDraft> analyzePlayerScorecard(
    String imagePath, {
    required int holeCount,
    String? targetPlayerName,
    List<ImportedPlayerScoreRow> existingRows = const [],
    String? explicitApiKey,
  }) async {
    final bytes = await File(imagePath).readAsBytes();
    if (bytes.isEmpty) throw const FormatException('The image file is empty.');

    final mimeType = imagePath.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';

    final promptText = targetPlayerName == null
        ? 'Extract player gross scores from this completed 18Birdies golf scorecard photo.\n\n'
          'CRITICAL 18BIRDIES SCORECARD FORMATS:\n'
          'Format 1 (Card View - Two Rows per Player):\n'
          '   Every player\'s 18 holes are split across TWO STACKED ROWS OF 9 HOLES:\n'
          '   - Player name is on the left under their avatar (e.g., "Hiren B.", "Chet M.", "Neal P.").\n'
          '   - TOP ROW: Exactly 9 scores (Holes 1 to 9 / Front 9), followed by the Front 9 subtotal (e.g. 44, 47) and To Par badge.\n'
          '   - BOTTOM ROW directly underneath: Back 9 scores (Holes 10 to 18), followed by Back 9 subtotal (e.g. 39, 45).\n'
          '   - Combine both into a single array of $holeCount gross scores in hole order: [H1, H2, ..., H9, H10, ..., H18].\n'
          '   - If a hole has no score or is blank, use null for that hole.\n\n'
          'Format 2 (Table View - Gross & Net Rows):\n'
          '   - Each player has a "Gross" row and a "Net" row.\n'
          '   - CRITICAL: Extract ONLY the "Gross" row scores! Ignore the "Net" row completely! DO NOT combine Gross and Net rows together!\n'
          '   - If only 9 holes are visible in the table (Holes 1 to 9), return the visible 9 gross scores padded to $holeCount with nulls (or the full $holeCount if all are shown).\n\n'
          'GENERAL RULES:\n'
          '1. SHAPES & SYMBOLS:\n'
          '   - Numbers inside dark circles are birdies/pars; numbers inside grey/black boxes are bogeys/doubles.\n'
          '   - Always read the gross score number inside each shape or circle.\n'
          '2. SUB-TOTALS & TOTALS:\n'
          '   - DO NOT include subtotals (e.g. 37, 39, 42, 44, 45, 47) or final totals (e.g. 76, 81, 86, 89) in the hole scores list.\n'
          '3. IGNORE NON-SCORE SECTIONS:\n'
          '   - Ignore the partially visible card peeking in on the far right edge of the screen.\n'
          '   - Ignore the "Share to" menu sheet at the bottom of the screenshot.\n\n'
          'Return ONLY one valid JSON object adhering strictly to this schema:\n'
          '{"rows": [{"playerName": "...", "scores": [exactly $holeCount integers or nulls]}]}'
        : 'Targeted recovery: find the player belonging to "$targetPlayerName" on this completed 18Birdies golf scorecard.\n'
          'Note: If 18 holes are split across two stacked rows (Top = Front 9 Holes 1-9, Bottom = Back 9 Holes 10-18), combine both into $holeCount gross scores in hole order: [H1..H18].\n'
          'If the scorecard has separate Gross and Net rows, extract ONLY the Gross row.\n'
          'Do not include subtotals (37, 39) or totals (76, 81).\n'
          'Return exactly that one player row with $holeCount gross scores. Return ONLY valid JSON: {"rows": [{"playerName": "...", "scores": [...]}]}';

    final result = await generateWithFallback(
      prompt: promptText,
      imageBytes: bytes,
      mimeType: mimeType,
      explicitPrimaryKey: explicitApiKey,
    );

    final draft = parsePlayerScorecardResponse(result.text, holeCount: holeCount);
    if (result.warning != null) {
      draft.warnings.insert(0, result.warning!);
    }
    return draft;
  }

  /// COURSE OCR: Analyzes course scorecard photo and extracts course name, holes, pars, handicaps, and tees.
  static Future<CourseImportData> analyzeCourseScorecard(
    String imagePath, {
    String? explicitApiKey,
    String? defaultCourseName,
  }) async {
    final bytes = await File(imagePath).readAsBytes();
    if (bytes.isEmpty) throw const FormatException('The image file is empty.');

    final mimeType = imagePath.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';

    final promptText = '''
Extract the golf course scorecard information from this image.
${defaultCourseName != null && defaultCourseName.isNotEmpty ? 'The course name is likely: "$defaultCourseName".' : ''}

Output ONLY valid, raw JSON (no conversational text, no markdown backticks, no code fences) adhering strictly to this JSON format for the Arcadia Golf Trip app:

{
  "name": "Course Name",
  "city": "City",
  "state": "State abbreviation (e.g. MI)",
  "holeCount": 18,
  "holes": [
    {"holeNumber": 1, "par": 4, "strokeIndex": 7},
    {"holeNumber": 2, "par": 3, "strokeIndex": 15},
    {"holeNumber": 3, "par": 5, "strokeIndex": 3},
    {"holeNumber": 4, "par": 4, "strokeIndex": 11},
    {"holeNumber": 5, "par": 4, "strokeIndex": 1},
    {"holeNumber": 6, "par": 3, "strokeIndex": 17},
    {"holeNumber": 7, "par": 4, "strokeIndex": 5},
    {"holeNumber": 8, "par": 5, "strokeIndex": 9},
    {"holeNumber": 9, "par": 4, "strokeIndex": 13},
    {"holeNumber": 10, "par": 4, "strokeIndex": 8},
    {"holeNumber": 11, "par": 4, "strokeIndex": 12},
    {"holeNumber": 12, "par": 3, "strokeIndex": 16},
    {"holeNumber": 13, "par": 5, "strokeIndex": 2},
    {"holeNumber": 14, "par": 4, "strokeIndex": 10},
    {"holeNumber": 15, "par": 4, "strokeIndex": 6},
    {"holeNumber": 16, "par": 3, "strokeIndex": 18},
    {"holeNumber": 17, "par": 5, "strokeIndex": 4},
    {"holeNumber": 18, "par": 4, "strokeIndex": 14}
  ],
  "tees": [
    {
      "name": "Championship",
      "courseRating": 74.2,
      "slopeRating": 140,
      "totalYardage": 7050,
      "yardages": {
        "1": 420, "2": 190, "3": 545, "4": 410, "5": 435, "6": 175, "7": 415, "8": 530, "9": 405,
        "10": 425, "11": 395, "12": 180, "13": 555, "14": 410, "15": 440, "16": 165, "17": 540, "18": 415
      }
    }
  ]
}

Ensure all holes have their par (3, 4, or 5) and stroke index (handicap ranking 1 to 18). Extract all visible tee boxes with ratings and yardages.
''';

    final result = await generateWithFallback(
      prompt: promptText,
      imageBytes: bytes,
      mimeType: mimeType,
      explicitPrimaryKey: explicitApiKey,
    );

    return CourseImportService.parseJson(result.text);
  }

  static RoundScoreImportDraft parsePlayerScorecardResponse(
    String response, {
    required int holeCount,
  }) {
    final json = AiResponseJsonDecoder.decodeObject(response);
    final rows = <ImportedPlayerScoreRow>[];
    final rawRows = json['rows'] ?? json['players'] ?? json['data'] ?? json['scorecard'] ?? json['results'];
    if (rawRows is List) {
      for (final raw in rawRows.whereType<Map>()) {
        final row = raw.map((key, value) => MapEntry(key.toString(), value));
        final rawScores = row['scores'] ?? row['grossScores'] ?? row['gross_scores'] ?? row['holeScores'] ?? row['holes'] ?? row['score'];
        final scores = <int?>[];
        if (rawScores is List) {
          scores.addAll(
            rawScores.map((value) => value is num ? value.round() : null),
          );
        } else if (rawScores is Map) {
          // If keys are hole numbers like "1", "2", ...
          final sortedKeys = rawScores.keys.toList()
            ..sort((a, b) {
              final aNum = int.tryParse(a.toString()) ?? 0;
              final bNum = int.tryParse(b.toString()) ?? 0;
              return aNum.compareTo(bNum);
            });
          for (final key in sortedKeys) {
            final val = rawScores[key];
            scores.add(val is num ? val.round() : null);
          }
        }
        final paddedScores = <int?>[
          ...scores.take(holeCount),
          ...List<int?>.filled(
            (holeCount - scores.length).clamp(0, holeCount),
            null,
          ),
        ];
        final nameCandidate = row['playerName'] ?? row['player'] ?? row['name'] ?? row['player_name'] ?? row['sourceLabel'] ?? row['label'];
        rows.add(
          ImportedPlayerScoreRow(
            sourceLabel: nameCandidate != null && nameCandidate.toString().trim().isNotEmpty
                ? nameCandidate.toString().trim()
                : 'Detected row ${rows.length + 1}',
            scores: paddedScores,
            sourceText: jsonEncode(row),
          ),
        );
      }
    }

    final warnings = <String>[];
    final rawWarnings = json['warnings'];
    if (rawWarnings is List) {
      for (final item in rawWarnings) {
        if (item != null && item.toString().trim().isNotEmpty) {
          warnings.add(item.toString().trim());
        }
      }
    }

    if (rows.isEmpty) {
      throw const FormatException(
        'The AI response did not contain any player score rows.',
      );
    }

    // Filter out explicit Net rows if Gross or standard rows are present
    final nonNetRows = rows.where((r) => !RegExp(r'\bnet\b', caseSensitive: false).hasMatch(r.sourceLabel)).toList();
    final effectiveRows = nonNetRows.isNotEmpty ? nonNetRows : rows;

    final finalRows = _mergeTwoRowScoresIfNeeded(effectiveRows, holeCount);

    return RoundScoreImportDraft(
      holeCount: holeCount,
      rows: finalRows,
      warnings: warnings,
    );
  }

  static List<ImportedPlayerScoreRow> _mergeTwoRowScoresIfNeeded(
    List<ImportedPlayerScoreRow> rows,
    int holeCount,
  ) {
    if (holeCount != 18 || rows.length < 2) return rows;

    // Check if rows represent split 9-hole rows (each has <= 10 non-null scores)
    final allArePartial = rows.every((r) => r.enteredScoreCount <= 10);
    if (!allArePartial) return rows;

    final merged = <ImportedPlayerScoreRow>[];

    // Case 1: Pair rows by player name if names match after stripping front/back qualifiers
    final nameGroups = <String, List<ImportedPlayerScoreRow>>{};
    for (final r in rows) {
      final key = _normalizePlayerKey(r.sourceLabel);
      nameGroups.putIfAbsent(key, () => []).add(r);
    }

    final allPairs = nameGroups.values.every((group) => group.length == 2);
    if (allPairs && nameGroups.isNotEmpty) {
      for (final entry in nameGroups.entries) {
        final pair = entry.value;
        final frontScores = pair[0].scores.take(9).toList();
        final backScores = pair[1].scores.take(9).toList();
        final combined = <int?>[
          ...frontScores,
          ...List<int?>.filled((9 - frontScores.length).clamp(0, 9), null),
          ...backScores,
          ...List<int?>.filled((9 - backScores.length).clamp(0, 9), null),
        ];
        merged.add(
          ImportedPlayerScoreRow(
            sourceLabel: _cleanPlayerName(pair[0].sourceLabel),
            scores: combined,
            sourceText: '${pair[0].sourceText}\n${pair[1].sourceText}',
          ),
        );
      }
      return merged;
    }

    // Case 2: Even number of rows (e.g. 2, 4, 6) -> merge consecutive pairs [0]+[1], [2]+[3]
    // only if the two rows do not represent distinct named players.
    if (rows.length % 2 == 0) {
      var canMergePairs = true;
      for (var i = 0; i < rows.length; i += 2) {
        final frontName = _cleanPlayerName(rows[i].sourceLabel);
        final backName = _cleanPlayerName(rows[i + 1].sourceLabel);
        if (frontName.isNotEmpty &&
            backName.isNotEmpty &&
            !frontName.startsWith('Detected player') &&
            !backName.startsWith('Detected player') &&
            _normalizePlayerKey(frontName) != _normalizePlayerKey(backName)) {
          canMergePairs = false;
          break;
        }
      }

      if (canMergePairs) {
        for (var i = 0; i < rows.length; i += 2) {
          final front = rows[i];
          final back = rows[i + 1];
          final frontScores = front.scores.take(9).toList();
          final backScores = back.scores.take(9).toList();
          final combined = <int?>[
            ...frontScores,
            ...List<int?>.filled((9 - frontScores.length).clamp(0, 9), null),
            ...backScores,
            ...List<int?>.filled((9 - backScores.length).clamp(0, 9), null),
          ];
          merged.add(
            ImportedPlayerScoreRow(
              sourceLabel: _cleanPlayerName(front.sourceLabel),
              scores: combined,
              sourceText: '${front.sourceText}\n${back.sourceText}',
            ),
          );
        }
        return merged;
      }
    }

    return rows;
  }

  static String _normalizePlayerKey(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'\b(front|back|f9|b9|out|in|1-9|10-18|holes?)\b'), '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  static String _cleanPlayerName(String name) {
    return name
        .replaceAll(RegExp(r'\s*[\(\[\{][^\)\]\}]*(?:front|back|f9|b9|out|in|1-9|10-18|hole)[^\)\]\}]*[\)\]\}]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(?:front\s*9?|back\s*9?|f9|b9|out|in)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'[:|\-–—_]+$'), '')
        .trim();
  }
}

class GeminiOcrResult {
  const GeminiOcrResult({
    required this.text,
    required this.model,
    required this.keyLabel,
    required this.wasFallback,
    this.warning,
  });

  final String text;
  final String model;
  final String keyLabel;
  final bool wasFallback;
  final String? warning;
}

class _GeminiAttemptPlan {
  const _GeminiAttemptPlan({
    required this.model,
    required this.apiKey,
    required this.label,
  });

  final String model;
  final String apiKey;
  final String label;
}
