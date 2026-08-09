import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloxmd/widgets/markdown_viewer.dart';

void main() {
  testWidgets('renders visible search highlight in heading and body', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.binding.setSurfaceSize(const Size(980, 760));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownViewer(
            content: '''
# Usage Tracking
## Problema

Las API keys se usan para registrar el Problema de consumo por tenant.

- Problema en lista
- Otro item sin match

> Problema en cita
''',
            scrollController: controller,
            basePath: '.',
            searchQuery: 'Problema',
            activeMatchIndex: 1,
            useGoogleFonts: false,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MarkdownViewer),
      matchesGoldenFile('goldens/markdown_viewer_search_highlight.png'),
    );
  });
}
