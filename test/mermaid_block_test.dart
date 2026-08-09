import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:veloxmd/widgets/mermaid_view.dart';

/// The Mermaid builder in `markdown_viewer.dart` detects diagrams by looking
/// for a `pre > code` element whose class list contains `language-mermaid`,
/// then decodes the HTML entities the Markdown parser injects. These tests
/// lock both halves of that contract.
void main() {
  md.Element preFor(String source) {
    final nodes = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
    ).parse(source);
    return nodes.whereType<md.Element>().firstWhere((e) => e.tag == 'pre');
  }

  md.Element? codeChild(md.Element pre) {
    return pre.children
        ?.whereType<md.Element>()
        .cast<md.Element?>()
        .firstWhere((e) => e?.tag == 'code', orElse: () => null);
  }

  test('fenced mermaid block is tagged language-mermaid', () {
    const source = '```mermaid\ngraph TD;\n  A-->B;\n```';
    final pre = preFor(source);
    expect(pre.tag, 'pre');

    final code = codeChild(pre)!;
    final classes = (code.attributes['class'] ?? '').split(' ');
    expect(classes, contains('language-mermaid'));
  });

  test('non-mermaid fenced block is not tagged as mermaid', () {
    const source = '```dart\nvoid main() {}\n```';
    final code = codeChild(preFor(source))!;
    final classes = (code.attributes['class'] ?? '').split(' ');
    expect(classes, isNot(contains('language-mermaid')));
    expect(classes, contains('language-dart'));
  });

  test('parser escapes arrows; decodeHtmlEntities restores raw source', () {
    const source = '```mermaid\ngraph TD;\n  A-->B;\n```';
    final code = codeChild(preFor(source))!;
    // The AST stores HTML-escaped content.
    expect(code.textContent, contains('--&gt;'));
    // Decoding recovers the mermaid-usable source.
    expect(decodeHtmlEntities(code.textContent).trimRight(), 'graph TD;\n  A-->B;');
  });

  test('decodeHtmlEntities handles named, decimal and hex entities', () {
    expect(decodeHtmlEntities('a &amp; b'), 'a & b');
    expect(decodeHtmlEntities('&lt;x&gt;'), '<x>');
    expect(decodeHtmlEntities('&quot;q&quot;'), '"q"');
    expect(decodeHtmlEntities('&#39;s&#39;'), "'s'");
    expect(decodeHtmlEntities('&#x27;h&#x27;'), "'h'");
  });
}
