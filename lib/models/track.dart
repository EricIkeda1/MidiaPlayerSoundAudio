import 'dart:convert';

class Track {
  final String id, title, artist, album, art, source;
  final bool imported;
  final String? lyrics;
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.art,
    required this.source,
    this.album = '',
    this.imported = false,
    this.lyrics,
  });

  bool get isDeviceTrack => Uri.tryParse(source)?.scheme == 'content';

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'album': album,
    'art': art,
    'source': source,
    'imported': imported,
    'lyrics': lyrics,
  };
  factory Track.fromJson(Map<String, dynamic> json) => Track(
    id: json['id'] as String,
    title: json['title'] as String,
    artist: json['artist'] as String,
    album: json['album'] as String? ?? '',
    art: 'icon',
    source: json['source'] as String,
    imported: json['imported'] == true,
    lyrics: json['lyrics'] as String?,
  );
  Track withLyrics(String value) => Track(
    id: id,
    title: title,
    artist: artist,
    art: art,
    source: source,
    album: album,
    imported: imported,
    lyrics: value,
  );
  static String encode(List<Track> tracks) =>
      jsonEncode(tracks.map((t) => t.toJson()).toList());
  static List<Track> decode(String json) => (jsonDecode(json) as List)
      .map((e) => Track.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Estado visual de uma biblioteca vazia; nunca é inserido na fila.
const emptyTrack = Track(
  id: '',
  title: 'Nenhuma música selecionada',
  artist: 'Escolha uma faixa na biblioteca',
  art: 'icon',
  source: '',
  imported: true,
);

// Somente identificadores usados para migrar dados de versões anteriores.
const retiredTrackIds = {
  'blinding',
  'espresso',
  'as-it-was',
  'flowers',
  'after-hours',
  'anti-hero',
  'save-your-tears',
  'levitating',
  'hot-hits',
  'short-sweet',
  'mayhem',
};
const retiredPlaylistNames = {
  'Chill Vibes',
  'Mix diário',
  'Descobertas',
  'Relax',
  'Foco',
};
Map<String, List<String>> cleanLegacyPlaylists(
  Map<String, List<String>> input,
) {
  final result = <String, List<String>>{};
  for (final entry in input.entries) {
    final ids = entry.value
        .where((id) => !retiredTrackIds.contains(id))
        .toList();
    if (ids.isEmpty && retiredPlaylistNames.contains(entry.key)) continue;
    result[entry.key] = ids;
  }
  return result;
}

String normalize(String text) {
  const accented = 'áàãâäéèêëíìîïóòõôöúùûüç';
  const plain = 'aaaaaeeeeiiiiooooouuuuc';
  var value = text.toLowerCase().trim();
  for (var i = 0; i < accented.length; i++) {
    value = value.replaceAll(accented[i], plain[i]);
  }
  return value;
}

List<Track> searchTracks(Iterable<Track> tracks, String query) {
  final words = normalize(
    query,
  ).split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  return tracks.where((t) {
    final value = normalize('${t.title} ${t.artist} ${t.album}');
    return words.every(value.contains);
  }).toList();
}

class LyricLine {
  final Duration time;
  final String text;
  const LyricLine(this.time, this.text);
}

List<LyricLine> parseLrc(String input) {
  final result = <LyricLine>[];
  final timeTag = RegExp(r'\[(\d+):(\d{2})(?:\.(\d{1,3}))?\]');
  for (final line in input.split('\n')) {
    final matches = timeTag.allMatches(line).toList();
    final text = line.replaceAll(timeTag, '').trim();
    if (text.isEmpty) continue;
    for (final match in matches) {
      final fraction = (match.group(3) ?? '').padRight(3, '0');
      result.add(
        LyricLine(
          Duration(
            minutes: int.parse(match.group(1)!),
            seconds: int.parse(match.group(2)!),
            milliseconds: int.parse(fraction),
          ),
          text,
        ),
      );
    }
  }
  result.sort((a, b) => a.time.compareTo(b.time));
  return result;
}

/// Substitui apenas a leitura anterior do MediaStore, preservando importações e letras.
List<Track> mergeDeviceTracks(List<Track> existing, List<Track> scanned) {
  final old = {for (final t in existing) t.id: t};
  final result = existing.where((t) => !t.isDeviceTrack).toList();
  final ids = result.map((t) => t.id).toSet();
  for (final track in scanned) {
    if (!ids.add(track.id)) continue;
    final lyrics = old[track.id]?.lyrics;
    result.add(lyrics == null ? track : track.withLyrics(lyrics));
  }
  return result;
}
