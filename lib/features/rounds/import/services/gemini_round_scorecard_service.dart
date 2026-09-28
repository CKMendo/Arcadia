import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../shared/services/app_settings_service.dart';
import '../models/round_score_import_draft.dart';
import 'ai_response_json_decoder.dart';

class GeminiRoundScorecardService {
  // Built-in API key support or system property
  static String? apiKey;

  static const String defaultModel = 'gemini-3.8-flash';

  /// Prioritized candidate models in the Gemini 3 family.
  /// If 3.8 encounters Google server 503 high-demand spikes, the service
  /// automatically retries and seamlessly fails over to sibling models in the fleet.
  static const List<String> candidateModels = [
    'gemini-3.8-flash',
    'gemini-3.6-flash',
    'gemini-3.7-flash',
    'gemini-3.5-flash',
  ];

  Future<RoundScoreImportDraft> analyze(
    String imagePath, {
    required int holeCount,
    String? targetPlayerName,
    List<ImportedPlayerScoreRow> existingRows = const [],
  }) async {
    final bytes = await File(imagePath).readAsBytes();
    if (bytes.isEmpty) throw const FormatException('The image file is empty.');

    final key = apiKey ?? await AppSettingsService.getGeminiApiKey();
    if (key == null || key.isEmpty) {
      throw const FormatException(
        'Gemini API key not configured. Tap Configure Key below, use FREE ON-DEVICE, or select '
        'GEMINI in the External AI assistant to copy prompt and paste response.',
      );
    }

    final base64Image = base64Encode(bytes);
    final mimeType = imagePath.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';

    final promptText = targetPlayerName == null
        ? 'Read only the handwritten or entered player gross scores '
          'from this completed golf scorecard photo. Inspect every '
          'physical player row from top to bottom and return one '
          'row per player with exactly $holeCount scores in hole '
          'order. Count and return every physical row without stopping early. '
          'Ignore printed par, yardage, handicap, OUT, IN, and total rows or '
          'columns. Return ONLY one valid JSON object with {"rows": [{"playerName": "...", "scores": [...]}]}'
        : 'Targeted recovery: find the physical score row belonging '
          'to "$targetPlayerName" on this completed golf scorecard. Return exactly that one player row with '
          '$holeCount gross scores in hole order. Return ONLY valid JSON: {"rows": [{"playerName": "...", "scores": [...]}]}';

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

    String? lastErrorDetail;
    int lastStatusCode = 0;

    for (final model in candidateModels) {
      // Allow up to 2 attempts per model for transient errors
      for (var attempt = 1; attempt <= 2; attempt++) {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key',
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
            if (model != defaultModel) {
              draft.warnings.insert(
                0,
                'Gemini 3.8 Flash had high demand on Google servers; automatically read using $model.',
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

          // If unauthorized or bad key, fail immediately without looping
          if (response.statusCode == 400 || response.statusCode == 403) {
            throw FormatException('Gemini API authentication failed (${response.statusCode}): $extractedMsg');
          }

          // If 503 (high demand) or 429 (rate limit), wait briefly if retrying same model
          if ((response.statusCode == 503 || response.statusCode == 429) && attempt < 2) {
            await Future.delayed(const Duration(milliseconds: 1200));
            continue;
          } else {
            // Move to next candidate model in the fallback chain
            break;
          }
        } catch (e) {
          if (e is FormatException && (lastStatusCode == 400 || lastStatusCode == 403)) {
            rethrow;
          }
          lastErrorDetail = e.toString();
          if (attempt < 2) {
            await Future.delayed(const Duration(milliseconds: 1000));
          }
        }
      }
    }

    if (lastStatusCode == 503) {
      throw const FormatException(
        'Google Gemini is currently experiencing temporary high demand (503 UNAVAILABLE) on Google servers. '
        'The app automatically attempted retries and model failover. '
        'Please wait a moment and tap RE-READ WITH GEMINI, or switch to FREE ON-DEVICE OCR.',
      );
    } else if (lastStatusCode == 429) {
      throw const FormatException(
        'Gemini API request limit reached (429 RESOURCE_EXHAUSTED). '
        'Please wait a few moments and tap RE-READ WITH GEMINI, or switch to FREE ON-DEVICE OCR.',
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
