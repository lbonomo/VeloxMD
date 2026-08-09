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
}
