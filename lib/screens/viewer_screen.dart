import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:path/path.dart' as p;
import '../widgets/markdown_viewer.dart';
import '../widgets/toc_panel.dart';
import '../models/toc_entry.dart';
import '../services/file_service.dart';

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({
    super.key,
    this.initialFile,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final String? initialFile;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

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
  final _scrollController = ScrollController();
  StreamSubscription<FileSystemEvent>? _fileWatchSub;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    if (widget.initialFile != null) {
      _openFile(widget.initialFile!);
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _fileWatchSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // File handling
  // ---------------------------------------------------------------------------

  Future<void> _pickAndOpenFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'markdown', 'txt'],
      dialogTitle: 'Open Markdown file',
    );
    if (result != null && result.files.single.path != null) {
      await _openFile(result.files.single.path!);
    }
  }

  Future<void> _openFile(String path) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final content = await FileService.readMarkdown(path);
      _watchFile(path);
      setState(() {
        _filePath = path;
        _markdownContent = content;
        _isLoading = false;
        _tocEntries = TocEntry.fromMarkdown(content);
      });
      await windowManager.setTitle('VeloxMD – ${p.basename(path)}');
    } on FileServiceException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
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
      setState(() {
        _markdownContent = content;
        _tocEntries = TocEntry.fromMarkdown(content);
      });
    } catch (_) {
      // Silently ignore reload errors
    }
  }

  // ---------------------------------------------------------------------------
  // Keyboard intents
  // ---------------------------------------------------------------------------

  Map<ShortcutActivator, Intent> get _shortcuts => {
        const SingleActivator(LogicalKeyboardKey.keyO, control: true):
            const _OpenFileIntent(),
        const SingleActivator(LogicalKeyboardKey.keyR, control: true):
            const _ReloadIntent(),
        const SingleActivator(LogicalKeyboardKey.keyT, control: true):
            const _ToggleTocIntent(),
        const SingleActivator(LogicalKeyboardKey.f5): const _ReloadIntent(),
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
            icon: Icon(_tocVisible ? Icons.list_alt : Icons.list),
            tooltip: 'Toggle Table of Contents (Ctrl+T)',
            onPressed: () => setState(() => _tocVisible = !_tocVisible),
          ),
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
            tooltip: 'Reload (Ctrl+R / F5)',
            onPressed: _reloadFile,
          ),
        IconButton(
          icon: const Icon(Icons.folder_open),
          tooltip: 'Open file (Ctrl+O)',
          onPressed: _pickAndOpenFile,
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
        if (_tocVisible && _tocEntries.isNotEmpty)
          TocPanel(
            entries: _tocEntries,
            scrollController: _scrollController,
          ),
        Expanded(
          child: MarkdownViewer(
            content: _markdownContent,
            scrollController: _scrollController,
            basePath: p.dirname(_filePath!),
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
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
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
            'or drop a .md file anywhere\nKeyboard: Ctrl+O',
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
