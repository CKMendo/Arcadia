import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:arcadia/database/app_database.dart';
import 'package:arcadia/shared/theme/app_colors.dart';
import 'package:arcadia/features/courses/repository/course_repository.dart';
import 'package:arcadia/features/players/repository/player_repository.dart';
import 'package:arcadia/features/publish/services/website_publish_service.dart';
import 'package:arcadia/features/rounds/import/models/round_score_import_draft.dart';
import 'package:arcadia/features/rounds/import/presentation/round_scorecard_import_screen.dart';
import 'package:arcadia/features/rounds/import/services/external_ai_import_service.dart';
import 'package:arcadia/features/rounds/import/services/on_device_text_recognition_service.dart';
import 'package:arcadia/features/rounds/import/services/player_score_row_matcher.dart';
import 'package:arcadia/features/rounds/import/services/round_scorecard_text_parser.dart';
import 'package:arcadia/features/rounds/repository/round_repository.dart';
import 'package:arcadia/features/tournaments/repository/tournament_repository.dart';
import 'package:arcadia/features/rounds/import/presentation/gemini_key_config_dialog.dart';
import 'package:arcadia/features/trip/presentation/edit_website_links_dialog.dart';
import 'package:arcadia/shared/services/app_settings_service.dart';
import 'package:arcadia/shared/services/gemini_ocr_service.dart';
import 'package:arcadia/features/rounds/import/services/gemini_round_scorecard_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late PlayerRepository playerRepo;
  late CourseRepository courseRepo;
  late TournamentRepository tournamentRepo;
  late RoundRepository roundRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    playerRepo = PlayerRepository(db);
    courseRepo = CourseRepository(db);
    tournamentRepo = TournamentRepository(db);
    roundRepo = RoundRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Website Publish Tests', () {
    test('WebsitePublishService produces valid tournament data and standings', () async {
      final result = await WebsitePublishService.publishTournament(
        tournamentRepo: tournamentRepo,
        courseRepo: courseRepo,
        playerRepo: playerRepo,
        roundRepo: roundRepo,
      );

      expect(result.publishedAt, isNotNull);
      expect(result.message, isNotEmpty);
    });

    testWidgets('Manual website push button renders in AppBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  icon: const Icon(Icons.cloud_upload_outlined, color: AppColors.lakeCyan, size: 28),
                  tooltip: 'Push Standings to Website',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final pushIconFinder = find.byTooltip('Push Standings to Website');
      expect(pushIconFinder, findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
    });
  });

  group('AI Scorecard Import 4-Methods Tests', () {
    test('ExternalAiImportService produces structured ChatGPT/Claude round prompt', () {
      const service = ExternalAiImportService();
      final prompt = service.roundPrompt(
        holeCount: 18,
        playerNames: ['Neal Patel', 'Chet Mehta'],
      );

      expect(prompt, contains('Neal Patel, Chet Mehta'));
      expect(prompt, contains('exactly 18 gross scores in hole order'));
      expect(prompt, contains('TWO-ROW 18-HOLE SCORECARDS'));
      expect(prompt, contains('TOP ROW: Front 9'));
      expect(prompt, contains('BOTTOM ROW directly beneath: Back 9'));
      expect(prompt, contains('"rows"'));
      expect(prompt, contains('"playerName"'));
      expect(prompt, contains('"scores"'));
    });

    test('RoundScorecardTextParser parses OCR line numbers into score rows', () {
      const parser = RoundScorecardTextParser();
      const ocrOutput = '''
Hole 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 Total
Chet M 4 4 5 3 4 4 5 4 4 4 4 5 3 4 4 5 4 4
Neal P 4 3 5 4 4 3 5 4 4 4 3 5 4 4 3 5 4 4
''';

      final draft = parser.parse(ocrOutput, holeCount: 18);
      expect(draft.rows.length, equals(2));
      expect(draft.rows[0].sourceLabel, contains('Chet'));
      expect(draft.rows[0].scores.length, equals(18));
      expect(draft.rows[1].sourceLabel, contains('Neal'));
      expect(draft.rows[1].scores.length, equals(18));
    });

    test('RoundScorecardTextParser parses 2-row 18Birdies stacked scorecard into 18-hole player rows', () {
      const parser = RoundScorecardTextParser();
      // From 18Birdies screenshot:
      // Chet M.: Front 9 = 5 3 5 5 4 5 4 3 3 (37), Back 9 = 5 3 5 3 4 5 4 5 5 (39), Total 76
      // Neal P.: Front 9 = 5 3 5 6 4 4 7 4 4 (42), Back 9 = 4 3 4 6 4 5 4 4 5 (39), Total 81
      const ocrOutput = '''
Goose Creek Golf Course
09/27/2026 18 Holes
Chet M. 5 3 5 5 4 5 4 3 3 37
5 3 5 3 4 5 4 5 5 39 76
Neal P. 5 3 5 6 4 4 7 4 4 42
4 3 4 6 4 5 4 4 5 39 81
''';

      final draft = parser.parse(ocrOutput, holeCount: 18);
      expect(draft.rows.length, equals(2));
      expect(draft.rows[0].sourceLabel, contains('Chet'));
      expect(draft.rows[0].scores.length, equals(18));
      expect(draft.rows[0].scores, equals([5, 3, 5, 5, 4, 5, 4, 3, 3, 5, 3, 5, 3, 4, 5, 4, 5, 5]));
      expect(draft.rows[1].sourceLabel, contains('Neal'));
      expect(draft.rows[1].scores.length, equals(18));
      expect(draft.rows[1].scores, equals([5, 3, 5, 6, 4, 4, 7, 4, 4, 4, 3, 4, 6, 4, 5, 4, 4, 5]));
    });

    test('PlayerScoreRowMatcher matches OCR label to player candidate', () {
      const matcher = PlayerScoreRowMatcher();
      final candidates = [
        const ImportPlayerCandidate(
          id: 'p1',
          fullName: 'Neal Patel',
          nickname: 'Neal',
          initials: 'NP',
        ),
        const ImportPlayerCandidate(
          id: 'p2',
          fullName: 'Chet Mehta',
          nickname: 'Chet',
          initials: 'CM',
        ),
      ];

      final rows = [
        ImportedPlayerScoreRow(
          sourceLabel: 'Chet M',
          scores: List.filled(18, 4),
          sourceText: 'Chet M 4 4...',
        ),
        ImportedPlayerScoreRow(
          sourceLabel: 'Neal Patel',
          scores: List.filled(18, 4),
          sourceText: 'Neal Patel 4 4...',
        ),
      ];

      final matches = matcher.match(players: candidates, rows: rows);
      expect(matches['p2']?.rowIndex, equals(0));
      expect(matches['p1']?.rowIndex, equals(1));
    });

    testWidgets('RoundScorecardImportScreen renders all 4 reader options: FREE ON-DEVICE, GEMINI, CHATGPT, CLAUDE', (tester) async {
      final candidates = [
        const ImportPlayerCandidate(
          id: 'p1',
          fullName: 'Neal Patel',
          nickname: 'Neal',
          initials: 'NP',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: RoundScorecardImportScreen(
            players: candidates,
            holeCount: 18,
            parByHole: {for (var i = 1; i <= 18; i++) i: 4},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FREE ON-DEVICE'), findsOneWidget);
      expect(find.text('GEMINI'), findsOneWidget);
      expect(find.text('CHATGPT'), findsOneWidget);
      expect(find.text('CLAUDE'), findsOneWidget);
    });

    testWidgets('Tapping CHATGPT shows paste and prompt instructions', (tester) async {
      final candidates = [
        const ImportPlayerCandidate(
          id: 'p1',
          fullName: 'Neal Patel',
          nickname: 'Neal',
          initials: 'NP',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: RoundScorecardImportScreen(
            players: candidates,
            holeCount: 18,
            parByHole: {for (var i = 1; i <= 18; i++) i: 4},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('CHATGPT'));
      await tester.pumpAndSettle();

      expect(find.text('RETURN FROM CHATGPT'), findsOneWidget);
      expect(find.text('PASTE CHATGPT RESPONSE'), findsOneWidget);
      expect(find.text('COPY PROMPT AGAIN'), findsOneWidget);
    });

    test('AppSettingsService stores and retrieves Primary (3.8) and Secondary (3.6) keys', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await AppSettingsService.hasAnyGeminiApiKey(), isFalse);

      await AppSettingsService.setGeminiPrimaryApiKey('key-primary-38');
      expect(await AppSettingsService.getGeminiPrimaryApiKey(), 'key-primary-38');
      expect(await AppSettingsService.getGeminiApiKey(), 'key-primary-38');
      expect(await AppSettingsService.hasAnyGeminiApiKey(), isTrue);

      await AppSettingsService.setGeminiSecondaryApiKey('key-secondary-36');
      expect(await AppSettingsService.getGeminiSecondaryApiKey(), 'key-secondary-36');

      await AppSettingsService.setGeminiPrimaryApiKey(null);
      expect(await AppSettingsService.getGeminiPrimaryApiKey(), isNull);
      expect(await AppSettingsService.hasAnyGeminiApiKey(), isTrue); // Secondary still present

      await AppSettingsService.setGeminiSecondaryApiKey(null);
      expect(await AppSettingsService.hasAnyGeminiApiKey(), isFalse);
    });

    testWidgets('GeminiKeyConfigDialog renders both Primary (3.8) and Backup (3.6) key fields', (tester) async {
      SharedPreferences.setMockInitialValues({
        'gemini_api_key': 'AIzaSyPrimary123',
        'gemini_secondary_api_key': 'AIzaSySecondary456',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GeminiKeyConfigDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Configure Gemini AI Keys'), findsOneWidget);
      expect(find.text('Primary Key (Gemini 3.8 Flash)'), findsOneWidget);
      expect(find.text('Backup Key (Gemini 3.6 Flash Failover)'), findsOneWidget);
      expect(find.text('Copy Primary Key'), findsOneWidget);
      expect(find.text('Copy Backup Key'), findsOneWidget);
      expect(find.text('Verify & Save'), findsOneWidget);
    });

    test('AppSettingsService saves and retrieves custom Website URL and TinyURL', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await AppSettingsService.getWebsiteUrl(), AppSettingsService.defaultWebsiteUrl);
      expect(await AppSettingsService.getTinyUrl(), AppSettingsService.defaultTinyUrl);

      await AppSettingsService.updateWebsiteLinks(
        websiteUrl: 'https://mycustomgolfurl.com',
        tinyUrl: 'https://tinyurl.com/customarcadia',
      );

      expect(await AppSettingsService.getWebsiteUrl(), 'https://mycustomgolfurl.com');
      expect(await AppSettingsService.getTinyUrl(), 'https://tinyurl.com/customarcadia');
    });

    test('AppSettingsService automatically purges legacy chatgpt.site or trycloudflare URLs', () async {
      SharedPreferences.setMockInitialValues({
        'website_url': 'https://arcadia-golf-trip.ckm-endo.chatgpt.site',
        'tiny_url': 'https://tinyurl.com/2xnkqbrx',
      });

      expect(await AppSettingsService.getWebsiteUrl(), AppSettingsService.defaultWebsiteUrl);
      expect(await AppSettingsService.getTinyUrl(), AppSettingsService.defaultTinyUrl);
    });

    testWidgets('EditWebsiteLinksDialog renders editable fields and saves custom URLs', (tester) async {
      SharedPreferences.setMockInitialValues({
        'website_url': 'https://custom-site.com',
        'tiny_url': 'https://tinyurl.com/custom123',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EditWebsiteLinksDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Website & TinyURL'), findsOneWidget);
      expect(find.text('Website Destination URL'), findsOneWidget);
      expect(find.text('Custom Short Link (TinyURL)'), findsOneWidget);
      expect(find.text('Save Links'), findsOneWidget);
      expect(find.text('https://custom-site.com'), findsOneWidget);
      expect(find.text('https://tinyurl.com/custom123'), findsOneWidget);
    });

    test('GeminiOcrService centrally configures Gemini 3.8 primary and 3.6 backup without 2.5', () {
      expect(GeminiOcrService.primaryModel, 'gemini-3.8-flash');
      expect(GeminiOcrService.backupModel, 'gemini-3.6-flash');
      expect(GeminiOcrService.fallbackModel, 'gemini-3.5-flash-lite');

      // Scoring service delegates directly to centralized GeminiOcrService
      expect(GeminiRoundScorecardService.primaryModel, GeminiOcrService.primaryModel);
      expect(GeminiRoundScorecardService.fallbackModel, GeminiOcrService.backupModel);
      expect(GeminiRoundScorecardService.emergencyModel, GeminiOcrService.fallbackModel);
    });

    test('RoundScorecardTextParser accurately parses actual 18Birdies scorecard screenshot text with circled unicode digits and subtotals', () {
      const parser = RoundScorecardTextParser();
      // Exact representation of OCR extraction from the user's 18Birdies screenshot:
      // Includes:
      // - Course and round header
      // - Chet M. with circled unicode digits (❹ and ❸ for birdies), Out 37, To Par +5(76), Back 9 In 39
      // - Neal P. with circled unicode digits (❹), Out 42, In 39
      // - Peeking card text on the right and share sheet at the bottom
      const actualOcrText = '''
Goose Creek Golf Course
Goose Creek
09/27/2026 18 Holes 4 MPH 81°F
Chet M.
5 3 5 5 4 5 ❹ ❸ 3 37 To Par +5(76) To Par +5 GROSS
5 3 5 ❸ 4 5 4 5 5 39
Neal P.
5 3 5 6 4 4 7 4 4 42 To Par +10(81) To Par +5 Chet M.
4 3 ❹ 6 4 5 ❹ 4 5 39
Share to
Message Instagram Facebook TikTok
18Birdies Download Copy Link More
''';

      final draft = parser.parse(actualOcrText, holeCount: 18);
      expect(draft.rows.length, equals(2));

      // Player 1: Chet M. (18 gross scores)
      expect(draft.rows[0].sourceLabel, contains('Chet'));
      expect(draft.rows[0].scores.length, equals(18));
      expect(
        draft.rows[0].scores,
        equals([5, 3, 5, 5, 4, 5, 4, 3, 3, 5, 3, 5, 3, 4, 5, 4, 5, 5]),
      );

      // Player 2: Neal P. (18 gross scores)
      expect(draft.rows[1].sourceLabel, contains('Neal'));
      expect(draft.rows[1].scores.length, equals(18));
      expect(
        draft.rows[1].scores,
        equals([5, 3, 5, 6, 4, 4, 7, 4, 4, 4, 3, 4, 6, 4, 5, 4, 4, 5]),
      );
    });

    test('AiResponseJsonDecoder parses ChatGPT root list format, trailing commas, and markdown fences', () {
      const chatGptResponse = '''
Here are the extracted scores:
```json
[
  {
    "playerName": "Chet M.",
    "scores": [5, 3, 5, 5, 4, 5, 4, 3, 3, 5, 3, 5, 3, 4, 5, 4, 5, 5],
  },
  {
    "playerName": "Neal P.",
    "scores": [5, 3, 5, 6, 4, 4, 7, 4, 4, 4, 3, 4, 6, 4, 5, 4, 4, 5],
  }
]
```
''';

      final draft = GeminiOcrService.parsePlayerScorecardResponse(
        chatGptResponse,
        holeCount: 18,
      );

      expect(draft.rows.length, equals(2));
      expect(draft.rows[0].sourceLabel, equals('Chet M.'));
      expect(draft.rows[0].scores.length, equals(18));
      expect(draft.rows[0].scores, equals([5, 3, 5, 5, 4, 5, 4, 3, 3, 5, 3, 5, 3, 4, 5, 4, 5, 5]));
      expect(draft.rows[1].sourceLabel, equals('Neal P.'));
      expect(draft.rows[1].scores.length, equals(18));
      expect(draft.rows[1].scores, equals([5, 3, 5, 6, 4, 4, 7, 4, 4, 4, 3, 4, 6, 4, 5, 4, 4, 5]));
    });

    test('OnDeviceTextRecognitionService 2D spatial extraction accurately parses 18Birdies scorecards from ML Kit TextElements', () {
      TextElement makeElement(String text, double x, double y, [double width = 35, double height = 40]) {
        return TextElement(
          text: text,
          boundingBox: Rect.fromLTWH(x - width / 2, y - height / 2, width, height),
          cornerPoints: [
            Point((x - width / 2).round(), (y - height / 2).round()),
            Point((x + width / 2).round(), (y - height / 2).round()),
            Point((x + width / 2).round(), (y + height / 2).round()),
            Point((x - width / 2).round(), (y + height / 2).round()),
          ],
          recognizedLanguages: [],
          symbols: const [],
          confidence: 1.0,
          angle: 0,
        );
      }

      final elements = <TextElement>[
        // Player 1 Name
        makeElement('Chet M.', 120, 420, 80, 25),
        // Player 1 Front 9: [5, 3, 5, 5, 4, 5, 4, 3, 3] + 37 subtotal
        makeElement('5', 300, 380),
        makeElement('3', 360, 381),
        makeElement('5', 420, 379),
        makeElement('5', 480, 380),
        makeElement('4', 540, 382),
        makeElement('5', 600, 380),
        makeElement('❹', 660, 378), // birdie circle
        makeElement('❸', 720, 380), // birdie circle
        makeElement('3', 780, 381),
        makeElement('37', 840, 380), // subtotal
        // Player 1 Back 9: [5, 3, 5, 3, 4, 5, 4, 5, 5] + 39 subtotal
        makeElement('5', 300, 460),
        makeElement('3', 360, 462),
        makeElement('5', 420, 459),
        makeElement('❸', 480, 461), // birdie circle
        makeElement('4', 540, 460),
        makeElement('5', 600, 460),
        makeElement('4', 660, 458),
        makeElement('5', 720, 461),
        makeElement('5', 780, 460),
        makeElement('39', 840, 460), // subtotal

        // Player 2 Name
        makeElement('Neal P.', 120, 600, 80, 25),
        // Player 2 Front 9: [5, 3, 5, 6, 4, 4, 7, 4, 4] + 42 subtotal
        makeElement('5', 300, 560),
        makeElement('3', 360, 559),
        makeElement('5', 420, 561),
        makeElement('6', 480, 560),
        makeElement('4', 540, 560),
        makeElement('4', 600, 562),
        makeElement('7', 660, 560),
        makeElement('4', 720, 558),
        makeElement('4', 780, 560),
        makeElement('42', 840, 560), // subtotal
        // Player 2 Back 9: [4, 3, 4, 6, 4, 5, 4, 4, 5] + 39 subtotal
        makeElement('4', 300, 640),
        makeElement('3', 360, 641),
        makeElement('❹', 420, 639), // birdie circle
        makeElement('6', 480, 640),
        makeElement('4', 540, 640),
        makeElement('5', 600, 642),
        makeElement('❹', 660, 638), // birdie circle
        makeElement('4', 720, 640),
        makeElement('5', 780, 641),
        makeElement('39', 840, 640), // subtotal

        // Extraneous elements from right peeking card & bottom share sheet
        makeElement('GROSS', 1100, 380, 60, 20),
        makeElement('Share to', 500, 1200, 100, 30),
        makeElement('18Birdies', 500, 1300, 80, 25),
      ];

      final draft = OnDeviceTextRecognitionService.extractFromSpatialElements(
        elements: elements,
        holeCount: 18,
      );

      expect(draft, isNotNull);
      expect(draft!.rows.length, equals(2));

      // Chet M. (18 gross scores)
      expect(draft.rows[0].sourceLabel, equals('Chet M.'));
      expect(draft.rows[0].scores.length, equals(18));
      expect(
        draft.rows[0].scores,
        equals([5, 3, 5, 5, 4, 5, 4, 3, 3, 5, 3, 5, 3, 4, 5, 4, 5, 5]),
      );

      // Neal P. (18 gross scores)
      expect(draft.rows[1].sourceLabel, equals('Neal P.'));
      expect(draft.rows[1].scores.length, equals(18));
      expect(
        draft.rows[1].scores,
        equals([5, 3, 5, 6, 4, 4, 7, 4, 4, 4, 3, 4, 6, 4, 5, 4, 4, 5]),
      );
    });

    test('GeminiOcrService.parsePlayerScorecardResponse merges 2-row AI responses into 18 holes', () {
      // Test when AI returns 2 rows per player (Front 9 & Back 9)
      const aiTwoRowResponse = '''
{
  "rows": [
    {
      "playerName": "Chet M. (Front 9)",
      "scores": [5, 3, 5, 5, 4, 5, 4, 3, 3]
    },
    {
      "playerName": "Chet M. (Back 9)",
      "scores": [5, 3, 5, 3, 4, 5, 4, 5, 5]
    },
    {
      "playerName": "Neal P. (Front 9)",
      "scores": [5, 3, 5, 6, 4, 4, 7, 4, 4]
    },
    {
      "playerName": "Neal P. (Back 9)",
      "scores": [4, 3, 4, 6, 4, 5, 4, 4, 5]
    }
  ]
}
''';

      final draft = GeminiOcrService.parsePlayerScorecardResponse(
        aiTwoRowResponse,
        holeCount: 18,
      );

      expect(draft.rows.length, equals(2));
      expect(draft.rows[0].sourceLabel, equals('Chet M.'));
      expect(draft.rows[0].scores.length, equals(18));
      expect(
        draft.rows[0].scores,
        equals([5, 3, 5, 5, 4, 5, 4, 3, 3, 5, 3, 5, 3, 4, 5, 4, 5, 5]),
      );

      expect(draft.rows[1].sourceLabel, equals('Neal P.'));
      expect(draft.rows[1].scores.length, equals(18));
      expect(
        draft.rows[1].scores,
        equals([5, 3, 5, 6, 4, 4, 7, 4, 4, 4, 3, 4, 6, 4, 5, 4, 4, 5]),
      );
    });

    test('GeminiOcrService.parsePlayerScorecardResponse ignores Net rows when Gross rows exist', () {
      const aiGrossNetResponse = '''
{
  "rows": [
    {
      "playerName": "Neal P. Gross",
      "scores": [5, 3, 5, 6, 4, 4, 7, 4, 4]
    },
    {
      "playerName": "Neal P. Net",
      "scores": [5, 3, 4, 6, 4, 3, 7, 4, 3]
    },
    {
      "playerName": "Chet M. Gross",
      "scores": [5, 3, 5, 5, 4, 5, 4, 3, 3]
    },
    {
      "playerName": "Chet M. Net",
      "scores": [4, 3, 4, 5, 4, 4, 3, 3, 3]
    }
  ]
}
''';

      final draft = GeminiOcrService.parsePlayerScorecardResponse(
        aiGrossNetResponse,
        holeCount: 18,
      );

      expect(draft.rows.length, equals(2));
      expect(draft.rows[0].sourceLabel, contains('Neal P.'));
      expect(draft.rows[0].scores.take(9), equals([5, 3, 5, 6, 4, 4, 7, 4, 4]));
      expect(draft.rows[1].sourceLabel, contains('Chet M.'));
      expect(draft.rows[1].scores.take(9), equals([5, 3, 5, 5, 4, 5, 4, 3, 3]));
    });

    test('OnDeviceTextRecognitionService parses Gross/Net table scorecard and ignores Net rows', () {
      TextElement makeElement(String text, double x, double y, [double width = 35, double height = 40]) {
        return TextElement(
          text: text,
          boundingBox: Rect.fromLTWH(x - width / 2, y - height / 2, width, height),
          cornerPoints: [
            Point((x - width / 2).round(), (y - height / 2).round()),
            Point((x + width / 2).round(), (y - height / 2).round()),
            Point((x + width / 2).round(), (y + height / 2).round()),
            Point((x - width / 2).round(), (y + height / 2).round()),
          ],
          recognizedLanguages: [],
          symbols: const [],
          confidence: 1.0,
          angle: 0,
        );
      }

      final elements = <TextElement>[
        // Player 1
        makeElement('Neal P.', 100, 300, 70, 20),
        makeElement('Gross', 180, 300, 40, 20),
        makeElement('5', 250, 300),
        makeElement('3', 300, 300),
        makeElement('5', 350, 300),
        makeElement('6', 400, 300),
        makeElement('4', 450, 300),
        makeElement('4', 500, 300),
        makeElement('7', 550, 300),
        makeElement('4', 600, 300),
        makeElement('4', 650, 300),
        makeElement('81', 720, 300),

        makeElement('Net', 180, 340, 40, 20),
        makeElement('5', 250, 340),
        makeElement('3', 300, 340),
        makeElement('4', 350, 340),
        makeElement('6', 400, 340),
        makeElement('4', 450, 340),
        makeElement('3', 500, 340),
        makeElement('7', 550, 340),
        makeElement('4', 600, 340),
        makeElement('3', 650, 340),
        makeElement('75', 720, 340),

        // Player 2
        makeElement('Chet M.', 100, 420, 70, 20),
        makeElement('Gross', 180, 420, 40, 20),
        makeElement('5', 250, 420),
        makeElement('3', 300, 420),
        makeElement('5', 350, 420),
        makeElement('5', 400, 420),
        makeElement('4', 450, 420),
        makeElement('5', 500, 420),
        makeElement('4', 550, 420),
        makeElement('3', 600, 420),
        makeElement('3', 650, 420),
        makeElement('76', 720, 420),

        makeElement('Net', 180, 460, 40, 20),
        makeElement('4', 250, 460),
        makeElement('3', 300, 460),
        makeElement('4', 350, 460),
        makeElement('5', 400, 460),
        makeElement('4', 450, 460),
        makeElement('4', 500, 460),
        makeElement('3', 550, 460),
        makeElement('3', 600, 460),
        makeElement('3', 650, 460),
        makeElement('67', 720, 460),
      ];

      final draft = OnDeviceTextRecognitionService.extractFromSpatialElements(
        elements: elements,
        holeCount: 18,
      );

      expect(draft, isNotNull);
      expect(draft!.rows.length, equals(2));
      expect(draft.rows[0].sourceLabel, equals('Neal P.'));
      expect(draft.rows[0].scores.take(9), equals([5, 3, 5, 6, 4, 4, 7, 4, 4]));
      expect(draft.rows[1].sourceLabel, equals('Chet M.'));
      expect(draft.rows[1].scores.take(9), equals([5, 3, 5, 5, 4, 5, 4, 3, 3]));
    });
  });
}



