import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:markdown/markdown.dart' as md;

/// A scrollable Markdown viewer with syntax-highlighted code blocks,
/// clickable links, and image support relative to [basePath].
class MarkdownViewer extends StatelessWidget {
  const MarkdownViewer({
    super.key,
    required this.content,
    required this.scrollController,
    required this.basePath,
    this.searchQuery = '',
    this.activeMatchIndex = 0,
    this.useGoogleFonts = true,
  });

  final String content;
  final ScrollController scrollController;
  final String basePath;
  final String searchQuery;
  final int activeMatchIndex;
  final bool useGoogleFonts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final query = searchQuery.trim();
    final matchBackgroundColor = isDark
        ? const Color(0xFFFFFF00)
        : const Color(0xFFFFC107);
    final activeMatchBackgroundColor = isDark
        ? const Color(0xFFFFD600)
        : const Color(0xFFFF9800);

    return Scrollbar(
      controller: scrollController,
      child: Markdown(
        key: ValueKey<String>('${searchQuery.trim()}::${activeMatchIndex}'),
        controller: scrollController,
        data: content,
        selectable: true,
        shrinkWrap: false,
        imageDirectory: basePath,
        extensionSet: md.ExtensionSet(
          md.ExtensionSet.gitHubFlavored.blockSyntaxes,
          <md.InlineSyntax>[
            if (query.isNotEmpty) _SearchHighlightSyntax(query),
            md.EmojiSyntax(),
            ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
          ],
        ),
        builders: <String, MarkdownElementBuilder>{
          if (query.isNotEmpty)
            _SearchHighlightSyntax.tag: _SearchHighlightBuilder(
              backgroundColor: matchBackgroundColor,
              activeBackgroundColor: activeMatchBackgroundColor,
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
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      ),
    );
  }

  MarkdownStyleSheet _buildStyleSheet(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final codeFont = useGoogleFonts
        ? GoogleFonts.firaCode(fontSize: 13.5)
        : const TextStyle(fontFamily: 'monospace', fontSize: 13.5);
    final bodyFont = useGoogleFonts ? GoogleFonts.inter() : const TextStyle();

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

class _SearchHighlightBuilder extends MarkdownElementBuilder {
  _SearchHighlightBuilder({
    required this.backgroundColor,
    required this.activeBackgroundColor,
    required this.activeMatchIndex,
    required this.scrollController,
  });

  final Color backgroundColor;
  final Color activeBackgroundColor;
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
      style: baseStyle?.copyWith(
        backgroundColor: isActive ? activeBackgroundColor : backgroundColor,
      ),
    );
  }

  final GlobalKey _activeMatchKey = GlobalKey();
}
