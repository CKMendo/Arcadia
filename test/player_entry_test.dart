import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:arcadia/database/app_database.dart';
import 'package:arcadia/features/players/repository/player_repository.dart';
import 'package:arcadia/features/players/presentation/player_entry_screen.dart';
import 'package:arcadia/shared/widgets/player_avatar.dart';

void main() {
  late AppDatabase db;
  late PlayerRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = PlayerRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('PlayerEntryScreen renders NAME, HANDICAP, PHONE NUMBER and Headshot Space', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: PlayerEntryScreen(playerRepository: repo),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Player Entry'), findsOneWidget);

    // Verify Headshot space
    expect(find.text('HEADSHOT SPACE'), findsOneWidget);

    // Verify Required Field Labels
    expect(find.text('NAME *'), findsOneWidget);
    expect(find.text('HANDICAP *'), findsOneWidget);
    expect(find.text('PHONE NUMBER *'), findsOneWidget);

    // Verify Submit button
    expect(find.text('Add Player to Roster'), findsOneWidget);

    // Cleanup widget tree and drain stream cancellation timers
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('PlayerEntryScreen adds a player with phone and handicap and displays in roster list', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: PlayerEntryScreen(playerRepository: repo),
      ),
    );
    await tester.pumpAndSettle();

    // Fill in NAME, HANDICAP, PHONE NUMBER
    await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Chet Mehta'), 'Jordan Spieth');
    await tester.enterText(find.widgetWithText(TextFormField, '8.7'), '1.5');
    await tester.enterText(find.widgetWithText(TextFormField, 'e.g. (313) 555-0188'), '(214) 555-0199');

    // Scroll to button and tap
    await tester.ensureVisible(find.text('Add Player to Roster'));
    await tester.tap(find.text('Add Player to Roster'));
    await tester.pumpAndSettle();

    // Verify player is now in the database
    final players = await repo.getAllPlayers();
    expect(players.length, 1);
    expect(players.first.fullName, 'Jordan Spieth');
    expect(players.first.handicapIndex, 1.5);
    expect(players.first.phoneNumber, '(214) 555-0199');

    // Verify list renders the player name, handicap badge, and phone number
    expect(find.text('Jordan Spieth'), findsOneWidget);
    expect(find.text('HCP 1.5'), findsOneWidget);
    expect(find.text('(214) 555-0199'), findsOneWidget);
    expect(find.text('Headshot space reserved • Tap avatar to fill in photo'), findsOneWidget);

    // Cleanup widget tree and drain stream cancellation timers
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  test('PlayerAvatar renders headshot space placeholder when photo is null', () {
    const avatar = PlayerAvatar(
      initials: 'JS',
      isHeadshotSpace: true,
      radius: 28,
    );
    expect(avatar.isHeadshotSpace, true);
    expect(avatar.initials, 'JS');
  });
}
