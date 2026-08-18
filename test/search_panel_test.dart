import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloxmd/widgets/search_panel.dart';

void main() {
  testWidgets('renders search state and navigation controls', (tester) async {
    final controller = TextEditingController(text: 'alpha');
    final focusNode = FocusNode();
    var nextCount = 0;
    var previousCount = 0;
    var clearCount = 0;

    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchPanel(
            controller: controller,
            focusNode: focusNode,
            matchCount: 3,
            activeMatchIndex: 1,
            onChanged: (_) {},
            onNext: () => nextCount++,
            onPrevious: () => previousCount++,
            onClear: () => clearCount++,
          ),
        ),
      ),
    );

    expect(find.text('2/3 matches'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Previous'), findsOneWidget);
    expect(find.byTooltip('Clear search'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.tap(find.text('Previous'));
    await tester.tap(find.byTooltip('Clear search'));

    expect(nextCount, 1);
    expect(previousCount, 1);
    expect(clearCount, 1);
  });

  testWidgets('shows no-results state and disables navigation', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    var nextCount = 0;

    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchPanel(
            controller: controller,
            focusNode: focusNode,
            matchCount: 0,
            activeMatchIndex: 0,
            onChanged: (_) {},
            onNext: () => nextCount++,
            onPrevious: () {},
            onClear: () {},
          ),
        ),
      ),
    );

    expect(find.text('No results'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Next'))
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Next'));
    expect(nextCount, 0);
  });
}
