import 'package:flutter_test/flutter_test.dart';
import 'package:veloxmd/services/update_checker.dart';

void main() {
  group('UpdateChecker.isNewer', () {
    test('detects a newer patch/minor/major version', () {
      expect(UpdateChecker.isNewer('0.5.1', '0.5.0'), isTrue);
      expect(UpdateChecker.isNewer('0.6.0', '0.5.0'), isTrue);
      expect(UpdateChecker.isNewer('1.0.0', '0.9.9'), isTrue);
    });

    test('equal versions are not newer', () {
      expect(UpdateChecker.isNewer('0.5.0', '0.5.0'), isFalse);
    });

    test('older versions are not newer', () {
      expect(UpdateChecker.isNewer('0.4.9', '0.5.0'), isFalse);
      expect(UpdateChecker.isNewer('0.5.0', '0.6.0'), isFalse);
    });

    test('ignores build and pre-release suffixes', () {
      expect(UpdateChecker.isNewer('0.5.0+9', '0.5.0'), isFalse);
      expect(UpdateChecker.isNewer('0.5.0', '0.5.0+8'), isFalse);
      expect(UpdateChecker.isNewer('0.6.0-rc1', '0.5.0'), isTrue);
    });

    test('handles differing component counts', () {
      expect(UpdateChecker.isNewer('0.5', '0.5.0'), isFalse);
      expect(UpdateChecker.isNewer('0.5.0.1', '0.5.0'), isTrue);
    });
  });
}
