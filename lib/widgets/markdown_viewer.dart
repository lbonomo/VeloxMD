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
  });

  final String content;
  final ScrollController scrollController;
  final String basePath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scrollbar(
      controller: scrollController,
      child: Markdown(
        controller: scrollController,
        data: content,
        selectable: true,
        shrinkWrap: false,
        imageDirectory: basePath,
        extensionSet: md.ExtensionSet(
          md.ExtensionSet.gitHubFlavored.blockSyntaxes,
          <md.InlineSyntax>[
            md.EmojiSyntax(),
            ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
          ],
        ),
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
