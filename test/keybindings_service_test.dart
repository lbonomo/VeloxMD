import 'package:flutter_test/flutter_test.dart';
import 'package:veloxmd/services/keybindings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('KeybindingsService includes exportPdf action with default shortcuts', () async {
    final keybindings = await KeybindingsService.load();

    expect(keybindings[KeyAction.exportPdf], isNotEmpty);
    expect(keybindings.label(KeyAction.exportPdf), equals('Ctrl+P'));
    expect(keybindings.labels(KeyAction.exportPdf), contains('Ctrl+P'));
  });
}
