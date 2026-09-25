import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/widgets.dart' as pw;
import 'package:veloxmd/services/pdf_export_service.dart';

void main() {
  group('PdfExportService', () {
    final testFontConfig = PdfFontConfig(
      regular: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      italic: pw.Font.helveticaOblique(),
      boldItalic: pw.Font.helveticaBoldOblique(),
      mono: pw.Font.courier(),
    );

    test('generates valid PDF bytes from basic markdown', () async {
      const markdown = '''
# Heading 1
## Heading 2
### Heading 3

This is a paragraph with **bold**, *italic*, and `inline code`.
Here is a [link](https://github.com/lbonomo/VeloxMD).

---

- Item 1
- Item 2
  - Subitem 2.1
- [ ] Task unchecked
- [x] Task checked

1. First
2. Second

> This is a blockquote with multiple words.

```dart
void main() {
  print('Hello, PDF!');
}
```

```mermaid
graph TD
  A --> B
```

| Header 1 | Header 2 |
| :--- | :---: |
| Value 1 | Value 2 |
''';

      final bytes = await PdfExportService.generatePdf(
        markdown: markdown,
        title: 'Test Document',
        fontConfig: testFontConfig,
      );

      expect(bytes, isNotEmpty);
      // PDF starts with %PDF-
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('exports to file successfully', () async {
      final tempDir = Directory.systemTemp.createTempSync('veloxmd_pdf_test');
      final outputFile = '${tempDir.path}/output.pdf';

      try {
        const markdown = '# Exported Title\n\nContent paragraph.';
        final file = await PdfExportService.exportToFile(
          markdown: markdown,
          outputPath: outputFile,
          title: 'Exported Title',
          fontConfig: testFontConfig,
        );

        expect(await file.exists(), isTrue);
        final length = await file.length();
        expect(length, greaterThan(100));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('handles empty markdown without crashing', () async {
      final bytes = await PdfExportService.generatePdf(
        markdown: '',
        title: 'Empty',
        fontConfig: testFontConfig,
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('handles tables with alignments, blockquotes, and deep lists', () async {
      const markdown = '''
# Complex Document

> Line 1 of blockquote
> Line 2 of blockquote
>
> > Nested blockquote

* Level 1
  * Level 2
    * Level 3
      * Level 4

1. Numbered 1
   1. Nested numbered 1.1
   2. Nested numbered 1.2

| Left | Center | Right |
| :--- | :----: | ----: |
| L1   |   C1   |    R1 |
| L2   |   C2   |    R2 |

![Local Missing Image](missing_image.png)

```
plain code block without language
```

```python
def hello():
    return 42
```
''';

      final bytes = await PdfExportService.generatePdf(
        markdown: markdown,
        title: 'Complex Document',
        fontConfig: testFontConfig,
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('handles a huge code block without throwing height overflow', () async {
      final buffer = StringBuffer();
      buffer.writeln('# Huge Code Block');
      buffer.writeln('```dart');
      for (int i = 1; i <= 150; i++) {
        buffer.writeln('  // Line $i of a very long code block that exceeds single page height');
      }
      buffer.writeln('```');

      final bytes = await PdfExportService.generatePdf(
        markdown: buffer.toString(),
        title: 'Huge Code Block',
        fontConfig: testFontConfig,
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('handles very large documents spanning multiple pages without height overflow', () async {
      final buffer = StringBuffer();
      buffer.writeln('# Very Large Document');
      buffer.writeln();
      buffer.writeln('## Long Code Block');
      buffer.writeln('```dart');
      for (int i = 1; i <= 200; i++) {
        buffer.writeln('  // Line $i: Some code that extends the document across multiple pages');
      }
      buffer.writeln('```');
      buffer.writeln();
      buffer.writeln('## Long List');
      for (int i = 1; i <= 150; i++) {
        buffer.writeln('- List item number $i with some explanatory text to test pagination');
      }
      buffer.writeln();
      buffer.writeln('## Long Blockquote');
      for (int i = 1; i <= 50; i++) {
        buffer.writeln('> Paragraph $i in a long blockquote that spans across multiple pages.');
        buffer.writeln('>');
      }
      buffer.writeln();
      buffer.writeln('## Long Table');
      buffer.writeln('| Index | Description | Status |');
      buffer.writeln('| :--- | :--- | :--- |');
      for (int i = 1; i <= 80; i++) {
        buffer.writeln('| $i | Long table row description $i | Completed |');
      }

      final bytes = await PdfExportService.generatePdf(
        markdown: buffer.toString(),
        title: 'Very Large Document',
        fontConfig: testFontConfig,
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('exports real-world files examples/kiro.md, assets/demo.md, assets/mermaid_demo.md', () async {
      for (final filePath in [
        'examples/kiro.md',
        'assets/demo.md',
        'assets/mermaid_demo.md',
      ]) {
        final file = File(filePath);
        if (await file.exists()) {
          final content = await file.readAsString();
          final bytes = await PdfExportService.generatePdf(
            markdown: content,
            title: p.basename(filePath),
            fontConfig: testFontConfig,
            basePath: p.dirname(filePath),
          );
          expect(bytes, isNotEmpty, reason: 'Failed for $filePath');
          expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'), reason: 'Failed for $filePath');
        }
      }
    });
  });
}
