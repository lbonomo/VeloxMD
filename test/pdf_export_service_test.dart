import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
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
  });
}
