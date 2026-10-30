import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

Future<bool> hasAudio(String source) => File(source).exists();

Future<String> persistAudio({
  required String id,
  required String extension,
  String? path,
  Uint8List? bytes,
}) async {
  final dir = await getApplicationSupportDirectory();
  final destination = File('${dir.path}/$id.$extension');
  if (path != null) return (await File(path).copy(destination.path)).path;
  if (bytes == null) throw StateError('Arquivo sem conteúdo.');
  await destination.writeAsBytes(bytes);
  return destination.path;
}

Future<Uri> audioUri(String source) async =>
    source.startsWith('content://') ? Uri.parse(source) : Uri.file(source);

Future<Uri> coverUri(String art) async {
  final dir = await getApplicationSupportDirectory();
  final file = File('${dir.path}/cover_$art.png');
  if (!await file.exists()) {
    final data = await rootBundle.load('assets/art/$art.png');
    await file.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }
  return file.uri;
}

Future<String> readLyrics({String? path, Uint8List? bytes}) async {
  final content =
      bytes ?? (path == null ? null : await File(path).readAsBytes());
  if (content == null) throw StateError('Arquivo sem conteúdo.');
  return utf8.decode(content).replaceFirst(RegExp('^\uFEFF'), '');
}

void releaseMedia() {}

Future<Uint8List> readAudio(String source) async {
  if (source.startsWith('content://')) {
    final bytes = await const MethodChannel(
      'app.musica/device_library',
    ).invokeMethod<Uint8List>('readAudio', {'source': source});
    if (bytes == null) throw StateError('Áudio indisponível.');
    return bytes;
  }
  return File(source).readAsBytes();
}

Future<void> saveDownload(Uint8List bytes, String name, String mime) async {
  await FilePicker.platform.saveFile(
    dialogTitle: 'Salvar áudio',
    fileName: name,
    bytes: bytes,
  );
}

Future<String> audioExtension(String source) async {
  if (source.startsWith('content://')) {
    return await const MethodChannel(
          'app.musica/device_library',
        ).invokeMethod<String>('audioExtension', {'source': source}) ??
        'audio';
  }
  final extension = source.split('.').last.toLowerCase();
  return RegExp(r'^[a-z0-9]{1,6}$').hasMatch(extension) ? extension : 'audio';
}
