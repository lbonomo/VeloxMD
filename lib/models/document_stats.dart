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

    final lines = content.split('\n');
    final characters = content.length;
    final words = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    
    final headingRegex = RegExp(r'^#{1,6}\s+');
    final linkRegex = RegExp(r'\[([^\]]+)\]\(([^\)]+)\)');
    final codeBlockRegex = RegExp(r'^```', multiLine: true);
    
    final headings = lines.where((l) => headingRegex.hasMatch(l)).length;
    final links = linkRegex.allMatches(content).length;
    final codeBlocks = (codeBlockRegex.allMatches(content).length / 2).ceil();
    
    // Calculate tokens using industry standard (OpenAI's approximation)
    final tokens = _calculateTokens(content);

    return DocumentStats(
      characters: characters,
      words: words,
      lines: lines.length,
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
  static int _calculateTokens(String content) {
    if (content.isEmpty) return 0;
    
    // Method 1: Characters-based (1 token ≈ 4 characters)
    final tokensByChars = (content.length / 4).ceil();
    
    // Method 2: Words-based (1 token ≈ 0.75 words, or 1.33 words per token)
    final words = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final tokensByWords = (words * 1.3).ceil();
    
    // Use average for better estimation
    return ((tokensByChars + tokensByWords) / 2).ceil();
  }
}
