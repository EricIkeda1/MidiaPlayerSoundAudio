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
    art: json['art'] as String,
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

const demoTracks = [
  Track(
    id: 'blinding',
    title: 'Blinding Lights',
    artist: 'The Weeknd',
    album: 'After Hours',
    art: 'after_hours',
    source: 'night',
  ),
  Track(
    id: 'espresso',
    title: 'Espresso',
    artist: 'Sabrina Carpenter',
    album: 'Short n’ Sweet',
    art: 'espresso',
    source: 'sunset',
  ),
  Track(
    id: 'as-it-was',
    title: 'As It Was',
    artist: 'Harry Styles',
    album: 'Harry’s House',
    art: 'harry',
    source: 'ocean',
  ),
  Track(
    id: 'flowers',
    title: 'Flowers',
    artist: 'Miley Cyrus',
    album: 'Endless Summer Vacation',
    art: 'flowers',
    source: 'sunset',
  ),
  Track(
    id: 'after-hours',
    title: 'After Hours',
    artist: 'The Weeknd',
    album: 'After Hours',
    art: 'after_hours',
    source: 'night',
  ),
  Track(
    id: 'anti-hero',
    title: 'Anti-Hero',
    artist: 'Taylor Swift',
    album: 'Midnights',
    art: 'taylor',
    source: 'ocean',
  ),
  Track(
    id: 'save-your-tears',
    title: 'Save Your Tears',
    artist: 'The Weeknd',
    album: 'After Hours',
    art: 'after_hours',
    source: 'night',
  ),
  Track(
    id: 'levitating',
    title: 'Levitating',
    artist: 'Dua Lipa',
    album: 'Future Nostalgia',
    art: 'dua',
    source: 'sunset',
  ),
  Track(
    id: 'hot-hits',
    title: 'HOT HITS',
    artist: 'Billie Eilish',
    art: 'billie',
    source: 'ocean',
  ),
  Track(
    id: 'short-sweet',
    title: 'Short n’ Sweet',
    artist: 'Sabrina Carpenter',
    art: 'sabrina',
    source: 'sunset',
  ),
  Track(
    id: 'mayhem',
    title: 'MAYHEM',
    artist: 'Lady Gaga',
    art: 'mayhem',
    source: 'night',
  ),
];

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
