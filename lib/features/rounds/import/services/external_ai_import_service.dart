import 'package:flutter/services.dart';
import '../../../../shared/services/device_communication_service.dart';

enum ExternalAiAssistant { chatGpt, claude, gemini }

extension ExternalAiAssistantDetails on ExternalAiAssistant {
  String get label => switch (this) {
    ExternalAiAssistant.chatGpt => 'ChatGPT',
    ExternalAiAssistant.claude => 'Claude',
    ExternalAiAssistant.gemini => 'Gemini',
  };

  String get packageName => switch (this) {
    ExternalAiAssistant.chatGpt => 'com.openai.chatgpt',
    ExternalAiAssistant.claude => 'com.anthropic.claude',
    ExternalAiAssistant.gemini => 'com.google.android.apps.bard',
  };

  String get fallbackUrl => switch (this) {
    ExternalAiAssistant.chatGpt => 'https://chatgpt.com/',
    ExternalAiAssistant.claude => 'https://claude.ai/new',
    ExternalAiAssistant.gemini => 'https://gemini.google.com/app',
  };
}

class ExternalAiImportService {
  const ExternalAiImportService([
    this._communication = const DeviceCommunicationService(),
  ]);

  final DeviceCommunicationService _communication;

  Future<bool> copyPromptAndOpen({
    required ExternalAiAssistant assistant,
    required String prompt,
  }) async {
    await Clipboard.setData(ClipboardData(text: prompt));
    return _communication.openAiAssistant(
      packageName: assistant.packageName,
      fallbackUrl: assistant.fallbackUrl,
    );
  }

  String roundPrompt({
    required int holeCount,
    required List<String> playerNames,
  }) {
    final players = playerNames.join(', ');
    return '''
You are extracting player gross scores from a completed golf scorecard photo.

I will attach the scorecard photo after this prompt. The expected players are: $players.

First count all physical player score rows in the photo. The expected-player list is only a name-matching aid and is NOT a limit on the number of rows. The card may contain fewer or more rows than the expected-player list, including more than four rows.

Read each physical player score row independently from top to bottom. Return one row for every visible player row, regardless of how many rows exist and even when a handwritten name is difficult to read. Never merge, reorder, or skip a score row. Each row must contain exactly $holeCount gross scores in hole order. Ignore printed par, yardage, handicap, OUT, IN, TOTAL, and NET rows or columns. Use the closest expected player name when confident; otherwise label it "Unknown Row 1", "Unknown Row 2", and so on. Do not guess an unreadable score; use null and explain it in warnings.

Return ONLY one valid JSON object with this exact structure, without Markdown or commentary:
{
  "rows": [
    {
      "playerName": "name associated with this physical row",
      "scores": [exactly $holeCount integers or null values]
    }
  ],
  "warnings": ["short notes about uncertain names or scores"]
}

Before answering, count the physical player rows again, confirm the JSON contains that same number of rows, and verify that each scores array contains exactly $holeCount positions.
''';
  }
}
