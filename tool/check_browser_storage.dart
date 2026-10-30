// Execute como JavaScript em um navegador, não na VM de Dart.
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import '../lib/services/platform/media_storage_web.dart' as storage;

Future<void> main() async {
  final output = html.document.body!;
  String? source;
  var checks = 0;
  void check(bool condition, String label) {
    if (!condition) throw StateError(label);
    checks++;
  }

  try {
    source = await storage.persistAudio(
      id: 'browser-test-${DateTime.now().microsecondsSinceEpoch}',
      extension: 'wav',
      bytes: Uint8List.fromList([82, 73, 70, 70]),
    );
    check(await storage.hasAudio(source), 'Arquivo persistido no IndexedDB');
    final bytes = await storage.readAudio(source);
    check(bytes.length == 4 && bytes[0] == 82, 'Leitura dos bytes do áudio');
    check(
      await storage.audioExtension(source) == 'wav',
      'Extensão do download',
    );
    final uri = await storage.audioUri(source);
    check(uri.scheme == 'blob', 'URL de reprodução');
    check(await storage.audioUri(source) == uri, 'Reuso de URL temporária');
    storage.releaseMedia();
    final restored = await storage.audioUri(source);
    check(
      restored.scheme == 'blob' && restored != uri,
      'Reabertura após liberar a memória',
    );
    check(
      (await storage.coverUri(
        'chill',
      )).path.endsWith('/assets/assets/art/chill.png'),
      'Caminho da capa',
    );
    final text = await storage.readLyrics(
      bytes: Uint8List.fromList(utf8.encode('\uFEFF[00:01.00]Canção')),
    );
    check(text == '[00:01.00]Canção', 'Letra UTF-8 e BOM');
    await storage.removeAudio(source);
    check(!await storage.hasAudio(source), 'Remoção do arquivo');
    output.dataset['result'] = 'passed';
    output.text = '$checks verificações de armazenamento web passaram.';
  } catch (e) {
    output.dataset['result'] = 'failed';
    output.text = 'Falhou: $e';
  } finally {
    if (source != null) await storage.removeAudio(source);
    storage.releaseMedia();
  }
}
