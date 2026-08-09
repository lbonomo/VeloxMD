import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloxmd/widgets/markdown_viewer.dart';

void main() {
  testWidgets('highlights search matches without changing their case', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownViewer(
            content: 'Hello world and WORLD.',
            scrollController: controller,
            basePath: '.',
            searchQuery: 'world',
          ),
        ),
      ),
    );

    final highlightedText = tester.widgetList<Text>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data == 'world' || widget.data == 'WORLD') &&
            widget.style?.backgroundColor != null,
      ),
    );

    expect(highlightedText.map((text) => text.data), ['world', 'WORLD']);
  });

  testWidgets('keeps markdown formatting while highlighting matches', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownViewer(
            content: '**Search this text**',
            scrollController: controller,
            basePath: '.',
            searchQuery: 'this',
          ),
        ),
      ),
    );

    final match = tester.widget<Text>(find.text('this'));
    expect(match.style?.backgroundColor, isNotNull);
    expect(match.style?.fontWeight, FontWeight.bold);
  });

  testWidgets('uses high-contrast highlight colors in light theme', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownViewer(
            content: 'one two two',
            scrollController: controller,
            basePath: '.',
            searchQuery: 'two',
            activeMatchIndex: 1,
          ),
        ),
      ),
    );

    final matches = tester
        .widgetList<Text>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                widget.data == 'two' &&
                widget.style?.backgroundColor != null,
          ),
        )
        .toList();

    expect(matches, hasLength(2));
    expect(matches[0].style?.backgroundColor, const Color(0xFFFFC107));
    expect(matches[1].style?.backgroundColor, const Color(0xFFFF9800));
  });

  testWidgets('preserves text color in dark theme while highlighting', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: MarkdownViewer(
            content: 'Dark world test',
            scrollController: controller,
            basePath: '.',
            searchQuery: 'world',
          ),
        ),
      ),
    );

    final match = tester.widget<Text>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == 'world' &&
            widget.style?.backgroundColor != null,
      ),
    );

    expect(match.style?.backgroundColor, isNotNull);
    expect(match.style?.color, isNot(Colors.black));
  });

  testWidgets('preserves heading style when highlight matches a heading', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownViewer(
            content: '## Problema',
            scrollController: controller,
            basePath: '.',
            searchQuery: 'Problema',
          ),
        ),
      ),
    );

    final match = tester.widget<Text>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == 'Problema' &&
            widget.style?.backgroundColor != null,
      ),
    );

    expect(match.style?.backgroundColor, isNotNull);
    expect(match.style?.fontWeight, FontWeight.bold);
    expect(match.style?.fontSize, greaterThan(20));
  });

  testWidgets('active match index changes the highlighted occurrence', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    Future<List<Text>> pumpWithIndex(int activeMatchIndex) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownViewer(
              content: 'banana apple banana grape banana',
              scrollController: controller,
              basePath: '.',
              searchQuery: 'banana',
              activeMatchIndex: activeMatchIndex,
            ),
          ),
        ),
      );
      await tester.pump();

      return tester
          .widgetList<Text>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  widget.data == 'banana' &&
                  widget.style?.backgroundColor != null,
            ),
          )
          .toList();
    }

    final firstState = await pumpWithIndex(0);
    expect(
      firstState
          .where(
            (text) => text.style?.backgroundColor == const Color(0xFFFF9800),
          )
          .length,
      1,
    );
    expect(
      firstState
          .where(
            (text) => text.style?.backgroundColor == const Color(0xFFFFC107),
          )
          .length,
      2,
    );

    final secondState = await pumpWithIndex(1);
    expect(
      secondState
          .where(
            (text) => text.style?.backgroundColor == const Color(0xFFFF9800),
          )
          .length,
      1,
    );
    expect(
      secondState
          .where(
            (text) => text.style?.backgroundColor == const Color(0xFFFFC107),
          )
          .length,
      2,
    );
  });

  testWidgets('updates highlight when query changes without theme toggle', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    Future<void> pumpWithQuery(String query) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownViewer(
              content: 'Texto con Problema visible',
              scrollController: controller,
              basePath: '.',
              searchQuery: query,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    await pumpWithQuery('');
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == 'Problema' &&
            widget.style?.backgroundColor != null,
      ),
      findsNothing,
    );

    await pumpWithQuery('Problema');
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == 'Problema' &&
            widget.style?.backgroundColor != null,
      ),
      findsWidgets,
    );
  });
}
