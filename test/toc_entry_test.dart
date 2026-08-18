import 'package:flutter_test/flutter_test.dart';
import 'package:veloxmd/models/toc_entry.dart';

void main() {
  group('TocEntry.fromMarkdown', () {
    test('returns empty list for content with no headings', () {
      final entries = TocEntry.fromMarkdown('Hello world\n\nParagraph text.');
      expect(entries, isEmpty);
    });

    test('parses ATX headings of all levels', () {
      const markdown = '''
# Title
## Section 1
### Subsection
## Section 2
#### Deep
''';
      final entries = TocEntry.fromMarkdown(markdown);
      expect(entries.length, 5);
      expect(entries[0].level, 1);
      expect(entries[0].title, 'Title');
      expect(entries[1].level, 2);
      expect(entries[1].title, 'Section 1');
      expect(entries[2].level, 3);
      expect(entries[2].title, 'Subsection');
      expect(entries[4].level, 4);
    });

    test('assigns sequential index values', () {
      const markdown = '# A\n## B\n### C\n';
      final entries = TocEntry.fromMarkdown(markdown);
      expect(entries.map((e) => e.index), orderedEquals([0, 1, 2]));
    });

    test('generates lowercase hyphenated anchors', () {
      const markdown = '# Hello World\n## My Section\n';
      final entries = TocEntry.fromMarkdown(markdown);
      expect(entries[0].anchor, 'hello-world');
      expect(entries[1].anchor, 'my-section');
    });

    test('parses indented ATX headings and strips closing hashes', () {
      const markdown = '   # Indented heading ###\n# Real heading\n';
      final entries = TocEntry.fromMarkdown(markdown);
      expect(entries.length, 2);
      expect(entries.first.title, 'Indented heading');
      expect(entries.first.anchor, 'indented-heading');
      expect(entries.last.title, 'Real heading');
    });
  });
}
