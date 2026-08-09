import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:markdown/markdown.dart' as md;

import 'mermaid_view.dart';

/// A scrollable Markdown viewer with syntax-highlighted code blocks,
/// clickable links, and image support relative to [basePath].
class MarkdownViewer extends StatelessWidget {
  const MarkdownViewer({
    super.key,
    required this.content,
    required this.scrollController,
    required this.basePath,
    required this.searchQuery,
    this.horizontalPadding = 32,
  });

  final String content;
  final ScrollController scrollController;
  final String basePath;
  final String searchQuery;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final styleSheet = _buildStyleSheet(context, isDark);
    final highlightBackground = isDark
        ? theme.colorScheme.secondaryContainer.withOpacity(0.75)
        : theme.colorScheme.secondaryContainer;
    final highlightForeground = theme.colorScheme.onSecondaryContainer;
    final codeBackground = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFFF6F8FA);

    return Scrollbar(
      controller: scrollController,
      child: Markdown(
        controller: scrollController,
        data: content,
        selectable: true,
        shrinkWrap: false,
        imageDirectory: basePath,
        extensionSet: _buildExtensionSet(),
        builders: _buildBuilders(
          styleSheet,
          highlightBackground,
          highlightForeground,
          isDark: isDark,
          codeBackground: codeBackground,
          codeForeground: theme.colorScheme.onSurface,
        ),
        onTapLink: (text, href, title) async {
          if (href == null) return;
          final uri = Uri.tryParse(href);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        styleSheet: styleSheet,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 24,
        ),
      ),
    );
  }

  md.ExtensionSet _buildExtensionSet() {
    final inlineSyntaxes = <md.InlineSyntax>[
      if (searchQuery.trim().isNotEmpty)
        SearchHighlightSyntax(searchQuery.trim()),
      md.EmojiSyntax(),
      ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
    ];
    return md.ExtensionSet(
      md.ExtensionSet.gitHubFlavored.blockSyntaxes,
      inlineSyntaxes,
    );
  }

  Map<String, MarkdownElementBuilder> _buildBuilders(
    MarkdownStyleSheet styleSheet,
    Color highlightBackground,
    Color highlightForeground, {
    required bool isDark,
    required Color codeBackground,
    required Color codeForeground,
  }) {
    final query = searchQuery.trim();

    final builders = <String, MarkdownElementBuilder>{
      // Always registered: renders ```mermaid``` blocks as diagrams and
      // falls back to (optionally highlighted) code blocks otherwise.
      'pre': _CodeBlockBuilder(
        query: query,
        styleSheet: styleSheet,
        isDark: isDark,
        codeBackground: codeBackground,
        codeForeground: codeForeground,
        highlightBackground: highlightBackground,
        highlightForeground: highlightForeground,
      ),
    };

    if (query.isNotEmpty) {
      builders['a'] = _SearchLinkBuilder(
        query: query,
        highlightBackground: highlightBackground,
        highlightForeground: highlightForeground,
      );
      builders['code'] = _SearchCodeBuilder(
        query: query,
        styleSheet: styleSheet,
        highlightBackground: highlightBackground,
        highlightForeground: highlightForeground,
      );
      builders['mark'] = _SearchMarkBuilder(
        query: query,
        highlightBackground: highlightBackground,
        highlightForeground: highlightForeground,
      );
    }

    return builders;
  }

  MarkdownStyleSheet _buildStyleSheet(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final codeFont = GoogleFonts.firaCode(fontSize: 13.5);
    final bodyFont = GoogleFonts.inter();

    final codeBg = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFFF6F8FA);
    final blockquoteBorderColor = isDark
        ? theme.colorScheme.primary.withOpacity(0.6)
        : theme.colorScheme.primary;

    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: bodyFont.copyWith(
        fontSize: 16,
        height: 1.7,
        color: theme.colorScheme.onSurface,
      ),
      h1: bodyFont.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      h2: bodyFont.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      h3: bodyFont.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      h4: bodyFont.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
      h5: bodyFont.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
      h6: bodyFont.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      code: codeFont.copyWith(
        backgroundColor: codeBg,
        color: isDark
            ? theme.colorScheme.primary
            : const Color(0xFFD63200),
      ),
      codeblockDecoration: BoxDecoration(
        color: codeBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      codeblockPadding: const EdgeInsets.all(16),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: blockquoteBorderColor, width: 4),
        ),
        color: blockquoteBorderColor.withOpacity(0.08),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      tableHead: bodyFont.copyWith(fontWeight: FontWeight.bold),
      tableBody: bodyFont,
      tableBorder: TableBorder.all(
        color: theme.colorScheme.outlineVariant,
        width: 1,
      ),
      tableHeadAlign: TextAlign.left,
      a: bodyFont.copyWith(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: theme.colorScheme.primary.withOpacity(0.5),
      ),
      listBullet: bodyFont.copyWith(
        fontSize: 16,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

TextSpan buildHighlightedTextSpan(
  String text,
  TextStyle? baseStyle,
  String query, {
  required Color highlightBackground,
  required Color highlightForeground,
}) {
  final trimmedQuery = query.trim();
  if (trimmedQuery.isEmpty || text.isEmpty) {
    return TextSpan(text: text, style: baseStyle);
  }

  final matches = RegExp(
    RegExp.escape(trimmedQuery),
    caseSensitive: false,
  ).allMatches(text);
  final spans = <InlineSpan>[];
  var lastIndex = 0;

  for (final match in matches) {
    if (match.start > lastIndex) {
      spans.add(TextSpan(
        text: text.substring(lastIndex, match.start),
        style: baseStyle,
      ));
    }

    spans.add(TextSpan(
      text: text.substring(match.start, match.end),
      style: baseStyle?.copyWith(
        backgroundColor: highlightBackground,
        color: highlightForeground,
      ),
    ));
    lastIndex = match.end;
  }

  if (spans.isEmpty) {
    return TextSpan(text: text, style: baseStyle);
  }

  if (lastIndex < text.length) {
    spans.add(TextSpan(
      text: text.substring(lastIndex),
      style: baseStyle,
    ));
  }

  return TextSpan(children: spans, style: baseStyle);
}

class SearchHighlightSyntax extends md.InlineSyntax {
  SearchHighlightSyntax(String query)
      : super(RegExp.escape(query), caseSensitive: false);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('mark', match.group(0)!));
    return true;
  }
}

class _SearchMarkBuilder extends MarkdownElementBuilder {
  _SearchMarkBuilder({
    required this.query,
    required this.highlightBackground,
    required this.highlightForeground,
  });

  final String query;
  final Color highlightBackground;
  final Color highlightForeground;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return SelectableText.rich(
      buildHighlightedTextSpan(
        element.textContent,
        preferredStyle ?? parentStyle,
        query,
        highlightBackground: highlightBackground,
        highlightForeground: highlightForeground,
      ),
      textScaler: MediaQuery.textScalerOf(context),
    );
  }
}

class _SearchLinkBuilder extends MarkdownElementBuilder {
  _SearchLinkBuilder({
    required this.query,
    required this.highlightBackground,
    required this.highlightForeground,
  });

  final String query;
  final Color highlightBackground;
  final Color highlightForeground;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final href = element.attributes['href'];
    if (href == null) {
      return null;
    }

    final style = (preferredStyle ?? parentStyle)?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
    );

    return SelectableText.rich(
      buildHighlightedTextSpan(
        element.textContent,
        style,
        query,
        highlightBackground: highlightBackground,
        highlightForeground: highlightForeground,
      ),
      textScaler: MediaQuery.textScalerOf(context),
      onTap: () async {
        final uri = Uri.tryParse(href);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
    );
  }
}

class _SearchCodeBuilder extends MarkdownElementBuilder {
  _SearchCodeBuilder({
    required this.query,
    required this.styleSheet,
    required this.highlightBackground,
    required this.highlightForeground,
  });

  final String query;
  final MarkdownStyleSheet styleSheet;
  final Color highlightBackground;
  final Color highlightForeground;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return SelectableText.rich(
      buildHighlightedTextSpan(
        element.textContent,
        preferredStyle ?? styleSheet.code,
        query,
        highlightBackground: highlightBackground,
        highlightForeground: highlightForeground,
      ),
      textScaler: MediaQuery.textScalerOf(context),
    );
  }
}

class _CodeBlockBuilder extends MarkdownElementBuilder {
  _CodeBlockBuilder({
    required this.query,
    required this.styleSheet,
    required this.isDark,
    required this.codeBackground,
    required this.codeForeground,
    required this.highlightBackground,
    required this.highlightForeground,
  });

  final String query;
  final MarkdownStyleSheet styleSheet;
  final bool isDark;
  final Color codeBackground;
  final Color codeForeground;
  final Color highlightBackground;
  final Color highlightForeground;

  @override
  bool isBlockElement() => true;

  /// Returns the diagram source when [pre] wraps a ```mermaid``` fenced block.
  String? _mermaidSource(md.Element pre) {
    final children = pre.children;
    if (children == null) return null;
    for (final node in children) {
      if (node is md.Element && node.tag == 'code') {
        final classes = (node.attributes['class'] ?? '').split(' ');
        if (classes.contains('language-mermaid')) {
          final text = node.textContent;
          final trimmed = text.endsWith('\n')
              ? text.substring(0, text.length - 1)
              : text;
          return decodeHtmlEntities(trimmed);
        }
        return null;
      }
    }
    return null;
  }

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final mermaid = _mermaidSource(element);
    if (mermaid != null && mermaid.trim().isNotEmpty) {
      return MermaidView(
        key: ValueKey('mermaid:${mermaid.hashCode}:$isDark'),
        code: mermaid,
        isDark: isDark,
        backgroundColor: codeBackground,
        foregroundColor: codeForeground,
      );
    }

    // Not a mermaid block. Without a search query, defer to the default
    // code-block rendering by returning null.
    if (query.isEmpty) {
      return null;
    }

    // With an active query, render the code with search highlighting. The
    // surrounding decoration is provided by flutter_markdown's `pre` wrapper.
    return SingleChildScrollView(
      padding: styleSheet.codeblockPadding,
      scrollDirection: Axis.horizontal,
      child: SelectableText.rich(
        buildHighlightedTextSpan(
          element.textContent,
          styleSheet.code,
          query,
          highlightBackground: highlightBackground,
          highlightForeground: highlightForeground,
        ),
        textScaler: MediaQuery.textScalerOf(context),
      ),
    );
  }
}
