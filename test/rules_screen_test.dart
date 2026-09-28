import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:arcadia/database/app_database.dart';
import 'package:arcadia/features/players/repository/player_repository.dart';
import 'package:arcadia/features/rules/presentation/rules_screen.dart';

void main() {
  testWidgets('RulesScreen renders all 6 rules, birdie pot details, and share button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RulesScreen(),
      ),
    );

    // Verify header title and share button
    expect(find.text('Tournament Rules'), findsOneWidget);
    expect(find.text('SHARE RULES TO PLAYERS / GROUP'), findsOneWidget);
    expect(find.text('ARCADIA CUP'), findsOneWidget);
    expect(find.text('Official Tournament & Betting Format'), findsOneWidget);

    // Rule 1
    expect(find.text('AI 4-somes & Partner Rotation'), findsOneWidget);

    // Rule 2
    await tester.scrollUntilVisible(find.text('2-Man Best Ball Stableford'), 300);
    expect(find.text('2-Man Best Ball Stableford'), findsOneWidget);

    // Rule 3
    await tester.scrollUntilVisible(find.text('End of Round Team Score Recording'), 300);
    expect(find.text('End of Round Team Score Recording'), findsOneWidget);

    // Rule 4
    await tester.scrollUntilVisible(find.text('Final Round Partner Selection Draft'), 300);
    expect(find.text('Final Round Partner Selection Draft'), findsOneWidget);

    // Rule 5
    await tester.scrollUntilVisible(find.text('Final Round Modified Stableford'), 300);
    expect(find.text('Final Round Modified Stableford'), findsOneWidget);

    // Rule 6
    await tester.scrollUntilVisible(find.text('Arcadia Cup Champion Determination'), 300);
    expect(find.text('Arcadia Cup Champion Determination'), findsOneWidget);

    // Birdie Pot
    await tester.scrollUntilVisible(find.text('THE BIRDIE POT GAME'), 300);
    expect(find.text('THE BIRDIE POT GAME'), findsOneWidget);
    expect(find.text('3. Last Birdie Wins the Round Pot!'), findsOneWidget);
    expect(find.text('4. Last Birdie of Trip Wins Cumulative Pot!'), findsOneWidget);
  });

  testWidgets('Tapping SHARE RULES TO PLAYERS / GROUP opens CVRV-style selection dialog', (WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = PlayerRepository(db);
    await repo.seedSample8Players();

    await tester.pumpWidget(
      MaterialApp(
        home: RulesScreen(playerRepository: repo),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the prominent Share button at the top
    await tester.tap(find.text('SHARE RULES TO PLAYERS / GROUP'));
    await tester.pumpAndSettle();

    // Verify dialog title and instructions
    expect(find.text('SHARE TOURNAMENT RULES'), findsOneWidget);
    expect(find.textContaining('Choose active players from the roster or select the entire group'), findsOneWidget);

    // Verify all 8 players are rendered with checkboxes
    expect(find.text('8 of 8 selected'), findsOneWidget);
    expect(find.text('Neal Patel'), findsOneWidget);
    expect(find.text('Chet Mehta'), findsOneWidget);
    expect(find.text('Raudel Sandoval'), findsOneWidget);

    // Verify action buttons
    expect(find.text('Share via Apps'), findsOneWidget);
    expect(find.text('Compose Text (8)'), findsOneWidget);
    expect(find.text('Clear All'), findsOneWidget);

    // Test Clear All toggle
    await tester.tap(find.text('Clear All'));
    await tester.pumpAndSettle();
    expect(find.text('0 of 8 selected'), findsOneWidget);
    expect(find.text('Select All'), findsOneWidget);

    await db.close();
  });
}
