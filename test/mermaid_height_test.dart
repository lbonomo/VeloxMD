import 'package:flutter_test/flutter_test.dart';
import 'package:veloxmd/widgets/mermaid_view.dart';

/// Regression tests for the mermaid diagram height / scroll behaviour.
///
/// The diagram container must occupy the full height the diagram needs, with
/// no internal scrollbar and no upper height cap. These assert the contract of
/// the generated HTML (which drives the CEF webview) so the "diagram is clipped
/// with a scrollbar" bug cannot silently return. CEF itself cannot run in a
/// unit test, so we verify the document that CEF is asked to render.
void main() {
  const code = 'graph LR; A-->B; B-->C; C-->D;';

  String inlineHtml() => MermaidRuntime.buildHtml(
        code: code,
        theme: 'default',
        backgroundHex: '#ffffff',
        foregroundHex: '#000000',
      );

  group('inline (non-fullscreen) mermaid document', () {
    test('never caps the diagram height', () {
      final html = inlineHtml();
      // A max-height on the container/svg is exactly the regression we forbid:
      // the diagram must grow to whatever height it needs.
      expect(
        html.contains('max-height'),
        isFalse,
        reason: 'inline document must not cap diagram height with max-height',
      );
    });

    test('lets the svg auto-size its height (no fixed height)', () {
      expect(inlineHtml(), contains('height: auto !important'));
    });

    test('scales wide diagrams down to fit width', () {
      expect(inlineHtml(), contains('max-width: 100% !important'));
    });

    test('disables the page scrollbar so no internal scroll shows', () {
      expect(inlineHtml(), contains('overflow: hidden'));
    });

    test('uses block (not flex) layout so the svg keeps its aspect ratio', () {
      final html = inlineHtml();
      expect(html, isNot(contains('display: flex')));
      expect(html, contains('#c { padding: 12px; text-align: center; }'));
    });

    test('exposes a report() that returns the recomputed height live', () {
      final html = inlineHtml();
      // report() must return the value (polled live from Dart) and re-run on
      // resize -- otherwise a too-early measurement freezes an undersized box.
      expect(html, contains('return window.__mermaidHeight;'));
      expect(html, contains("addEventListener('resize', report)"));
    });

    test('report() returns 0 until the diagram has actually rendered', () {
      final html = inlineHtml();
      // mermaid.render() finishes after page load; report() must signal
      // "not ready" (0) until an svg/error element exists so the Dart poller
      // does not lock onto the empty pre-render height.
      expect(html, contains('if (!el) { window.__mermaidHeight = 0; return 0; }'));
    });
  });

  group('fullscreen (fitViewport) mermaid document', () {
    test('is the zoom/pan layout, distinct from the inline one', () {
      final html = MermaidRuntime.buildHtml(
        code: code,
        theme: 'dark',
        backgroundHex: '#000000',
        foregroundHex: '#ffffff',
        fitViewport: true,
      );
      expect(html, contains('id="stage"'));
      expect(html, contains('function fit()'));
    });

    test('fills the visible area (no 1x scale cap)', () {
      final html = MermaidRuntime.buildHtml(
        code: code,
        theme: 'dark',
        backgroundHex: '#000000',
        foregroundHex: '#ffffff',
        fitViewport: true,
      );
      // A trailing ", 1)" on the fit scale would cap enlargement at 1x, leaving
      // a small diagram floating in the middle instead of filling the viewport.
      expect(
        html,
        contains('scale = Math.min((vw - pad) / nw, (vh - pad) / nh);'),
        reason: 'fullscreen fit must scale up to fill the visible area',
      );
      expect(
        html.contains('(vh - pad) / nh, 1)'),
        isFalse,
        reason: 'the 1x cap must not be reintroduced',
      );
    });

    test('measures via viewBox and centers the diagram', () {
      final html = MermaidRuntime.buildHtml(
        code: code,
        theme: 'dark',
        backgroundHex: '#000000',
        foregroundHex: '#ffffff',
        fitViewport: true,
      );
      // Reliable intrinsic size (getBoundingClientRect is fuzzy for mermaid).
      expect(html, contains('svg.viewBox.baseVal.width'));
      // Centered both axes.
      expect(html, contains('tx = (vw - nw * scale) / 2;'));
      expect(html, contains('ty = (vh - nh * scale) / 2;'));
    });
  });
}
