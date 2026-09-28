import 'dart:convert';

class AiResponseJsonDecoder {
  const AiResponseJsonDecoder._();

  static Map<String, dynamic> decodeObject(String response) {
    final trimmed = response.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Paste the AI response before importing.');
    }

    final candidates = <String>[
      trimmed,
      ...RegExp(
        r'```(?:json)?\s*([\s\S]*?)```',
        caseSensitive: false,
      ).allMatches(trimmed).map((match) => match.group(1)?.trim() ?? ''),
    ];
    final firstBrace = trimmed.indexOf('{');
    final lastBrace = trimmed.lastIndexOf('}');
    if (firstBrace >= 0 && lastBrace > firstBrace) {
      candidates.add(trimmed.substring(firstBrace, lastBrace + 1));
    }

    for (final candidate in candidates.where((value) => value.isNotEmpty)) {
      try {
        final decoded = jsonDecode(candidate);
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } on FormatException {
        // Try the next candidate, including JSON inside a Markdown fence.
      }
    }
    throw const FormatException(
      'The pasted response did not contain valid JSON. Ask the AI to return '
      'only the requested JSON, then copy its complete response.',
    );
  }
}
