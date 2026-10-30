// Implementação para Flutter Web JavaScript; não é carregada no Android/iOS.
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;
import 'dart:indexed_db' as idb;
import 'dart:typed_data';

Future<idb.Database>? _database;
final _objectUrls = <String, Uri>{};

Future<idb.Database> _openDatabase() async {
  final factory = html.window.indexedDB;
  if (factory == null)
    throw UnsupportedError('O navegador não oferece armazenamento de áudio.');
  return factory.open(
    'musica_media',
    version: 1,
    onUpgradeNeeded: (event) {
      final db = (event.target as idb.Request).result as idb.Database;
      db.createObjectStore('audio');
    },
  );
}

Future<idb.Database> _db() => _database ??= _openDatabase();

Future<html.Blob?> _read(String source) async {
  final db = await _db();
  final tx = db.transaction('audio', 'readonly');
  final completed = tx.completed;
  final result = await tx.objectStore('audio').getObject(source);
  await completed;
  return result as html.Blob?;
}

Future<bool> hasAudio(String source) async {
  if (!source.startsWith('browser:')) return false;
  return await _read(source) != null;
}

Future<String> persistAudio({
  required String id,
  required String extension,
  String? path,
  Uint8List? bytes,
}) async {
  if (bytes == null)
    throw StateError('O navegador não retornou o conteúdo do arquivo.');
  final mime = switch (extension.toLowerCase()) {
    'mp3' => 'audio/mpeg',
    'wav' => 'audio/wav',
    'm4a' => 'audio/mp4',
    'aac' => 'audio/aac',
    'ogg' => 'audio/ogg',
    'flac' => 'audio/flac',
    _ => 'application/octet-stream',
  };
  final source = 'browser:$id';
  final db = await _db();
  final tx = db.transaction('audio', 'readwrite');
  final completed = tx.completed;
  await tx.objectStore('audio').put(html.Blob([bytes], mime), source);
  await completed;
  return source;
}

Future<Uri> audioUri(String source) async {
  final cached = _objectUrls[source];
  if (cached != null) return cached;
  final blob = await _read(source);
  if (blob == null)
    throw StateError(
      'Áudio não encontrado neste navegador. Importe novamente.',
    );
  final uri = Uri.parse(html.Url.createObjectUrlFromBlob(blob));
  _objectUrls[source] = uri;
  return uri;
}

Future<Uri> coverUri(String art) async =>
    Uri.base.resolve('assets/assets/art/$art.png');

Future<String> readLyrics({String? path, Uint8List? bytes}) async {
  if (bytes == null) throw StateError('O navegador não retornou a letra.');
  return utf8.decode(bytes).replaceFirst(RegExp('^\uFEFF'), '');
}

Future<void> removeAudio(String source) async {
  final uri = _objectUrls.remove(source);
  if (uri != null) html.Url.revokeObjectUrl(uri.toString());
  final db = await _db();
  final tx = db.transaction('audio', 'readwrite');
  final completed = tx.completed;
  await tx.objectStore('audio').delete(source);
  await completed;
}

void releaseMedia() {
  for (final uri in _objectUrls.values) {
    html.Url.revokeObjectUrl(uri.toString());
  }
  _objectUrls.clear();
}
