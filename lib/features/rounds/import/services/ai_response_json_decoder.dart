import 'dart:convert';

class AiResponseJsonDecoder {
  const AiResponseJsonDecoder._();

  /// Decodes AI responses from Gemini, ChatGPT, or Claude into a normalized Map.
  /// Handles:
  /// - JSON objects: `{"rows": [...]}` or `{"players": [...]}`
  /// - JSON lists: `[{"playerName": "...", "scores": [...]}]` (wrapped into `{"rows": ...}`)
  /// - Markdown code blocks (```json ... ```)
  /// - Text before or after the JSON block
  /// - Trailing commas before `}` or `]`
  /// - Single quotes around keys or string values
  static Map<String, dynamic> decodeObject(String response) {
    final trimmed = response.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Paste the AI response before importing.');
    }

    final candidates = <String>[];

    // 1. Extract markdown code fences
    final fenceMatches = RegExp(
      r'```(?:json)?\s*([\s\S]*?)```',
      caseSensitive: false,
    ).allMatches(trimmed);
    for (final match in fenceMatches) {
      final inside = match.group(1)?.trim();
      if (inside != null && inside.isNotEmpty) {
        candidates.add(inside);
      }
    }

    // 2. Extract substring between first '{' and last '}'
    final firstBrace = trimmed.indexOf('{');
    final lastBrace = trimmed.lastIndexOf('}');
    if (firstBrace >= 0 && lastBrace > firstBrace) {
      candidates.add(trimmed.substring(firstBrace, lastBrace + 1));
    }

    // 3. Extract substring between first '[' and last ']' (in case root is a JSON array)
    final firstBracket = trimmed.indexOf('[');
    final lastBracket = trimmed.lastIndexOf(']');
    if (firstBracket >= 0 && lastBracket > firstBracket) {
      candidates.add(trimmed.substring(firstBracket, lastBracket + 1));
    }

    // 4. Raw trimmed string
    candidates.add(trimmed);

    for (final rawCandidate in candidates.where((value) => value.isNotEmpty)) {
      // Try candidate as-is, and with trailing commas stripped
      final variations = [
        rawCandidate,
        _stripTrailingCommas(rawCandidate),
        _fixSingleQuotes(rawCandidate),
      ];

      for (final text in variations) {
        try {
          final decoded = jsonDecode(text);
          if (decoded is Map) {
            final map = decoded.map((key, value) => MapEntry(key.toString(), value));
            // Check if rows are present directly or under other common keys
            if (map.containsKey('rows') || map.containsKey('players')) {
              return map;
            }
            if (map.containsKey('data') && map['data'] is Map) {
              return (map['data'] as Map).map((k, v) => MapEntry(k.toString(), v));
            }
            if (map.containsKey('data') && map['data'] is List) {
              return {'rows': map['data']};
            }
            if (map.containsKey('scorecard') && map['scorecard'] is Map) {
              return (map['scorecard'] as Map).map((k, v) => MapEntry(k.toString(), v));
            }
            if (map.containsKey('scorecard') && map['scorecard'] is List) {
              return {'rows': map['scorecard']};
            }
            return map;
          } else if (decoded is List) {
            // Root is an array of player objects! Wrap into {"rows": [...]}
            return {'rows': decoded};
          }
        } on FormatException {
          // Continue to next variation/candidate
        }
      }
    }

    throw const FormatException(
      'The pasted response did not contain valid JSON. Ask the AI to return '
      'only the requested JSON, then copy its complete response.',
    );
  }

  static String _stripTrailingCommas(String input) {
    var text = input;
    for (var i = 0; i < 3; i++) {
      text = text.replaceAllMapped(RegExp(r',\s*(\}|\])'), (m) => m.group(1)!);
    }
    return text;
  }

  static String _fixSingleQuotes(String input) {
    if (!input.contains("'")) return input;
    // Replace single quotes used as JSON string/key delimiters with double quotes
    return input.replaceAllMapped(
      RegExp(r"(?<=[{\[,:\s])'([^'\\]*(?:\\.[^'\\]*)*)'(?=[}\],:\s])"),
      (m) => '"${m.group(1)}"',
    );
  }
}
