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

CRITICAL SCORECARD LAYOUT INSTRUCTIONS:
1. TWO-ROW 18-HOLE SCORECARDS (18Birdies, Golfshot, digital apps, & folded paper cards):
   - In many scorecard formats (including 18Birdies digital cards), each player's 18 holes are split into TWO STACKED ROWS OF 9 HOLES:
     * TOP ROW: Front 9 (Holes 1 to 9), followed by the Front 9 subtotal (OUT).
     * BOTTOM ROW directly beneath: Back 9 (Holes 10 to 18), followed by the Back 9 subtotal (IN).
     * Right side: 18-hole total score and to-par indicator (e.g., +5 (76)).
   - YOU MUST COMBINE BOTH ROWS FOR EACH PLAYER:
     * Extract Holes 1 through 9 from the TOP row.
     * Extract Holes 10 through 18 from the BOTTOM row directly underneath.
     * Combine them into a single array of exactly $holeCount gross scores in hole order: [H1, H2, ..., H9, H10, ..., H18].
     * NEVER stop after reading the first 9 holes.
     * Do NOT include the 9-hole subtotal (OUT/IN) or the 18-hole total (e.g. 37, 39, 76) in the hole scores array.
     * Sanity check: sum(H1..H9) must equal the front-9 subtotal; sum(H10..H18) must equal the back-9 subtotal.

2. SINGLE-ROW SCORECARDS:
   - If all holes for a player are displayed across a single horizontal row, read all $holeCount gross scores in hole order from left to right.

3. PLAYERS & ROWS:
   - Count every visible player in the photo from top to bottom.
   - The expected-player list ($players) is a name-matching aid, NOT a limit on the number of players.
   - For every player found, return one row with their name and exactly $holeCount gross scores in hole order.
   - Use the closest expected player name when confident; otherwise use the name visible on the card (or "Unknown Row 1", etc.).
   - If a score cannot be determined, use null and explain in warnings.

Return ONLY one valid JSON object with this exact structure, without Markdown fences or commentary:
{
  "rows": [
    {
      "playerName": "player name",
      "scores": [exactly $holeCount gross scores in hole order]
    }
  ],
  "warnings": ["short notes if any"]
}

Before answering, verify:
- Did you read BOTH the top row (Holes 1-9) AND bottom row (Holes 10-18) for each player?
- Does every player in "rows" have exactly $holeCount gross scores in hole order?
''';
  }
}
