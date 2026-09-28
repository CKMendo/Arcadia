import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arcadia/features/rules/presentation/rules_screen.dart';

void main() {
  testWidgets('RulesScreen renders all 6 rules and birdie pot details', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RulesScreen(),
      ),
    );

    // Verify header title
    expect(find.text('Tournament Rules'), findsOneWidget);
    expect(find.text('ARCADIA CUP'), findsOneWidget);
    expect(find.text('Official Tournament & Betting Format'), findsOneWidget);

    // Rule 1
    expect(find.text('AI 4-somes & Partner Rotation'), findsOneWidget);

    // Rule 2
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
    expect(find.text('2-Man Best Ball Stableford'), findsOneWidget);

    // Rule 3
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();
    expect(find.text('End of Round Team Score Recording'), findsOneWidget);

    // Rule 4
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();
    expect(find.text('Final Round Partner Selection Draft'), findsOneWidget);

    // Rule 5
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();
    expect(find.text('Final Round Modified Stableford'), findsOneWidget);

    // Rule 6
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();
    expect(find.text('Arcadia Cup Champion Determination'), findsOneWidget);

    // Birdie Pot
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(find.text('THE BIRDIE POT GAME'), findsOneWidget);
    expect(find.text('3. Last Birdie Wins the Round Pot!'), findsOneWidget);
    expect(find.text('4. Last Birdie of Trip Wins Cumulative Pot!'), findsOneWidget);
  });
}
