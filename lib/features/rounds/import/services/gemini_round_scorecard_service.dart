import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../shared/services/app_settings_service.dart';
import '../models/round_score_import_draft.dart';
import 'ai_response_json_decoder.dart';

class GeminiRoundScorecardService {
  // Built-in API key support or system property
  static String? apiKey;

  static const String defaultModel = 'gemini-2.5-flash';

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

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$defaultModel:generateContent?key=$key',
    );

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

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      throw FormatException(
        'Gemini API error (${response.statusCode}): ${response.body}',
      );
    }

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

    return parseResponse(text, holeCount: holeCount);
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
