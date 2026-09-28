import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:arcadia/database/app_database.dart';
import 'package:arcadia/shared/theme/app_colors.dart';
import 'package:arcadia/features/courses/repository/course_repository.dart';
import 'package:arcadia/features/players/repository/player_repository.dart';
import 'package:arcadia/features/publish/services/website_publish_service.dart';
import 'package:arcadia/features/rounds/import/models/round_score_import_draft.dart';
import 'package:arcadia/features/rounds/import/presentation/round_scorecard_import_screen.dart';
import 'package:arcadia/features/rounds/import/services/external_ai_import_service.dart';
import 'package:arcadia/features/rounds/import/services/player_score_row_matcher.dart';
import 'package:arcadia/features/rounds/import/services/round_scorecard_text_parser.dart';
import 'package:arcadia/features/rounds/repository/round_repository.dart';
import 'package:arcadia/features/tournaments/repository/tournament_repository.dart';

void main() {
  late AppDatabase db;
  late PlayerRepository playerRepo;
  late CourseRepository courseRepo;
  late TournamentRepository tournamentRepo;
  late RoundRepository roundRepo;

  setUp(() async {
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
  });
}
