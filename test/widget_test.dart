import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloxmd/widgets/markdown_viewer.dart';

void main() {
  test('buildHighlightedTextSpan highlights matches', () {
    final span = buildHighlightedTextSpan(
      'Hello world, hello VeloxMD',
      const TextStyle(color: Colors.black),
      'hello',
      highlightBackground: Colors.yellow,
      highlightForeground: Colors.black,
    );

    expect(span.children, isNotNull);
    final children = span.children!.cast<TextSpan>();

    expect(children, hasLength(4));
    expect(children[0].text, 'Hello');
    expect(children[0].style?.backgroundColor, Colors.yellow);
    expect(children[1].text, ' world, ');
    expect(children[2].text, 'hello');
    expect(children[2].style?.backgroundColor, Colors.yellow);
    expect(children[3].text, ' VeloxMD');
  });

  test('buildHighlightedTextSpan escapes regex characters', () {
    final span = buildHighlightedTextSpan(
      'C++ and C++',
      const TextStyle(color: Colors.black),
      'C++',
      highlightBackground: Colors.yellow,
      highlightForeground: Colors.black,
    );

    final children = span.children!.cast<TextSpan>();

    expect(children, hasLength(3));
    expect(children[0].text, 'C++');
    expect(children[0].style?.backgroundColor, Colors.yellow);
    expect(children[1].text, ' and ');
    expect(children[2].text, 'C++');
  });

  group('countHighlightMatches', () {
    test('counts every case-insensitive occurrence in body text', () {
      expect(
        countHighlightMatches('banana apple banana grape banana', 'banana'),
        3,
      );
      expect(countHighlightMatches('World and WORLD and world', 'world'), 3);
    });

    test('counts matches across markdown formatting and headings', () {
      const content = '## Problema\n\nText with **Problema** and Problema.';
      expect(countHighlightMatches(content, 'Problema'), 3);
    });

    test('ignores matches inside fenced code blocks (not highlighted)', () {
      const content = 'foo\n\n```\nfoo foo\n```\n\nfoo';
      // Only the two body occurrences are highlighted; the fenced ones are not.
      expect(countHighlightMatches(content, 'foo'), 2);
    });

    test('returns 0 for empty query or empty content', () {
      expect(countHighlightMatches('anything here', ''), 0);
      expect(countHighlightMatches('anything here', '   '), 0);
      expect(countHighlightMatches('', 'query'), 0);
    });

    test('escapes regex metacharacters in the query', () {
      expect(countHighlightMatches('C++ and C++ again', 'C++'), 2);
    });
  });
}
