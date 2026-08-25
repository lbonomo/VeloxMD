import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:markdown/markdown.dart' as md;

import 'mermaid_view.dart';

/// Stable [GlobalKey]s for rendered ```mermaid``` diagrams, keyed by diagram
/// source + theme. Searching re-parses the whole document (to recolour the
/// highlights), which would otherwise recreate every widget and re-initialise
/// each diagram's CEF webview. Reusing a GlobalKey lets Flutter *reparent* the
/// existing [MermaidView] element instead of rebuilding it, so the diagrams
/// keep their state and do not flicker/reload on every keystroke.
final Map<String, GlobalKey> _mermaidViewKeys = <String, GlobalKey>{};

GlobalKey _mermaidViewKey(String source, bool isDark) =>
    _mermaidViewKeys.putIfAbsent(
      '${source.hashCode}:$isDark',
      () => GlobalKey(debugLabel: 'mermaid:${source.hashCode}:$isDark'),
    );

/// Drops the cached diagram keys. Call when switching to a different document
/// so keys for diagrams that no longer exist do not accumulate.
void clearMermaidViewKeyCache() => _mermaidViewKeys.clear();

/// The Markdown extension set used by the viewer. When [query] is non-empty a
/// [_SearchHighlightSyntax] is prepended so every match is wrapped in a
/// highlight element. Shared between the rendered widget and
/// [countHighlightMatches] so the visible highlights and the reported match
/// count are guaranteed to agree.
md.ExtensionSet buildMarkdownExtensionSet(String query) => md.ExtensionSet(
      <md.BlockSyntax>[
        const _MermaidFenceSyntax(),
        const _CodeFenceSyntax(),
        ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
      ],
      <md.InlineSyntax>[
        if (query.isNotEmpty) _SearchHighlightSyntax(query),
        md.EmojiSyntax(),
        ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
      ],
    );

/// Counts how many occurrences of [query] would actually be highlighted in the
/// rendered [content]. Parses the document with the exact same extension set
/// the viewer uses and counts the emitted highlight elements, so matches inside
/// fenced code blocks (which are not inline-parsed) are correctly excluded and
/// the count matches what the user sees.
int countHighlightMatches(String content, String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty || content.isEmpty) return 0;

  final document = md.Document(
    extensionSet: buildMarkdownExtensionSet(trimmed),
    encodeHtml: false,
  );
  final nodes = document.parseLines(const LineSplitter().convert(content));

  var count = 0;
  void walk(List<md.Node> ns) {
    for (final node in ns) {
      if (node is md.Element) {
        if (node.tag == _SearchHighlightSyntax.tag) count++;
        final children = node.children;
        if (children != null) walk(children);
      }
    }
  }

  walk(nodes);
  return count;
}

MarkdownStyleSheet buildViewerMarkdownStyleSheet(
  ThemeData theme, {
  required bool isDark,
  required bool useBundledFonts,
  required double fontScale,
}) {
  final codeFont = useBundledFonts
      ? TextStyle(fontFamily: 'FiraCode', fontSize: 13.5 * fontScale)
      : TextStyle(fontFamily: 'monospace', fontSize: 13.5 * fontScale);
  final bodyFont =
      useBundledFonts ? const TextStyle(fontFamily: 'Inter') : const TextStyle();

  final codeBg = isDark
      ? theme.colorScheme.surfaceContainerHighest
      : const Color(0xFFF6F8FA);
  final blockquoteBorderColor = isDark
      ? theme.colorScheme.primary.withOpacity(0.6)
      : theme.colorScheme.primary;

  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    p: bodyFont.copyWith(
      fontSize: 16 * fontScale,
      height: 1.7,
      color: theme.colorScheme.onSurface,
    ),
    h1: bodyFont.copyWith(
      fontSize: 32 * fontScale,
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface,
    ),
    h2: bodyFont.copyWith(
      fontSize: 26 * fontScale,
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface,
    ),
    h3: bodyFont.copyWith(
      fontSize: 22 * fontScale,
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface,
    ),
    h4: bodyFont.copyWith(
      fontSize: 18 * fontScale,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    ),
    h5: bodyFont.copyWith(
      fontSize: 16 * fontScale,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    ),
    h6: bodyFont.copyWith(
      fontSize: 14 * fontScale,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurfaceVariant,
    ),
    code: codeFont.copyWith(
      backgroundColor: codeBg,
      color: isDark ? theme.colorScheme.primary : const Color(0xFFD63200),
    ),
    codeblockDecoration: BoxDecoration(
      color: codeBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
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
        top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
    ),
    tableHead: bodyFont.copyWith(
      fontSize: 16 * fontScale,
      fontWeight: FontWeight.bold,
    ),
    tableBody: bodyFont.copyWith(fontSize: 16 * fontScale),
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
      fontSize: 16 * fontScale,
      color: theme.colorScheme.primary,
    ),
  );
}

/// Renders fenced code blocks with syntax highlighting via flutter_highlight.
class _CodeBlockBuilder extends MarkdownElementBuilder {
  _CodeBlockBuilder({
    required this.isDark,
    required this.codeBackground,
    required this.codeForeground,
  });

  final bool isDark;
  final Color codeBackground;
  final Color codeForeground;

  @override
  bool isBlockElement() => true;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = (element.attributes['content'] ?? '').trimRight();
    if (code.isEmpty) return const SizedBox.shrink();

    final language = _normalizeCodeLanguage(element.attributes['language']);
    final effectiveFontSize =
        preferredStyle?.fontSize ?? parentStyle?.fontSize ?? 13.5;
    final effectiveFontFamily =
        (preferredStyle ?? parentStyle)?.fontFamily ?? 'FiraCode';
    final textStyle = (preferredStyle ?? parentStyle ?? const TextStyle())
        .copyWith(
          color: codeForeground,
          fontFamily: effectiveFontFamily,
          fontSize: effectiveFontSize,
        );
    final theme = Map<String, TextStyle>.from(
      isDark ? monokaiSublimeTheme : githubTheme,
    ).map(
      (token, style) => MapEntry(
        token,
        style.copyWith(
          fontFamily: effectiveFontFamily,
          fontSize: effectiveFontSize,
        ),
      ),
    );
    final rootStyle = (theme['root'] ?? const TextStyle()).copyWith(
      backgroundColor: Colors.transparent,
      color: codeForeground,
    );
    theme['root'] = rootStyle;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: codeBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: HighlightView(
        code,
        language: language,
        theme: theme,
        padding: const EdgeInsets.all(16),
        textStyle: textStyle,
      ),
    );
  }
}

String _normalizeCodeLanguage(String? info) {
  final trimmed = info?.trim() ?? '';
  if (trimmed.isEmpty) return 'plaintext';
  final raw = trimmed.split(RegExp(r'\s+')).first.toLowerCase();
  return switch (raw) {
    'sh' || 'shell' || 'zsh' => 'bash',
    'js' => 'javascript',
    'ts' => 'typescript',
    'yml' => 'yaml',
    'text' || 'plain' || 'plaintext' => 'plaintext',
    _ => raw,
  };
}

/// A scrollable Markdown viewer with syntax-highlighted code blocks,
/// clickable links, ```mermaid``` diagram rendering, and image support
/// relative to [basePath].
///
/// Search matches are highlighted inline. [activeMatchIndex] marks the
/// currently focused occurrence with a distinct color and scrolls it into
/// view. [horizontalPadding] controls the left/right content margin.
class MarkdownViewer extends StatelessWidget {
  const MarkdownViewer({
    super.key,
    required this.content,
    required this.scrollController,
    required this.basePath,
    this.searchQuery = '',
    this.activeMatchIndex = 0,
    this.useBundledFonts = true,
    this.horizontalPadding = 32,
    this.fontScale = 1.0,
  });

  final String content;
  final ScrollController scrollController;
  final String basePath;
  final String searchQuery;
  final int activeMatchIndex;
  final bool useBundledFonts;
  final double horizontalPadding;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final query = searchQuery.trim();
    // Light mode: warm yellow highlight, keeping the default (dark) text color.
    // Dark mode: blue highlight with an inverted (dark) text color for contrast.
    final matchBackgroundColor = isDark
        ? const Color(0xFF44ACFF)
        : const Color(0xFFFFFBA7);
    final activeMatchBackgroundColor = isDark
        ? const Color(0xFF89D4FF)
        : const Color(0xFFFFEA6C);
    // In dark mode invert the text color so it stays legible over the blue
    // highlight; in light mode keep the document's own foreground (null).
    final matchForegroundColor = isDark ? Colors.black : null;
    final codeBackground = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFFF6F8FA);

    return Scrollbar(
      controller: scrollController,
      child: SingleChildScrollView(
        controller: scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 24,
        ),
        child: MarkdownBody(
          key: ValueKey<String>(searchQuery.trim()),
          data: content,
          selectable: true,
          shrinkWrap: true,
          fitContent: false,
          imageDirectory: basePath,
          extensionSet: buildMarkdownExtensionSet(query),
          builders: <String, MarkdownElementBuilder>{
            'codeblock': _CodeBlockBuilder(
              isDark: isDark,
              codeBackground: codeBackground,
              codeForeground: theme.colorScheme.onSurface,
            ),
            'mermaid': _MermaidBlockBuilder(
              isDark: isDark,
              codeBackground: codeBackground,
              codeForeground: theme.colorScheme.onSurface,
              fontScale: fontScale,
            ),
            if (query.isNotEmpty)
              _SearchHighlightSyntax.tag: _SearchHighlightBuilder(
                backgroundColor: matchBackgroundColor,
                activeBackgroundColor: activeMatchBackgroundColor,
                foregroundColor: matchForegroundColor,
                activeMatchIndex: activeMatchIndex,
                scrollController: scrollController,
              ),
          },
          onTapLink: (text, href, title) async {
            if (href == null) return;
            final uri = Uri.tryParse(href);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
          styleSheet: _buildStyleSheet(context, isDark),
        ),
      ),
    );
  }

  MarkdownStyleSheet _buildStyleSheet(BuildContext context, bool isDark) {
    return buildViewerMarkdownStyleSheet(
      Theme.of(context),
      isDark: isDark,
      useBundledFonts: useBundledFonts,
      fontScale: fontScale,
    );
  }
}

/// Splits [text] into styled spans, applying a highlight background/foreground
/// to every case-insensitive occurrence of [query]. Exposed for unit testing.
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

/// Inline syntax that wraps every search match in a [tag] element so it can be
/// rendered with a highlight by [_SearchHighlightBuilder].
class _SearchHighlightSyntax extends md.InlineSyntax {
  _SearchHighlightSyntax(String query)
      : super(RegExp.escape(query), caseSensitive: false);

  static const tag = 'search-highlight';

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text(tag, match[0]!));
    return true;
  }
}

class _MermaidFenceSyntax extends md.BlockSyntax {
  const _MermaidFenceSyntax();

  @override
  RegExp get pattern => const md.FencedCodeBlockSyntax().pattern;

  @override
  bool canParse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content);
    if (match == null) return false;
    final info = (match.namedGroup('backtickInfo') ??
            match.namedGroup('tildeInfo') ??
            '')
        .trim();
    final language = info.split(' ').first;
    return language == 'mermaid';
  }

  @override
  md.Node? parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content);
    if (match == null) return null;

    final marker = match.namedGroup('backtick') ?? match.namedGroup('tilde');
    if (marker == null) return null;

    final indent = match[1]!.length;
    final childLines = const md.FencedCodeBlockSyntax().parseChildLines(
      parser,
      marker,
      indent,
    );

    var text = childLines.map((line) => line!.content).join('\n');
    if (text.isNotEmpty) {
      text = '$text\n';
    }
    final element = md.Element.empty('mermaid');
    element.attributes['content'] = text;
    return element;
  }
}

class _CodeFenceSyntax extends md.BlockSyntax {
  const _CodeFenceSyntax();

  @override
  RegExp get pattern => const md.FencedCodeBlockSyntax().pattern;

  @override
  bool canParse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content);
    if (match == null) return false;
    final info = (match.namedGroup('backtickInfo') ??
            match.namedGroup('tildeInfo') ??
            '')
        .trim();
    final language = info.split(RegExp(r'\s+')).first.toLowerCase();
    return language != 'mermaid';
  }

  @override
  md.Node? parse(md.BlockParser parser) {
    final openingFence = pattern.firstMatch(parser.current.content);
    if (openingFence == null) return null;

    final marker = openingFence.namedGroup('backtick') ??
        openingFence.namedGroup('tilde');
    if (marker == null) return null;

    final indent = openingFence[1]!.length;
    final childLines = const md.FencedCodeBlockSyntax().parseChildLines(
      parser,
      marker,
      indent,
    );

    var text = childLines.map((e) => e!.content).join('\n');
    final element = md.Element.empty('codeblock');
    element.attributes['content'] = text;
    final info = (openingFence.namedGroup('backtickInfo') ??
            openingFence.namedGroup('tildeInfo') ??
            '')
        .trim();
    element.attributes['language'] = _normalizeCodeLanguage(info);
    return element;
  }
}

/// Renders a highlighted search match. The occurrence at [activeMatchIndex]
/// gets [activeBackgroundColor] and is scrolled into view; the rest use
/// [backgroundColor].
class _SearchHighlightBuilder extends MarkdownElementBuilder {
  _SearchHighlightBuilder({
    required this.backgroundColor,
    required this.activeBackgroundColor,
    required this.activeMatchIndex,
    required this.scrollController,
    this.foregroundColor,
  });

  final Color backgroundColor;
  final Color activeBackgroundColor;
  final Color? foregroundColor;
  final int activeMatchIndex;
  final ScrollController scrollController;
  int _matchIndex = 0;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final currentMatchIndex = _matchIndex++;
    final isActive = currentMatchIndex == activeMatchIndex;

    if (isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scrollController.hasClients) return;
        final context = _activeMatchKey.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: 0.2,
          );
        }
      });
    }

    final baseStyle = preferredStyle ?? parentStyle ?? const TextStyle();

    return Text(
      key: isActive ? _activeMatchKey : null,
      element.textContent,
      // copyWith(color: null) keeps the base foreground, so light mode retains
      // the document's own text color while dark mode inverts it.
      style: baseStyle.copyWith(
        backgroundColor: isActive ? activeBackgroundColor : backgroundColor,
        color: foregroundColor,
      ),
    );
  }

  final GlobalKey _activeMatchKey = GlobalKey();
}

/// Renders Mermaid fenced code blocks as diagrams via [MermaidView].
class _MermaidBlockBuilder extends MarkdownElementBuilder {
  _MermaidBlockBuilder({
    required this.isDark,
    required this.codeBackground,
    required this.codeForeground,
    required this.fontScale,
  });

  final bool isDark;
  final Color codeBackground;
  final Color codeForeground;
  final double fontScale;

  @override
  bool isBlockElement() => true;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = decodeHtmlEntities(element.attributes['content'] ?? '')
        .trimRight();
    if (code.isNotEmpty) {
      return MermaidView(
        key: _mermaidViewKey(code, isDark),
        code: code,
        isDark: isDark,
        backgroundColor: codeBackground,
        foregroundColor: codeForeground,
        fontScale: fontScale,
      );
    }
    return const SizedBox.shrink();
  }
}
