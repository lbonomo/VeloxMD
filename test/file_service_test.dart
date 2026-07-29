import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloxmd/services/file_service.dart';
import 'package:path/path.dart' as p;

void main() {
  group('FileService.readMarkdown', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('veloxmd_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('reads a valid .md file', () async {
      final file = File(p.join(tempDir.path, 'test.md'));
      await file.writeAsString('# Hello\n\nWorld');
      final content = await FileService.readMarkdown(file.path);
      expect(content, '# Hello\n\nWorld');
    });

    test('reads a valid .markdown file', () async {
      final file = File(p.join(tempDir.path, 'notes.markdown'));
      await file.writeAsString('# Notes\n');
      final content = await FileService.readMarkdown(file.path);
      expect(content, '# Notes\n');
    });

    test('reads a valid .txt file', () async {
      final file = File(p.join(tempDir.path, 'readme.txt'));
      await file.writeAsString('Plain text');
      final content = await FileService.readMarkdown(file.path);
      expect(content, 'Plain text');
    });

    test('throws FileServiceException for a missing file', () async {
      final path = p.join(tempDir.path, 'missing.md');
      expect(
        () => FileService.readMarkdown(path),
        throwsA(isA<FileServiceException>()),
      );
    });

    test('throws FileServiceException for an unsupported extension', () async {
      final file = File(p.join(tempDir.path, 'doc.pdf'));
      await file.writeAsString('not markdown');
      expect(
        () => FileService.readMarkdown(file.path),
        throwsA(isA<FileServiceException>()),
      );
    });
  });
}
