import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Holds fonts used for PDF generation.
class PdfFontConfig {
  const PdfFontConfig({
    required this.regular,
    required this.bold,
    this.italic,
    this.boldItalic,
    required this.mono,
  });

  final pw.Font regular;
  final pw.Font bold;
  final pw.Font? italic;
  final pw.Font? boldItalic;
  final pw.Font mono;
}

/// Converts Markdown documents to beautifully styled PDF files.
class PdfExportService {
  PdfExportService._();

  /// Loads bundled fonts or falls back to standard PDF fonts.
  static Future<PdfFontConfig> loadFonts() async {
    try {
      final regularData =
          await rootBundle.load('assets/fonts/Inter-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
      final monoData =
          await rootBundle.load('assets/fonts/FiraCode-Regular.ttf');
      return PdfFontConfig(
        regular: pw.Font.ttf(regularData),
        bold: pw.Font.ttf(boldData),
        mono: pw.Font.ttf(monoData),
      );
    } catch (_) {
      return PdfFontConfig(
        regular: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        italic: pw.Font.helveticaOblique(),
        boldItalic: pw.Font.helveticaBoldOblique(),
        mono: pw.Font.courier(),
      );
    }
  }

  /// Generates a PDF from [markdown] content and returns raw PDF bytes.
  static Future<Uint8List> generatePdf({
    required String markdown,
    String? title,
    String? basePath,
    PdfFontConfig? fontConfig,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    final fonts = fontConfig ?? await loadFonts();
    final pdf = pw.Document(
      title: title ?? 'VeloxMD Document',
      author: 'VeloxMD',
      creator: 'VeloxMD Markdown Viewer',
    );

    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
    );
    final lines = markdown.split(RegExp(r'\r?\n'));
    final astNodes = document.parseLines(lines);

    final converter = _MarkdownToPdfConverter(
      fonts: fonts,
      basePath: basePath,
    );
    final contentWidgets = await converter.convertNodes(astNodes);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        header: (context) {
          if (title == null || title.isEmpty || context.pageNumber == 1) {
            return pw.SizedBox(height: 8);
          }
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.only(bottom: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: 8.5,
                color: PdfColors.grey600,
              ),
            ),
          );
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 16),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated with VeloxMD',
                  style: pw.TextStyle(
                    font: fonts.regular,
                    fontSize: 8,
                    color: PdfColors.grey500,
                  ),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(
                    font: fonts.regular,
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },
        build: (context) => contentWidgets.isEmpty
            ? [pw.Text(' ', style: pw.TextStyle(font: fonts.regular, fontSize: 10))]
            : contentWidgets,
      ),
    );

    return pdf.save();
  }

  /// Exports [markdown] to a PDF file at [outputPath].
  static Future<File> exportToFile({
    required String markdown,
    required String outputPath,
    String? title,
    String? basePath,
    PdfFontConfig? fontConfig,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    final bytes = await generatePdf(
      markdown: markdown,
      title: title,
      basePath: basePath,
      fontConfig: fontConfig,
      pageFormat: pageFormat,
    );
    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}

class _MarkdownToPdfConverter {
  _MarkdownToPdfConverter({
    required this.fonts,
    this.basePath,
  });

  final PdfFontConfig fonts;
  final String? basePath;

  static const _textPrimary = PdfColor.fromInt(0xFF1F2328);
  static const _textMuted = PdfColor.fromInt(0xFF656D76);
  static const _codeBg = PdfColor.fromInt(0xFFF6F8FA);
  static const _codeBorder = PdfColor.fromInt(0xFFD0D7DE);
  static const _linkBlue = PdfColor.fromInt(0xFF0969DA);
  static const _blockquoteBorder = PdfColor.fromInt(0xFF0969DA);
  static const _codeInlineColor = PdfColor.fromInt(0xFFBF3989);

  Future<List<pw.Widget>> convertNodes(List<md.Node> nodes) async {
    final widgets = <pw.Widget>[];
    for (final node in nodes) {
      final converted = await _convertBlockNode(node);
      if (converted != null) {
        widgets.add(converted);
      }
    }
    return widgets;
  }

  Future<pw.Widget?> _convertBlockNode(md.Node node) async {
    if (node is! md.Element) {
      if (node is md.Text && node.text.trim().isNotEmpty) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Text(
            node.text,
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: 10.5,
              color: _textPrimary,
              lineSpacing: 1.4,
            ),
          ),
        );
      }
      return null;
    }

    switch (node.tag) {
      case 'h1':
        return _buildHeading(node, fontSize: 22, topMargin: 16, bottomMargin: 8, hasDivider: true);
      case 'h2':
        return _buildHeading(node, fontSize: 17, topMargin: 14, bottomMargin: 6, hasDivider: true);
      case 'h3':
        return _buildHeading(node, fontSize: 14, topMargin: 12, bottomMargin: 5);
      case 'h4':
        return _buildHeading(node, fontSize: 12, topMargin: 10, bottomMargin: 4);
      case 'h5':
        return _buildHeading(node, fontSize: 10.5, topMargin: 8, bottomMargin: 4);
      case 'h6':
        return _buildHeading(node, fontSize: 9.5, topMargin: 8, bottomMargin: 4, isMuted: true);

      case 'p':
        return _buildParagraph(node);

      case 'blockquote':
        return _buildBlockquote(node);

      case 'ul':
        return _buildList(node, ordered: false);

      case 'ol':
        return _buildList(node, ordered: true);

      case 'pre':
        return _buildCodeBlock(node);

      case 'table':
        return _buildTable(node);

      case 'hr':
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 10),
          child: pw.Divider(color: _codeBorder, thickness: 0.8),
        );

      case 'img':
        return _buildImageElement(node);

      default:
        // Handle custom or unrecognised container elements by processing their children
        if (node.children != null && node.children!.isNotEmpty) {
          final childrenWidgets = await convertNodes(node.children!);
          if (childrenWidgets.isNotEmpty) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: childrenWidgets,
            );
          }
        }
        return null;
    }
  }

  pw.Widget _buildHeading(
    md.Element element, {
    required double fontSize,
    required double topMargin,
    required double bottomMargin,
    bool hasDivider = false,
    bool isMuted = false,
  }) {
    final spans = _convertInlineNodes(element.children ?? []);
    final headingWidget = pw.RichText(
      text: pw.TextSpan(
        children: spans.isEmpty
            ? [pw.TextSpan(text: element.textContent)]
            : spans,
        style: pw.TextStyle(
          font: fonts.bold,
          fontSize: fontSize,
          color: isMuted ? _textMuted : _textPrimary,
        ),
      ),
    );

    if (hasDivider) {
      return pw.Padding(
        padding: pw.EdgeInsets.only(top: topMargin, bottom: bottomMargin),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            headingWidget,
            pw.SizedBox(height: 4),
            pw.Divider(color: _codeBorder, thickness: 0.5),
          ],
        ),
      );
    }

    return pw.Padding(
      padding: pw.EdgeInsets.only(top: topMargin, bottom: bottomMargin),
      child: headingWidget,
    );
  }

  Future<pw.Widget> _buildParagraph(md.Element element) async {
    // Check if the paragraph contains only an image
    if (element.children != null &&
        element.children!.length == 1 &&
        element.children!.first is md.Element &&
        (element.children!.first as md.Element).tag == 'img') {
      final imgWidget = await _buildImageElement(element.children!.first as md.Element);
      if (imgWidget != null) return imgWidget;
    }

    final spans = _convertInlineNodes(element.children ?? []);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.RichText(
        text: pw.TextSpan(
          children: spans.isEmpty
              ? [pw.TextSpan(text: element.textContent)]
              : spans,
          style: pw.TextStyle(
            font: fonts.regular,
            fontSize: 10.5,
            color: _textPrimary,
            lineSpacing: 1.4,
          ),
        ),
      ),
    );
  }

  Future<pw.Widget> _buildBlockquote(md.Element element) async {
    final innerWidgets = await convertNodes(element.children ?? []);
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.fromLTRB(12, 6, 8, 6),
      decoration: const pw.BoxDecoration(
        color: _codeBg,
        border: pw.Border(
          left: pw.BorderSide(color: _blockquoteBorder, width: 3.5),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: innerWidgets,
      ),
    );
  }

  Future<pw.Widget> _buildList(md.Element element, {required bool ordered}) async {
    final items = element.children?.whereType<md.Element>().toList() ?? [];
    final itemWidgets = <pw.Widget>[];

    int index = 1;
    for (final item in items) {
      if (item.tag == 'li') {
        itemWidgets.add(await _buildListItem(item, ordered: ordered, index: index++));
      }
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: itemWidgets,
      ),
    );
  }

  Future<pw.Widget> _buildListItem(
    md.Element li, {
    required bool ordered,
    required int index,
  }) async {
    // Check for Task List checkbox (e.g., "- [ ] " or "- [x] ")
    final rawText = li.textContent.trimLeft();
    final isTaskUnchecked = rawText.startsWith('[ ] ');
    final isTaskChecked = rawText.startsWith('[x] ') || rawText.startsWith('[X] ');
    final isTask = isTaskUnchecked || isTaskChecked;

    pw.Widget markerWidget;
    if (isTask) {
      markerWidget = pw.Container(
        margin: const pw.EdgeInsets.only(top: 2, right: 6),
        width: 9,
        height: 9,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: isTaskChecked ? _linkBlue : _textMuted, width: 1),
          borderRadius: pw.BorderRadius.circular(2),
          color: isTaskChecked ? _linkBlue : null,
        ),
        child: isTaskChecked
            ? pw.Center(
                child: pw.Container(
                  width: 4,
                  height: 4,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.white,
                    shape: pw.BoxShape.rectangle,
                  ),
                ),
              )
            : null,
      );
    } else if (ordered) {
      markerWidget = pw.SizedBox(
        width: 18,
        child: pw.Text(
          '$index.',
          style: pw.TextStyle(
            font: fonts.regular,
            fontSize: 10,
            color: _textPrimary,
          ),
        ),
      );
    } else {
      markerWidget = pw.Container(
        width: 14,
        alignment: pw.Alignment.centerLeft,
        padding: const pw.EdgeInsets.only(top: 4, right: 6),
        child: pw.Container(
          width: 3.5,
          height: 3.5,
          decoration: const pw.BoxDecoration(
            color: _textPrimary,
            shape: pw.BoxShape.circle,
          ),
        ),
      );
    }

    // Process children of LI (which may contain text, paragraphs, or nested lists)
    final nestedBlocks = <pw.Widget>[];
    final inlineNodes = <md.Node>[];

    for (final child in li.children ?? []) {
      if (child is md.Element && (child.tag == 'ul' || child.tag == 'ol')) {
        nestedBlocks.add(await _buildList(child, ordered: child.tag == 'ol'));
      } else if (child is md.Element && child.tag == 'p') {
        inlineNodes.addAll(child.children ?? []);
      } else {
        inlineNodes.add(child);
      }
    }

    // Strip task list marker prefix from text if present
    final spans = _convertInlineNodes(inlineNodes);
    if (isTask && spans.isNotEmpty) {
      final firstSpan = spans.first;
      if (firstSpan.text != null &&
          (firstSpan.text!.startsWith('[ ] ') ||
              firstSpan.text!.startsWith('[x] ') ||
              firstSpan.text!.startsWith('[X] '))) {
        final stripped = firstSpan.text!.substring(4);
        spans[0] = pw.TextSpan(
          text: stripped,
          style: firstSpan.style,
          children: firstSpan.children,
        );
      }
    }

    final contentWidget = pw.RichText(
      text: pw.TextSpan(
        children: spans.isEmpty
            ? [pw.TextSpan(text: isTask ? rawText.substring(4) : li.textContent)]
            : spans,
        style: pw.TextStyle(
          font: fonts.regular,
          fontSize: 10.5,
          color: _textPrimary,
          lineSpacing: 1.3,
        ),
      ),
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              markerWidget,
              pw.Expanded(child: contentWidget),
            ],
          ),
          if (nestedBlocks.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 16, top: 2),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: nestedBlocks,
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildCodeBlock(md.Element element) {
    String code = '';
    String? language;

    final children = element.children;
    if (children != null && children.isNotEmpty) {
      final first = children.first;
      if (first is md.Element && first.tag == 'code') {
        code = first.textContent;
        final classAttr = first.attributes['class'] ?? '';
        if (classAttr.startsWith('language-')) {
          language = classAttr.substring(9);
        }
      } else {
        code = element.textContent;
      }
    } else {
      code = element.textContent;
    }

    // Check if language is specified or is mermaid
    final isMermaid = language?.toLowerCase() == 'mermaid';

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      width: double.infinity,
      decoration: pw.BoxDecoration(
        color: _codeBg,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _codeBorder, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (language != null && language.isNotEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: _codeBorder, width: 0.5),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    isMermaid ? 'Mermaid Diagram' : language.toUpperCase(),
                    style: pw.TextStyle(
                      font: fonts.bold,
                      fontSize: 7.5,
                      color: _textMuted,
                    ),
                  ),
                ],
              ),
            ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Text(
              code.trimRight(),
              style: pw.TextStyle(
                font: fonts.mono,
                fontSize: 8.5,
                color: _textPrimary,
                lineSpacing: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTable(md.Element tableElement) {
    final rows = <pw.TableRow>[];
    final tableChildren = tableElement.children;
    if (tableChildren == null) return pw.SizedBox.shrink();

    for (final section in tableChildren) {
      if (section is! md.Element) continue;
      final sectionChildren = section.children;
      if (sectionChildren == null) continue;

      if (section.tag == 'thead') {
        for (final tr in sectionChildren) {
          if (tr is md.Element && tr.tag == 'tr') {
            final trChildren = tr.children;
            if (trChildren == null) continue;
            final cells = <pw.Widget>[];
            for (final th in trChildren) {
              if (th is md.Element && th.tag == 'th') {
                cells.add(
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    alignment: _parseAlignment(th.attributes['align']),
                    child: pw.Text(
                      th.textContent.trim(),
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: 9.5,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                );
              }
            }
            if (cells.isNotEmpty) {
              rows.add(
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _codeBg),
                  children: cells,
                ),
              );
            }
          }
        }
      } else if (section.tag == 'tbody') {
        int rowIndex = 0;
        for (final tr in sectionChildren) {
          if (tr is md.Element && tr.tag == 'tr') {
            final trChildren = tr.children;
            if (trChildren == null) continue;
            final cells = <pw.Widget>[];
            for (final td in trChildren) {
              if (td is md.Element && td.tag == 'td') {
                final spans = _convertInlineNodes(td.children ?? []);
                cells.add(
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    alignment: _parseAlignment(td.attributes['align']),
                    child: pw.RichText(
                      text: pw.TextSpan(
                        children: spans.isEmpty
                            ? [pw.TextSpan(text: td.textContent.trim())]
                            : spans,
                        style: pw.TextStyle(
                          font: fonts.regular,
                          fontSize: 9,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }
            }
            if (cells.isNotEmpty) {
              rows.add(
                pw.TableRow(
                  decoration: rowIndex % 2 == 1
                      ? const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFAFBFC))
                      : null,
                  children: cells,
                ),
              );
              rowIndex++;
            }
          }
        }
      } else if (section.tag == 'tr') {
        // Fallback for tables without thead/tbody wrappers
        final cells = <pw.Widget>[];
        for (final cell in sectionChildren) {
          if (cell is md.Element) {
            final isHeader = cell.tag == 'th';
            cells.add(
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                alignment: _parseAlignment(cell.attributes['align']),
                child: pw.Text(
                  cell.textContent.trim(),
                  style: pw.TextStyle(
                    font: isHeader ? fonts.bold : fonts.regular,
                    fontSize: 9,
                    color: _textPrimary,
                  ),
                ),
              ),
            );
          }
        }
        if (cells.isNotEmpty) {
          rows.add(pw.TableRow(children: cells));
        }
      }
    }

    if (rows.isEmpty) return pw.SizedBox.shrink();

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Table(
        border: pw.TableBorder.all(color: _codeBorder, width: 0.6),
        children: rows,
      ),
    );
  }

  pw.Alignment _parseAlignment(String? align) {
    switch (align?.toLowerCase()) {
      case 'center':
        return pw.Alignment.center;
      case 'right':
        return pw.Alignment.centerRight;
      default:
        return pw.Alignment.centerLeft;
    }
  }

  Future<pw.Widget?> _buildImageElement(md.Element element) async {
    final src = element.attributes['src'];
    final alt = element.attributes['alt'] ?? '';

    if (src == null || src.isEmpty) return null;

    try {
      String imagePath = src;
      if (!p.isAbsolute(imagePath) && basePath != null) {
        imagePath = p.normalize(p.join(basePath!, imagePath));
      }

      final file = File(imagePath);
      if (await file.exists()) {
        final imageBytes = await file.readAsBytes();
        final image = pw.MemoryImage(imageBytes);
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.ConstrainedBox(
                constraints: const pw.BoxConstraints(maxHeight: 300),
                child: pw.Image(image, fit: pw.BoxFit.contain),
              ),
              if (alt.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Text(
                    alt,
                    style: pw.TextStyle(
                      font: fonts.regular,
                      fontSize: 8.5,
                      color: _textMuted,
                    ),
                  ),
                ),
            ],
          ),
        );
      }
    } catch (_) {
      // Ignore image load error and fallback
    }

    // Fallback if image not found on disk
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(
        alt.isNotEmpty ? '[Image: $alt]' : '[Image: $src]',
        style: pw.TextStyle(
          font: fonts.regular,
          fontSize: 9,
          color: _textMuted,
        ),
      ),
    );
  }

  List<pw.TextSpan> _convertInlineNodes(
    List<md.Node> nodes, {
    pw.TextStyle? inheritedStyle,
  }) {
    final spans = <pw.TextSpan>[];

    for (final node in nodes) {
      if (node is md.Text) {
        spans.add(pw.TextSpan(
          text: node.text,
          style: inheritedStyle,
        ));
      } else if (node is md.Element) {
        switch (node.tag) {
          case 'strong':
          case 'b':
            spans.addAll(_convertInlineNodes(
              node.children ?? [],
              inheritedStyle: (inheritedStyle ?? const pw.TextStyle()).copyWith(
                font: fonts.bold,
              ),
            ));
            break;

          case 'em':
          case 'i':
            spans.addAll(_convertInlineNodes(
              node.children ?? [],
              inheritedStyle: (inheritedStyle ?? const pw.TextStyle()).copyWith(
                font: fonts.italic ?? fonts.regular,
                fontStyle: pw.FontStyle.italic,
              ),
            ));
            break;

          case 'code':
            spans.add(pw.TextSpan(
              text: node.textContent,
              style: (inheritedStyle ?? const pw.TextStyle()).copyWith(
                font: fonts.mono,
                fontSize: 9,
                color: _codeInlineColor,
              ),
            ));
            break;

          case 'a':
            final href = node.attributes['href'] ?? '';
            final text = node.textContent;
            spans.add(pw.TextSpan(
              text: text.isNotEmpty ? text : href,
              style: (inheritedStyle ?? const pw.TextStyle()).copyWith(
                color: _linkBlue,
                decoration: pw.TextDecoration.underline,
              ),
            ));
            break;

          case 'del':
            spans.addAll(_convertInlineNodes(
              node.children ?? [],
              inheritedStyle: (inheritedStyle ?? const pw.TextStyle()).copyWith(
                decoration: pw.TextDecoration.lineThrough,
              ),
            ));
            break;

          default:
            if (node.children != null && node.children!.isNotEmpty) {
              spans.addAll(_convertInlineNodes(
                node.children!,
                inheritedStyle: inheritedStyle,
              ));
            } else {
              spans.add(pw.TextSpan(
                text: node.textContent,
                style: inheritedStyle,
              ));
            }
            break;
        }
      }
    }

    return spans;
  }
}
