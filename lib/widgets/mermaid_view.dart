import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, LogicalKeyboardKey;
import 'package:webview_cef/webview_cef.dart';

/// Decodes the HTML entities that the Markdown parser injects into fenced
/// code content (e.g. `--&gt;` back to `-->`). Mermaid needs the raw source,
/// so this must run before handing a diagram to the renderer.
String decodeHtmlEntities(String input) {
  return input
      .replaceAllMapped(
        RegExp(r'&#x([0-9a-fA-F]+);'),
        (m) => String.fromCharCode(int.parse(m[1]!, radix: 16)),
      )
      .replaceAllMapped(
        RegExp(r'&#(\d+);'),
        (m) => String.fromCharCode(int.parse(m[1]!)),
      )
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');
}

/// Shared runtime that initialises CEF once and materialises the bundled
/// `mermaid.min.js` plus a per-diagram HTML document into a temporary
/// directory so the diagrams render fully offline.
class MermaidRuntime {
  MermaidRuntime._();

  static Future<void>? _initFuture;
  static Future<Directory>? _dirFuture;

  /// Initialises the CEF manager exactly once for the whole app.
  static Future<void> ensureInitialized() {
    return _initFuture ??= WebviewManager().initialize();
  }

  static Future<Directory> _workDir() {
    return _dirFuture ??= _prepareWorkDir();
  }

  static Future<Directory> _prepareWorkDir() async {
    final dir = Directory('${Directory.systemTemp.path}/veloxmd_mermaid');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    // Extract the bundled mermaid runtime once.
    final jsFile = File('${dir.path}/mermaid.min.js');
    if (!await jsFile.exists()) {
      final data = await rootBundle.load('assets/mermaid.min.js');
      await jsFile.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    }
    return dir;
  }

  /// Writes an HTML document that renders [code] with the given [theme]
  /// (`dark` or `default`) and returns a `file://` URL to load.
  ///
  /// When [fitViewport] is true the document fills the window, fits the
  /// diagram initially, and supports mouse-wheel zoom and drag-to-pan.
  static Future<String> buildDocument({
    required String code,
    required String theme,
    required String backgroundHex,
    required String foregroundHex,
    bool fitViewport = false,
  }) async {
    final dir = await _workDir();
    final html = buildHtml(
      code: code,
      theme: theme,
      backgroundHex: backgroundHex,
      foregroundHex: foregroundHex,
      fitViewport: fitViewport,
    );
    final key = '$code::$theme::$backgroundHex::$foregroundHex::$fitViewport';
    final name = 'd_${key.hashCode.toUnsigned(32).toRadixString(16)}.html';
    final file = File('${dir.path}/$name');
    await file.writeAsString(html);
    return Uri.file(file.path).toString();
  }

  /// Builds the HTML document string for a diagram. Pure (no I/O) so it can be
  /// unit-tested. When [fitViewport] is false the inline layout auto-sizes to
  /// the diagram's full height with the page scroll disabled (no scrollbar);
  /// when true it is the full-screen zoom/pan layout.
  static String buildHtml({
    required String code,
    required String theme,
    required String backgroundHex,
    required String foregroundHex,
    bool fitViewport = false,
  }) {
    final codeJson = jsonEncode(code);
    final themeJson = jsonEncode(theme);
    final head = '''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="color-scheme" content="dark light">
<style>
  html, body { margin: 0; padding: 0; overflow: hidden; background: $backgroundHex; color: $foregroundHex; }
  #err { padding: 12px; color: #d63200; font-family: monospace; white-space: pre-wrap; font-size: 13px; }''';

    final html = fitViewport
        ? '''$head
  #stage { position: fixed; inset: 0; overflow: hidden; cursor: grab; }
  #c { position: absolute; left: 0; top: 0; transform-origin: 0 0; }
</style>
<script src="mermaid.min.js"></script>
</head>
<body>
<div id="stage"><div id="c"></div></div>
<script>
  window.__mermaidError = "";
  var scale = 1, tx = 0, ty = 0;
  function apply() {
    document.getElementById('c').style.transform =
      'translate(' + tx + 'px,' + ty + 'px) scale(' + scale + ')';
  }
  function fit() {
    var c = document.getElementById('c');
    var svg = c.querySelector('svg');
    if (!svg) return;
    // Intrinsic diagram size. getBoundingClientRect is unreliable for mermaid
    // (e.g. sequence diagrams leave the <svg> without an explicit width/height
    // once the inline max-width is cleared), so read the viewBox first and fall
    // back to getBBox, then to the bounding rect.
    var nw = 0, nh = 0;
    if (svg.viewBox && svg.viewBox.baseVal && svg.viewBox.baseVal.width) {
      nw = svg.viewBox.baseVal.width;
      nh = svg.viewBox.baseVal.height;
    }
    if (!nw || !nh) {
      try { var b = svg.getBBox(); nw = b.width; nh = b.height; } catch (e) {}
    }
    if (!nw || !nh) {
      var r = svg.getBoundingClientRect();
      nw = r.width; nh = r.height;
    }
    // Pin the <svg> to its intrinsic pixel size so the CSS transform scales
    // predictably (no dependence on the SVG's fuzzy auto width/height).
    svg.style.maxWidth = 'none';
    svg.style.maxHeight = 'none';
    svg.setAttribute('width', nw);
    svg.setAttribute('height', nh);
    svg.style.width = nw + 'px';
    svg.style.height = nh + 'px';
    var vw = window.innerWidth, vh = window.innerHeight, pad = 32;
    // Scale to fill the visible area (no 1x cap): a diagram smaller than the
    // window is enlarged, a larger one is shrunk, always preserving aspect
    // ratio so it occupies as much of the viewport as possible.
    scale = Math.min((vw - pad) / nw, (vh - pad) / nh);
    if (!isFinite(scale) || scale <= 0) scale = 1;
    // Center horizontally and vertically within the viewport.
    tx = (vw - nw * scale) / 2;
    ty = (vh - nh * scale) / 2;
    apply();
  }
  function showError(msg) {
    window.__mermaidError = String(msg);
    var d = document.createElement('div');
    d.id = 'err';
    d.textContent = window.__mermaidError;
    document.body.appendChild(d);
  }
  var stage = document.getElementById('stage');
  stage.addEventListener('wheel', function (e) {
    e.preventDefault();
    var f = e.deltaY < 0 ? 1.1 : 0.9;
    var ns = Math.min(16, Math.max(0.05, scale * f));
    tx = e.clientX - (e.clientX - tx) * (ns / scale);
    ty = e.clientY - (e.clientY - ty) * (ns / scale);
    scale = ns;
    apply();
  }, { passive: false });
  var panning = false, psx = 0, psy = 0;
  stage.addEventListener('mousedown', function (e) {
    panning = true; psx = e.clientX - tx; psy = e.clientY - ty;
    stage.style.cursor = 'grabbing';
  });
  window.addEventListener('mousemove', function (e) {
    if (panning) { tx = e.clientX - psx; ty = e.clientY - psy; apply(); }
  });
  window.addEventListener('mouseup', function () {
    panning = false; stage.style.cursor = 'grab';
  });
  stage.addEventListener('dblclick', function () { fit(); });
  window.addEventListener('resize', function () { fit(); });
  try {
    mermaid.initialize({ startOnLoad: false, theme: $themeJson, securityLevel: 'strict' });
    mermaid.render('vmd', $codeJson).then(function (res) {
      document.getElementById('c').innerHTML = res.svg;
      requestAnimationFrame(function () { requestAnimationFrame(fit); });
    }).catch(function (e) {
      showError(e && e.message ? e.message : e);
    });
  } catch (e) {
    showError(e);
  }
</script>
</body>
</html>'''
        : '''$head
  /* Block (not flex) layout so the replaced <svg> keeps its intrinsic aspect
     ratio when width is capped -- inside a flex row it would keep its full
     intrinsic height and overflow, forcing a scrollbar. */
  #c { padding: 12px; text-align: center; }
  /* Mermaid emits an inline max-width on the <svg>; override it so wide
     diagrams scale down to fit the view instead of being clipped. */
  #c svg { display: inline-block; max-width: 100% !important; height: auto !important; }
</style>
<script src="mermaid.min.js"></script>
</head>
<body>
<div id="c"></div>
<script>
  window.__mermaidHeight = 0;
  window.__mermaidError = "";
  // Recomputes the content height on every call and returns it, or 0 while the
  // diagram has not rendered yet. mermaid.render() is async and finishes AFTER
  // the page's load event, so before it completes the body is effectively
  // empty (~24px). Returning 0 in that window tells the Dart poller "not ready
  // yet" so it keeps waiting instead of locking onto that tiny pre-render size
  // (which left the box at the minimum height and made the diagram scroll).
  function report() {
    var svg = document.querySelector('#c svg');
    var err = document.getElementById('err');
    var el = svg || err;
    if (!el) { window.__mermaidHeight = 0; return 0; }
    var r = el.getBoundingClientRect();
    var elBottom = r.top + r.height;
    var h = Math.ceil(Math.max(
      document.body.scrollHeight,
      document.documentElement.scrollHeight,
      elBottom + 12
    ));
    window.__mermaidHeight = h > 0 ? h : 1;
    return window.__mermaidHeight;
  }
  // Re-measure whenever the view is resized to the final display width.
  window.addEventListener('resize', report);
  function showError(msg) {
    window.__mermaidError = String(msg);
    var d = document.createElement('div');
    d.id = 'err';
    d.textContent = window.__mermaidError;
    document.body.appendChild(d);
    requestAnimationFrame(report);
  }
  try {
    mermaid.initialize({ startOnLoad: false, theme: $themeJson, securityLevel: 'strict' });
    mermaid.render('vmd', $codeJson).then(function (res) {
      document.getElementById('c').innerHTML = res.svg;
      requestAnimationFrame(function () { requestAnimationFrame(report); });
    }).catch(function (e) {
      showError(e && e.message ? e.message : e);
    });
  } catch (e) {
    showError(e);
  }
</script>
</body>
</html>''';

    return html;
  }
}

/// Renders a single Mermaid diagram inside an off-screen Chromium view.
///
/// The diagram height is measured after render and the view resizes to fit.
/// If CEF cannot be initialised the widget degrades gracefully to showing the
/// raw diagram source.
class MermaidView extends StatefulWidget {
  const MermaidView({
    super.key,
    required this.code,
    required this.isDark,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String code;
  final bool isDark;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  State<MermaidView> createState() => _MermaidViewState();
}

class _MermaidViewState extends State<MermaidView> {
  // Initial height and lower bound for the view. The measured diagram height
  // grows the box above this; it never shrinks below it. Kept at 500 (not a
  // tight 140) as a safety net so that even if height measurement fails the
  // diagram still gets a usable, mostly-scroll-free box.
  static const double _initialHeight = 500;

  late final WebViewController _controller;
  double _height = _initialHeight;
  bool _failed = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebviewManager().createWebView(
      // NOTE: webview_cef 0.5.1 stores this in a non-nullable map even though
      // the parameter is nullable, so passing null crashes in createWebView.
      // An empty InjectUserScripts avoids the bad assignment.
      injectUserScripts: InjectUserScripts(),
      loading: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
    _setup();
  }

  Future<void> _setup() async {
    try {
      await MermaidRuntime.ensureInitialized();
      final url = await MermaidRuntime.buildDocument(
        code: widget.code,
        theme: widget.isDark ? 'dark' : 'default',
        backgroundHex: _hex(widget.backgroundColor),
        foregroundHex: _hex(widget.foregroundColor),
      );
      _controller.setWebviewListener(
        WebviewEventsListener(onLoadEnd: (_, __) => _pollHeight()),
      );
      await _controller.initialize(url);
    } catch (e) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _pollHeight() async {
    var lastValue = 0.0;
    var stableCount = 0;
    for (var i = 0; i < 100 && !_disposed; i++) {
      try {
        // Recompute the height live each poll: report() re-measures against
        // the current (final) layout, so a diagram whose first measurement
        // landed too early is not frozen at a too-small, overflowing size.
        final raw = await _controller.evaluateJavascript(
          'typeof report === "function" ? report() : window.__mermaidHeight',
        );
        final value = double.tryParse(
          (raw ?? '').replaceAll('"', '').trim(),
        );
        if (value != null && value > 1) {
          // No upper bound: the diagram takes whatever height it needs.
          final target = value < _initialHeight ? _initialHeight : value;
          if (mounted && (target - _height).abs() > 0.5) {
            setState(() => _height = target + 2);
          }
          // Stop once the measurement holds steady across a few reads, so
          // late layout/font settling can still grow the view.
          if ((value - lastValue).abs() <= 0.5) {
            if (++stableCount >= 3) return;
          } else {
            stableCount = 0;
            lastValue = value;
          }
        }
      } catch (_) {
        // View not ready yet; keep polling.
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  static String _hex(Color c) {
    final value = c.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0')}';
  }

  void _openFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => MermaidFullScreenPage(
          code: widget.code,
          isDark: widget.isDark,
          backgroundColor: widget.backgroundColor,
          foregroundColor: widget.foregroundColor,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return _RawFallback(
        code: widget.code,
        foregroundColor: widget.foregroundColor,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth.isFinite ? constraints.maxWidth : null,
          height: _height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: _controller,
                builder: (_, ready, __) => ready
                    ? _controller.webviewWidget
                    : _controller.loadingWidget,
              ),
              // The webview consumes pointer events, so a transparent overlay
              // on top captures the tap to open the full-screen view.
              Positioned.fill(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _openFullscreen,
                    child: const Tooltip(
                      message: 'Click to view full screen',
                      child: SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Full-screen view of a single Mermaid diagram, scaled to fit the window.
class MermaidFullScreenPage extends StatefulWidget {
  const MermaidFullScreenPage({
    super.key,
    required this.code,
    required this.isDark,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String code;
  final bool isDark;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  State<MermaidFullScreenPage> createState() => _MermaidFullScreenPageState();
}

class _MermaidFullScreenPageState extends State<MermaidFullScreenPage> {
  late final WebViewController _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebviewManager().createWebView(
      injectUserScripts: InjectUserScripts(),
      loading: const Center(child: CircularProgressIndicator()),
    );
    _setup();
  }

  Future<void> _setup() async {
    try {
      await MermaidRuntime.ensureInitialized();
      final url = await MermaidRuntime.buildDocument(
        code: widget.code,
        theme: widget.isDark ? 'dark' : 'default',
        backgroundHex: _MermaidViewState._hex(widget.backgroundColor),
        foregroundHex: _MermaidViewState._hex(widget.foregroundColor),
        fitViewport: true,
      );
      await _controller.initialize(url);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: widget.backgroundColor,
          body: Stack(
            children: [
              Positioned.fill(
                child: _failed
                    ? _RawFallback(
                        code: widget.code,
                        foregroundColor: widget.foregroundColor,
                      )
                    : ValueListenableBuilder<bool>(
                        valueListenable: _controller,
                        builder: (_, ready, __) => ready
                            ? _controller.webviewWidget
                            : _controller.loadingWidget,
                      ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black.withOpacity(0.45),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Close (Esc)',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when CEF is unavailable: keeps the diagram source visible.
class _RawFallback extends StatelessWidget {
  const _RawFallback({required this.code, required this.foregroundColor});

  final String code;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree_outlined,
                  size: 16, color: foregroundColor.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text(
                'mermaid',
                style: TextStyle(
                  fontSize: 12,
                  color: foregroundColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            code,
            style: const TextStyle(fontFamily: 'FiraCode', fontSize: 13.5)
                .copyWith(color: foregroundColor),
          ),
        ],
      ),
    );
  }
}
