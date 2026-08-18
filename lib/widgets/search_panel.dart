import 'package:flutter/material.dart';

/// A side panel for document search controls.
class SearchPanel extends StatelessWidget {
  const SearchPanel({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.matchCount,
    required this.activeMatchIndex,
    required this.onChanged,
    required this.onNext,
    required this.onPrevious,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int matchCount;
  final int activeMatchIndex;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 1,
      child: SizedBox(
        width: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Search',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (context, value, _) {
                        final hasQuery = value.text.trim().isNotEmpty;
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onChanged: onChanged,
                          onSubmitted: (_) => onNext(),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Search in rendered text',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: hasQuery
                                ? IconButton(
                                    tooltip: 'Clear search',
                                    icon: const Icon(Icons.clear),
                                    onPressed: onClear,
                                  )
                                : null,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      matchCount == 0
                          ? 'No results'
                          : '${activeMatchIndex + 1}/$matchCount matches',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: matchCount == 0 ? null : onPrevious,
                            icon: const Icon(Icons.keyboard_arrow_up),
                            label: const Text('Previous'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: matchCount == 0 ? null : onNext,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            label: const Text('Next'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Press Enter to jump to the next match.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
