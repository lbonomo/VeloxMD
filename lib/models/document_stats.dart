class DocumentStats {
  final int characters;
  final int words;
  final int lines;
  final int headings;
  final int links;
  final int codeBlocks;
  final int tokens;

  DocumentStats({
    required this.characters,
    required this.words,
    required this.lines,
    required this.headings,
    required this.links,
    required this.codeBlocks,
    required this.tokens,
  });

  static final _wordRegex = RegExp(r'\S+');
  static final _headingRegex = RegExp(r'^#{1,6}\s+', multiLine: true);
  static final _linkRegex = RegExp(r'\[([^\]]+)\]\(([^\)]+)\)');
  static final _codeBlockRegex = RegExp(r'^```', multiLine: true);

  factory DocumentStats.fromMarkdown(String content) {
    if (content.isEmpty) {
      return DocumentStats(
        characters: 0,
        words: 0,
        lines: 0,
        headings: 0,
        links: 0,
        codeBlocks: 0,
        tokens: 0,
      );
    }

    final characters = content.length;

    int lineCount = 1;
    for (int i = 0; i < content.length; i++) {
      if (content.codeUnitAt(i) == 10) {
        lineCount++;
      }
    }

    final words = _wordRegex.allMatches(content).length;
    final headings = _headingRegex.allMatches(content).length;
    final links = _linkRegex.allMatches(content).length;
    final codeBlocks = (_codeBlockRegex.allMatches(content).length / 2).ceil();

    final tokens = _calculateTokens(characters, words);

    return DocumentStats(
      characters: characters,
      words: words,
      lines: lineCount,
      headings: headings,
      links: links,
      codeBlocks: codeBlocks,
      tokens: tokens,
    );
  }

  /// Calculates tokens using industry standard approximation.
  /// Based on OpenAI's tokenizer estimates:
  /// - 1 token ≈ 4 characters
  /// - 1 token ≈ 0.75 words
  /// Uses the average of both calculations for better accuracy.
  static int _calculateTokens(int characters, int words) {
    if (characters == 0) return 0;

    final tokensByChars = (characters / 4).ceil();
    final tokensByWords = (words * 1.3).ceil();

    return ((tokensByChars + tokensByWords) / 2).ceil();
  }
}
