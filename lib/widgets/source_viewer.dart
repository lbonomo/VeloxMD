import 'package:flutter/material.dart';

/// A scrollable plain text viewer displaying the raw unrendered Markdown source.
///
/// Text is selectable, wraps by default, and respects the user's font scale,
/// margins, and monospace font settings.
class SourceViewer extends StatelessWidget {
  const SourceViewer({
    super.key,
    required this.content,
    required this.scrollController,
    this.codeFontFamily,
    this.horizontalPadding = 32,
    this.fontScale = 1.0,
  });

  final String content;
  final ScrollController scrollController;
  final String? codeFontFamily;
  final double horizontalPadding;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final textStyle = TextStyle(
      fontFamily: codeFontFamily ?? 'monospace',
      fontSize: 14.0 * fontScale,
      height: 1.6,
      color: theme.colorScheme.onSurface,
    );

    return Scrollbar(
      controller: scrollController,
      child: SingleChildScrollView(
        controller: scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 24,
        ),
        child: SizedBox(
          width: double.infinity,
          child: SelectionArea(
            child: Text(
              content,
              style: textStyle,
            ),
          ),
        ),
      ),
    );
  }
}
