import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import '../widgets/markdown_viewer.dart';
import '../widgets/search_panel.dart';
import '../widgets/toc_panel.dart';
import '../widgets/document_footer.dart';
import '../dialogs/about_dialog.dart';
import '../models/toc_entry.dart';
import '../models/document_stats.dart';
import '../services/file_service.dart';
import '../services/keybindings_service.dart';

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({
    super.key,
    this.initialFile,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.keybindings,
  });

  final String? initialFile;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final KeybindingsService keybindings;

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> with WindowListener {
  String? _filePath;
  String _markdownContent = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _tocVisible = false;
  List<TocEntry> _tocEntries = [];
  DocumentStats _stats = DocumentStats.fromMarkdown('');
  final String _version = VeloxAboutDialog.version;
  double _horizontalMargin = 32;
  static const double _minMargin = 0;
  static const double _maxMargin = 320;
  double _fontScale = 1.0;
  static const double _minFontScale = 0.5;
  static const double _maxFontScale = 3.0;
  static const double _fontScaleStep = 0.1;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  int _activeMatchIndex = 0;
  int _matchCount = 0;
  StreamSubscription<FileSystemEvent>? _fileWatchSub;
  bool _isPickerOpen = false;

  /// Debounced search query actually applied to the rendered view and the match
  /// count. Typing updates the text field immediately, but re-parsing/rendering
  /// the whole document is deferred until the user pauses, avoiding a full
  /// re-parse on every keystroke on large documents.
  String _searchQuery = '';
  bool _searchVisible = false;
  Timer? _searchDebounce;
  static const Duration _searchDebounceDelay = Duration(milliseconds: 180);

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _loadMarginPreference();
    _loadFontScalePreference();
    if (widget.initialFile != null) {
      _openFile(widget.initialFile!);
    }
  }

  Future<void> _loadMarginPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getDouble('horizontal_margin');
    if (value != null && mounted) {
      setState(() => _horizontalMargin = value.clamp(_minMargin, _maxMargin));
    }
  }

  Future<void> _setHorizontalMargin(double value) async {
    final clamped = value.clamp(_minMargin, _maxMargin).toDouble();
    setState(() => _horizontalMargin = clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('horizontal_margin', clamped);
  }

  Future<void> _loadFontScalePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getDouble('font_scale');
    if (value != null && mounted) {
      setState(
        () => _fontScale = value.clamp(_minFontScale, _maxFontScale).toDouble(),
      );
    }
  }

  Future<void> _setFontScale(double value) async {
    final clamped = value.clamp(_minFontScale, _maxFontScale).toDouble();
    setState(() => _fontScale = clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_scale', clamped);
  }

  Future<void> _changeFontScale(double delta) =>
      _setFontScale(_fontScale + delta);

  @override
  void dispose() {
    windowManager.removeListener(this);
    _fileWatchSub?.cancel();
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // File handling
  // ---------------------------------------------------------------------------

  Future<void> _pickAndOpenFile() async {
    // Prevent multiple file picker dialogs from stacking when the button is
    // clicked repeatedly or the Ctrl+O shortcut fires while one is already open.
    if (_isPickerOpen) return;
    _isPickerOpen = true;
    // On Linux, some native choosers can still appear behind an always-on-top
    // app window. Temporarily dropping always-on-top and minimizing the app
    // guarantees the chooser is visible, then we restore the window state.
    final bool wasAlwaysOnTop = await windowManager.isAlwaysOnTop();
    var minimizedForPicker = false;
    if (wasAlwaysOnTop) {
      await windowManager.setAlwaysOnTop(false);
      if (Platform.isLinux) {
        await windowManager.minimize();
        minimizedForPicker = true;
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'markdown', 'mdc', 'txt'],
        dialogTitle: 'Open Markdown file',
        lockParentWindow: true,
      );
      if (result != null && result.files.single.path != null) {
        await _openFile(result.files.single.path!);
      }
    } finally {
      if (minimizedForPicker) {
        await windowManager.restore();
        await windowManager.focus();
      }
      if (wasAlwaysOnTop) {
        await windowManager.setAlwaysOnTop(true);
      }
      _isPickerOpen = false;
    }
  }

  Future<void> _openFile(String path) async {
    // Different document: drop cached diagram keys from the previous file so
    // stale GlobalKeys do not accumulate across opens.
    if (path != _filePath) {
      clearMermaidViewKeyCache();
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final content = await FileService.readMarkdown(path);
      _watchFile(path);

      final statsFuture = content.length > 20000
          ? Isolate.run(() => DocumentStats.fromMarkdown(content))
          : Future.value(DocumentStats.fromMarkdown(content));
      final tocFuture = content.length > 20000
          ? Isolate.run(() => TocEntry.fromMarkdown(content))
          : Future.value(TocEntry.fromMarkdown(content));

      final stats = await statsFuture;
      final tocEntries = await tocFuture;

      if (!mounted) return;

      setState(() {
        _filePath = path;
        _markdownContent = content;
        _stats = stats;
        _isLoading = false;
        _tocEntries = tocEntries;
        _recomputeMatchCount();
      });
      await windowManager.setTitle(p.basename(path));
    } on FileServiceException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    }
  }

  void _watchFile(String path) {
    _fileWatchSub?.cancel();
    _fileWatchSub = File(path)
        .watch(events: FileSystemEvent.modify)
        .listen((_) => _reloadFile());
  }

  Future<void> _reloadFile() async {
    if (_filePath == null) return;
    try {
      final content = await FileService.readMarkdown(_filePath!);
      final statsFuture = content.length > 20000
          ? Isolate.run(() => DocumentStats.fromMarkdown(content))
          : Future.value(DocumentStats.fromMarkdown(content));
      final tocFuture = content.length > 20000
          ? Isolate.run(() => TocEntry.fromMarkdown(content))
          : Future.value(TocEntry.fromMarkdown(content));

      final stats = await statsFuture;
      final tocEntries = await tocFuture;

      if (!mounted) return;

      setState(() {
        _markdownContent = content;
        _stats = stats;
        _tocEntries = tocEntries;
        _recomputeMatchCount();
      });
    } catch (_) {
      // Silently ignore reload errors
    }
  }

  // ---------------------------------------------------------------------------
  // Search navigation
  // ---------------------------------------------------------------------------

  /// Called when the query text changes. Debounced: re-parsing the document to
  /// count matches and rebuilding the rendered view is deferred until the user
  /// pauses typing, so fast typing does not trigger a full re-parse per
  /// keystroke. Resets the active occurrence to the first match.
  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDelay, () {
      if (!mounted) return;
      _commitSearchQuery(query);
    });
  }

  void _commitSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
      _matchCount = countHighlightMatches(_markdownContent, query);
      _activeMatchIndex = 0;
    });
  }

  void _flushPendingSearchQuery() {
    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce!.cancel();
    }
    _commitSearchQuery(_searchController.text);
  }

  /// Recomputes the match count for the current query against the current
  /// document and clamps the active index into range. Call after the document
  /// content changes (open/reload) so the counter stays accurate.
  void _recomputeMatchCount() {
    final count = countHighlightMatches(_markdownContent, _searchQuery);
    _matchCount = count;
    if (count == 0) {
      _activeMatchIndex = 0;
    } else if (_activeMatchIndex >= count) {
      _activeMatchIndex = count - 1;
    }
  }

  /// Advances the focused highlight to the next match, wrapping around to the
  /// first after the last. Invoked when the user presses Enter in the search
  /// field. Focus stays in the field so repeated Enter keeps jumping.
  void _goToNextMatch() {
    _flushPendingSearchQuery();
    if (_matchCount == 0) return;
    setState(() {
      _activeMatchIndex = (_activeMatchIndex + 1) % _matchCount;
    });
    _searchFocusNode.requestFocus();
  }

  void _goToPreviousMatch() {
    _flushPendingSearchQuery();
    if (_matchCount == 0) return;
    setState(() {
      _activeMatchIndex = (_activeMatchIndex - 1 + _matchCount) % _matchCount;
    });
    _searchFocusNode.requestFocus();
  }

  void _clearSearch() {
    _searchController.clear();
    _searchDebounce?.cancel();
    setState(() {
      _searchQuery = '';
      _activeMatchIndex = 0;
      _matchCount = 0;
    });
    _searchFocusNode.requestFocus();
  }

  void _showSearchPanel() {
    if (_filePath == null) return;
    if (!_searchVisible) {
      setState(() => _searchVisible = true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _toggleSearchPanel() {
    if (_filePath == null) return;
    if (_searchVisible) {
      setState(() => _searchVisible = false);
      _searchFocusNode.unfocus();
    } else {
      _showSearchPanel();
    }
  }

  // ---------------------------------------------------------------------------
  // Keyboard intents
  // ---------------------------------------------------------------------------

  Map<ShortcutActivator, Intent> get _shortcuts => {
        for (final a in widget.keybindings[KeyAction.openFile])
          a: const _OpenFileIntent(),
        for (final a in widget.keybindings[KeyAction.reload])
          a: const _ReloadIntent(),
        for (final a in widget.keybindings[KeyAction.toggleToc])
          a: const _ToggleTocIntent(),
        for (final a in widget.keybindings[KeyAction.focusSearch])
          a: const _FocusSearchIntent(),
        for (final a in widget.keybindings[KeyAction.increaseFontSize])
          a: const _IncreaseFontSizeIntent(),
        for (final a in widget.keybindings[KeyAction.decreaseFontSize])
          a: const _DecreaseFontSizeIntent(),
        for (final a in widget.keybindings[KeyAction.resetFontSize])
          a: const _ResetFontSizeIntent(),
      };

  Map<Type, Action<Intent>> get _actions => {
        _OpenFileIntent: CallbackAction<_OpenFileIntent>(
          onInvoke: (_) => _pickAndOpenFile(),
        ),
        _ReloadIntent: CallbackAction<_ReloadIntent>(
          onInvoke: (_) => _reloadFile(),
        ),
        _ToggleTocIntent: CallbackAction<_ToggleTocIntent>(
          onInvoke: (_) => setState(() => _tocVisible = !_tocVisible),
        ),
        _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(
          onInvoke: (_) {
            _showSearchPanel();
            return null;
          },
        ),
        _IncreaseFontSizeIntent: CallbackAction<_IncreaseFontSizeIntent>(
          onInvoke: (_) => _changeFontScale(_fontScaleStep),
        ),
        _DecreaseFontSizeIntent: CallbackAction<_DecreaseFontSizeIntent>(
          onInvoke: (_) => _changeFontScale(-_fontScaleStep),
        ),
        _ResetFontSizeIntent: CallbackAction<_ResetFontSizeIntent>(
          onInvoke: (_) => _setFontScale(1.0),
        ),
      };

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: _actions,
        child: Focus(
          autofocus: true,
          child: DropTarget(
            onDragDone: (details) {
              final file = details.files.firstOrNull;
              if (file != null) _openFile(file.path);
            },
            child: Scaffold(
              appBar: _buildAppBar(context),
              body: _buildBody(context),
              bottomNavigationBar: _filePath != null
                  ? DocumentFooter(stats: _stats, version: _version)
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      title: Text(
        _filePath != null ? p.basename(_filePath!) : 'VeloxMD',
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        if (_filePath != null)
          IconButton(
            icon: Icon(_searchVisible ? Icons.search_off : Icons.search),
            tooltip: _searchVisible
                ? 'Hide search panel'
                : 'Show search panel (Ctrl+F)',
            onPressed: _toggleSearchPanel,
          ),
        if (_filePath != null)
          IconButton(
            icon: Icon(_tocVisible ? Icons.list_alt : Icons.list),
            tooltip:
                'Toggle Table of Contents (${widget.keybindings.label(KeyAction.toggleToc)})',
            onPressed: () => setState(() => _tocVisible = !_tocVisible),
          ),
        if (_filePath != null) _buildMarginControl(context),
        IconButton(
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          tooltip: 'Toggle theme',
          onPressed: () => widget.onThemeModeChanged(
            isDark ? ThemeMode.light : ThemeMode.dark,
          ),
        ),
        if (_filePath != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip:
                'Reload (${widget.keybindings.labels(KeyAction.reload).join(' / ')})',
            onPressed: _reloadFile,
          ),
        IconButton(
          icon: const Icon(Icons.folder_open),
          tooltip:
              'Open file (${widget.keybindings.label(KeyAction.openFile)})',
          onPressed: _pickAndOpenFile,
        ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: 'About VeloxMD',
          onPressed: () => showDialog(
            context: context,
            builder: (context) => const VeloxAboutDialog(),
          ),
        ),
      ],
    );
  }

  Widget _buildMarginControl(BuildContext context) {
    return PopupMenuButton<void>(
      tooltip: 'Text margins',
      icon: const Icon(Icons.format_indent_increase),
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          enabled: false,
          child: StatefulBuilder(
            builder: (context, setInner) {
              void update(double value) {
                setInner(() {});
                _setHorizontalMargin(value);
              }

              return SizedBox(
                width: 260,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Text margins'),
                        Text('${_horizontalMargin.round()} px'),
                      ],
                    ),
                    Slider(
                      min: _minMargin,
                      max: _maxMargin,
                      divisions: ((_maxMargin - _minMargin) / 8).round(),
                      value: _horizontalMargin,
                      label: '${_horizontalMargin.round()} px',
                      onChanged: update,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => update(32),
                        icon: const Icon(Icons.restart_alt, size: 18),
                        label: const Text('Reset'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _pickAndOpenFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Open another file'),
            ),
          ],
        ),
      );
    }

    if (_filePath == null) {
      return _buildWelcome(context);
    }

    return Row(
      children: [
        if (_tocVisible)
          TocPanel(
            entries: _tocEntries,
            scrollController: _scrollController,
          ),
        if (_searchVisible && _filePath != null)
          SearchPanel(
            controller: _searchController,
            focusNode: _searchFocusNode,
            matchCount: _matchCount,
            activeMatchIndex: _activeMatchIndex,
            onChanged: _onSearchChanged,
            onNext: _goToNextMatch,
            onPrevious: _goToPreviousMatch,
            onClear: _clearSearch,
          ),
        Expanded(
          child: MarkdownViewer(
            content: _markdownContent,
            scrollController: _scrollController,
            basePath: p.dirname(_filePath!),
            searchQuery: _searchQuery,
            activeMatchIndex: _activeMatchIndex,
            horizontalPadding: _horizontalMargin,
            fontScale: _fontScale,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcome(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.6),
          ),
          const SizedBox(height: 24),
          Text(
            'VeloxMD',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fast Markdown viewer for Linux',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _pickAndOpenFile,
            icon: const Icon(Icons.folder_open),
            label: const Text('Open Markdown file'),
          ),
          const SizedBox(height: 12),
          Text(
            'or drop a .md / .mdc file anywhere\n'
            'Keyboard: ${widget.keybindings.label(KeyAction.openFile)}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// Intent classes
class _OpenFileIntent extends Intent {
  const _OpenFileIntent();
}

class _ReloadIntent extends Intent {
  const _ReloadIntent();
}

class _ToggleTocIntent extends Intent {
  const _ToggleTocIntent();
}

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class _IncreaseFontSizeIntent extends Intent {
  const _IncreaseFontSizeIntent();
}

class _DecreaseFontSizeIntent extends Intent {
  const _DecreaseFontSizeIntent();
}

class _ResetFontSizeIntent extends Intent {
  const _ResetFontSizeIntent();
}
