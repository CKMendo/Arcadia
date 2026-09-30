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
  static const String backupModel = 'gemini-3.7-flash';
  static const String fallbackModel = 'gemini-3.6-flash';

  static const String primaryModelLabel = 'Gemini 3.8 Flash';
  static const String backupModelLabel = 'Gemini 3.7 Flash';
  static const String fallbackModelLabel = 'Gemini 3.6 Flash';

  /// Validates a Gemini API key using the unified Gemini 3 family models.
  static Future<bool> validateApiKey(String apiKey) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) return false;

    final modelsToTry = [primaryModel, backupModel, fallbackModel];
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
        'Gemini API key not configured. Tap Configure Key below to set your Primary (3.8) and Backup (3.7) keys, '
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

    // Execution plan:
    // 1) Gemini 3.8 Flash with Primary Key
    // 2) Gemini 3.8 Flash with Secondary Key (if Primary hits 503/429)
    // 3) Gemini 3.7 Flash with Secondary Key (as requested: "if 3.8 is not working, 3.7 should be used")
    // 4) Gemini 3.7 Flash with Primary Key
    // 5) Gemini 3.6 Flash (emergency fleet fallback if Google servers are busy)
    final plan = <_GeminiAttemptPlan>[
      if (primaryKey != null && primaryKey.isNotEmpty)
        _GeminiAttemptPlan(model: primaryModel, apiKey: primaryKey, label: 'Gemini 3.8 (Primary Key)'),
      if (secondaryKey != null && secondaryKey.isNotEmpty && secondaryKey != primaryKey)
        _GeminiAttemptPlan(model: primaryModel, apiKey: secondaryKey, label: 'Gemini 3.8 (Secondary Key)'),
      if (secondaryKey != null && secondaryKey.isNotEmpty)
        _GeminiAttemptPlan(model: backupModel, apiKey: secondaryKey, label: 'Gemini 3.7 (Secondary Key)'),
      if (primaryKey != null && primaryKey.isNotEmpty)
        _GeminiAttemptPlan(model: backupModel, apiKey: primaryKey, label: 'Gemini 3.7 (Primary Key)'),
      if (secondaryKey != null && secondaryKey.isNotEmpty)
        _GeminiAttemptPlan(model: fallbackModel, apiKey: secondaryKey, label: 'Gemini 3.6 (Secondary Key)'),
      if (primaryKey != null && primaryKey.isNotEmpty)
        _GeminiAttemptPlan(model: fallbackModel, apiKey: primaryKey, label: 'Gemini 3.6 (Primary Key)'),
    ];

    String? lastErrorDetail;
    int lastStatusCode = 0;

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
            .timeout(timeout);

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
              ? 'Gemini 3.8 Flash was unavailable; automatically analyzed using ${step.model == backupModel ? 'Gemini 3.7 Flash' : 'Gemini 3.6 Flash'}.'
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
        lastErrorDetail = extractedMsg;

        if (response.statusCode == 503 || response.statusCode == 429) {
          await Future.delayed(const Duration(milliseconds: 600));
        }
      } catch (e) {
        lastErrorDetail = e.toString();
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }

    if (lastStatusCode == 503) {
      throw const FormatException(
        'Google Gemini is currently experiencing high demand (503 UNAVAILABLE). '
        'Tried Gemini 3.8 and Gemini 3.7 with both configured API keys. '
        'Please wait a moment and tap RE-READ WITH GEMINI, or switch to FREE ON-DEVICE OCR.',
      );
    } else if (lastStatusCode == 429) {
      throw const FormatException(
        'Gemini API request rate limit reached (429 RESOURCE_EXHAUSTED). '
        'Tried both configured API keys. Please wait a moment and tap RE-READ WITH GEMINI.',
      );
    } else {
      throw FormatException(
        'Gemini API error ($lastStatusCode): ${lastErrorDetail ?? 'Service temporarily unavailable.'}',
      );
    }
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
        ? 'Extract player gross scores from this completed golf scorecard photo.\n'
          'LAYOUT INSTRUCTIONS:\n'
          '1. Many digital scorecards (e.g. 18Birdies, Golfshot) and paper cards split 18 holes into TWO ROWS per player:\n'
          '   - Top row: Front 9 (Holes 1 to 9), followed by Front 9 subtotal (OUT).\n'
          '   - Bottom row: Back 9 (Holes 10 to 18), followed by Back 9 subtotal (IN).\n'
          '   - For each player, COMBINE both rows into a single list of $holeCount gross scores in exact hole order (Hole 1 to $holeCount).\n'
          '2. If all 18 holes are on a single horizontal row, read all 18 scores across.\n'
          '3. Inspect every visible player from top to bottom and return one row per player with exactly $holeCount gross scores.\n'
          '4. Do NOT include Front 9 / Back 9 subtotals (OUT/IN) or 18-hole total scores in the scores list.\n'
          '5. Ignore printed par, yardage, handicap, and ratings.\n'
          'Return ONLY one valid JSON object with {"rows": [{"playerName": "...", "scores": [...]}]}'
        : 'Targeted recovery: find the player belonging to "$targetPlayerName" on this completed golf scorecard.\n'
          'Note: 18 holes may be split across two stacked rows (Top = Front 9, Bottom = Back 9). Combine both into $holeCount gross scores in hole order.\n'
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
    final rawRows = json['rows'];
    if (rawRows is List) {
      for (final raw in rawRows.whereType<Map>()) {
        final row = raw.map((key, value) => MapEntry(key.toString(), value));
        final scores = row['scores'] is List
            ? (row['scores'] as List)
                .map((value) => value is num ? value.round() : null)
                .toList()
            : <int?>[];
        final paddedScores = <int?>[
          ...scores.take(holeCount),
          ...List<int?>.filled(
            (holeCount - scores.length).clamp(0, holeCount),
            null,
          ),
        ];
        rows.add(
          ImportedPlayerScoreRow(
            sourceLabel: row['playerName']?.toString().trim().isNotEmpty == true
                ? row['playerName'].toString().trim()
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

    return RoundScoreImportDraft(
      holeCount: holeCount,
      rows: rows,
      warnings: warnings,
    );
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
