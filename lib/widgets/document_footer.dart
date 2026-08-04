import 'package:flutter/material.dart';
import '../models/document_stats.dart';

class DocumentFooter extends StatelessWidget {
  const DocumentFooter({
    super.key,
    required this.stats,
    required this.version,
  });

  final DocumentStats stats;
  final String version;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
        color: isDark
            ? theme.colorScheme.surface.withOpacity(0.5)
            : theme.colorScheme.surface,
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _StatItem(
                  icon: Icons.text_fields,
                  label: 'Words',
                  value: stats.words.toString(),
                  theme: theme,
                ),
                _StatItem(
                  icon: Icons.subject,
                  label: 'Lines',
                  value: stats.lines.toString(),
                  theme: theme,
                ),
                _StatItem(
                  icon: Icons.abc,
                  label: 'Characters',
                  value: stats.characters.toString(),
                  theme: theme,
                ),
                _StatItem(
                  icon: Icons.title,
                  label: 'Headings',
                  value: stats.headings.toString(),
                  theme: theme,
                ),
                _StatItem(
                  icon: Icons.link,
                  label: 'Links',
                  value: stats.links.toString(),
                  theme: theme,
                ),
                _StatItem(
                  icon: Icons.code,
                  label: 'Code blocks',
                  value: stats.codeBlocks.toString(),
                  theme: theme,
                ),
                _StatItem(
                  icon: Icons.token,
                  label: 'Tokens',
                  value: stats.tokens.toString(),
                  theme: theme,
                  highlight: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Container(
              height: 24,
              width: 1,
              color: theme.dividerColor,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'VeloxMD v$version',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.textTheme.labelSmall?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: highlight
              ? theme.colorScheme.primary
              : theme.textTheme.labelSmall?.color?.withOpacity(0.7),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: theme.textTheme.labelSmall?.copyWith(
            color: highlight
                ? theme.colorScheme.primary
                : theme.textTheme.labelSmall?.color?.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: highlight ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}
