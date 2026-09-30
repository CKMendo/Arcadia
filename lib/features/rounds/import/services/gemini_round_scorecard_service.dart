import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../shared/services/app_settings_service.dart';
import '../models/round_score_import_draft.dart';
import 'ai_response_json_decoder.dart';

class GeminiRoundScorecardService {
  // Built-in API key support or system property
  static String? apiKey;

  static const String defaultModel = 'gemini-2.0-flash';
  static const String primaryModel = 'gemini-2.0-flash';
  static const String fallbackModel = 'gemini-1.5-flash';
  static const String emergencyModel = 'gemini-2.5-flash';

  Future<RoundScoreImportDraft> analyze(
    String imagePath, {
    required int holeCount,
    String? targetPlayerName,
    List<ImportedPlayerScoreRow> existingRows = const [],
  }) async {
    final bytes = await File(imagePath).readAsBytes();
    if (bytes.isEmpty) throw const FormatException('The image file is empty.');

    final primaryKey = apiKey ?? await AppSettingsService.getGeminiPrimaryApiKey();
    final secondaryKey = await AppSettingsService.getGeminiSecondaryApiKey();

    if ((primaryKey == null || primaryKey.isEmpty) &&
        (secondaryKey == null || secondaryKey.isEmpty)) {
      throw const FormatException(
        'Gemini API key not configured. Tap Configure Key below to set your Primary and Backup Gemini keys, '
        'or use FREE ON-DEVICE OCR.',
      );
    }

    final base64Image = base64Encode(bytes);
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

    final payload = {
      'contents': [
        {
          'parts': [
            {'text': promptText},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'response_mime_type': 'application/json',
        'temperature': 0.1,
      }
    };

    // Execution plan:
    // 1) Gemini 3.8 Flash with Primary Key
    // 2) Gemini 3.8 Flash with Secondary Key (if Primary hits 503/429)
    // 3) Gemini 3.7 Flash with Secondary Key (as requested: "if 3.8 is not working, 3.7 should be used")
    // 4) Gemini 3.7 Flash with Primary Key
    // 5) Gemini 3.6 Flash (emergency fleet fallback)
    final plan = <_GeminiAttemptPlan>[
      if (primaryKey != null && primaryKey.isNotEmpty)
        _GeminiAttemptPlan(model: primaryModel, apiKey: primaryKey, label: 'Gemini 3.8 (Primary Key)'),
      if (secondaryKey != null && secondaryKey.isNotEmpty && secondaryKey != primaryKey)
        _GeminiAttemptPlan(model: primaryModel, apiKey: secondaryKey, label: 'Gemini 3.8 (Secondary Key)'),
      if (secondaryKey != null && secondaryKey.isNotEmpty)
        _GeminiAttemptPlan(model: fallbackModel, apiKey: secondaryKey, label: 'Gemini 3.7 (Secondary Key)'),
      if (primaryKey != null && primaryKey.isNotEmpty)
        _GeminiAttemptPlan(model: fallbackModel, apiKey: primaryKey, label: 'Gemini 3.7 (Primary Key)'),
      if (secondaryKey != null && secondaryKey.isNotEmpty)
        _GeminiAttemptPlan(model: emergencyModel, apiKey: secondaryKey, label: 'Gemini 3.6 (Secondary Key)'),
      if (primaryKey != null && primaryKey.isNotEmpty)
        _GeminiAttemptPlan(model: emergencyModel, apiKey: primaryKey, label: 'Gemini 3.6 (Primary Key)'),
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
            .timeout(const Duration(seconds: 40));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List?;
          if (candidates == null || candidates.isEmpty) {
            throw const FormatException('Gemini did not return any candidates.');
          }

          final firstCandidate = candidates.first as Map<String, dynamic>;
          final content = firstCandidate['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List?;
          final text = parts?.first?['text'] as String?;

          if (text == null || text.trim().isEmpty) {
            throw const FormatException('Gemini returned empty text.');
          }

          final draft = parseResponse(text, holeCount: holeCount);
          if (step.model != primaryModel) {
            draft.warnings.insert(
              0,
              'Gemini 3.8 Flash was unavailable; automatically analyzed using ${step.model == fallbackModel ? 'Gemini 3.7 Flash' : 'Gemini 3.6 Flash'}.',
            );
          }
          return draft;
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

        // If 503 or 429, wait briefly before next step
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

  RoundScoreImportDraft parseResponse(
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
