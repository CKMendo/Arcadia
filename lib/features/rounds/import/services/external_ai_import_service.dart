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
    final is18Holes = holeCount >= 18;
    return '''
You are extracting player gross scores from a completed golf scorecard photo.

I will attach the scorecard photo after this prompt. Expected players: $players.

${is18Holes ? '''CRITICAL 18BIRDIES TWO-ROW SCORECARD FORMAT (TWO-ROW 18-HOLE SCORECARDS):
All scorecard photos in this app are in the 18Birdies two-row layout:
1. TWO ROWS PER PLAYER:
   For EACH player, their 18 holes are split across TWO STACKED ROWS OF 9 BOXES:
   - Player avatar and name are on the left (e.g., "Chet M.", "Neal P.").
   - TOP ROW: Front 9 (Holes 1 to 9), followed by the 9-hole subtotal (e.g., 37 or 42) and To Par badge (+5).
   - BOTTOM ROW directly beneath: Back 9 (Holes 10 to 18), followed by the 9-hole subtotal (e.g., 39).
   
2. COMBINE BOTH ROWS INTO ONE 18-HOLE ARRAY:
   - Extract Holes 1 through 9 from the TOP row.
   - Extract Holes 10 through 18 from the BOTTOM row directly underneath.
   - Combine both into a SINGLE array of exactly 18 gross scores in hole order:
     [H1, H2, H3, H4, H5, H6, H7, H8, H9, H10, H11, H12, H13, H14, H15, H16, H17, H18]
   - CRITICAL: Both rows belong to the SAME player! DO NOT treat top and bottom rows as separate players!
   - Every player must have exactly 18 scores.
   - Do NOT include the 9-hole subtotals (37, 39, 42) or final totals (76, 81) in the scores array.

3. SCORE SHAPES & SYMBOLS:
   - Numbers inside dark circles are birdies/pars; numbers in grey squares are bogeys/doubles.
   - Always read the gross score number inside each shape.

4. MATHEMATICAL SANITY CHECK:
   - Sum of holes 1 to 9 MUST equal the front-9 subtotal (e.g. 5+3+5+5+4+5+4+3+3 = 37).
   - Sum of holes 10 to 18 MUST equal the back-9 subtotal (e.g. 5+3+5+3+4+5+4+5+5 = 39).

5. IGNORE NON-SCORE ELEMENTS:
   - Ignore the partially visible second card peeking in on the far right edge of the screen.
   - Ignore the "Share to" menu sheet at the bottom of the screenshot.''' : '''Read each physical player score row from top to bottom. Each player row must contain exactly $holeCount gross scores in hole order. Ignore printed par, yardage, handicap, OUT, IN, and total rows.'''}

Return ONLY one valid JSON object adhering strictly to this schema, without Markdown commentary:
{
  "rows": [
    {
      "playerName": "player name",
      "scores": [exactly ${is18Holes ? 18 : holeCount} gross scores in hole order]
    }
  ],
  "warnings": ["short notes if any"]
}
''';
  }
}
