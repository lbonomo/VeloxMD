/// A single entry in the table of contents extracted from Markdown headings.
class TocEntry {
  const TocEntry({
    required this.title,
    required this.level,
    required this.anchor,
    required this.index,
  });

  /// Heading text.
  final String title;

  /// ATX heading level (1–6).
  final int level;

  /// Generated anchor slug (lowercase, spaces → hyphens).
  final String anchor;

  /// Zero-based occurrence index used for scrolling.
  final int index;

  /// Parse all ATX headings from [markdown] and return a flat list of entries.
  static List<TocEntry> fromMarkdown(String markdown) {
    final entries = <TocEntry>[];
    int index = 0;

    for (final line in markdown.split('\n')) {
      final match = _headingPattern.firstMatch(line);
      if (match != null) {
        final hashes = match.group(1)!;
        final text = match.group(2)!.trim();
        entries.add(TocEntry(
          title: text,
          level: hashes.length,
          anchor: _toAnchor(text),
          index: index++,
        ));
      }
    }

    return entries;
  }

  static final _headingPattern = RegExp(r'^(#{1,6})\s+(.+)$');

  static String _toAnchor(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s-]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '-');

  @override
  String toString() => 'TocEntry(level: $level, title: $title)';
}
