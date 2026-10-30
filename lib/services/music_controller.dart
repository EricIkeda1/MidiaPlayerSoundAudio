import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:audio_session/audio_session.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/track.dart';
import 'platform/media_storage.dart' as storage;

class MusicController extends ChangeNotifier {
  final AudioPlayer player = AudioPlayer();
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  List<Track> tracks = [...demoTracks];
  List<Track> queue = [];
  Set<String> favorites = {};
  Map<String, List<String>> playlists = {
    'Chill Vibes': ['blinding', 'as-it-was', 'levitating', 'flowers'],
    'Mix diário': ['blinding', 'espresso', 'as-it-was', 'flowers'],
    'Descobertas': ['hot-hits', 'short-sweet', 'mayhem'],
    'Relax': ['as-it-was', 'flowers', 'levitating'],
    'Foco': ['hot-hits', 'blinding', 'mayhem'],
  };
  bool serviceResults = true,
      suggestions = true,
      loading = false,
      ready = false;
  String? error;
  Timer? _sleepTimer;
  DateTime? sleepUntil;
  Track get current => queue.isNotEmpty
      ? queue[(player.currentIndex ?? 0).clamp(0, queue.length - 1)]
      : tracks.first;
  bool get playing => player.playing;
  bool get shuffled => player.shuffleModeEnabled;
  Duration get position => player.position;
  Duration get duration => player.duration ?? const Duration(seconds: 24);

  Future<void> initialize() async {
    try {
      favorites = (await prefs.getStringList('favorites') ?? []).toSet();
      serviceResults = await prefs.getBool('serviceResults') ?? true;
      suggestions = await prefs.getBool('suggestions') ?? true;
      final imported = await prefs.getString('imported');
      if (imported != null) {
        for (final track in Track.decode(imported)) {
          if (await storage.hasAudio(track.source)) tracks.add(track);
        }
      }
      final saved = await prefs.getString('playlists');
      if (saved != null) {
        playlists = (jsonDecode(saved) as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, List<String>.from(value as List)),
        );
      }
      final lyrics = await prefs.getString('lyrics');
      if (lyrics != null) {
        final map = jsonDecode(lyrics) as Map<String, dynamic>;
        tracks = tracks
            .map(
              (t) =>
                  map[t.id] is String ? t.withLyrics(map[t.id] as String) : t,
            )
            .toList();
      }
      if (!kIsWeb) {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
      }
      _subscriptions.addAll([
        player.playerStateStream.listen((_) => notifyListeners()),
        player.positionStream.listen((_) => notifyListeners()),
        player.currentIndexStream.listen((_) => notifyListeners()),
        player.shuffleModeEnabledStream.listen((_) => notifyListeners()),
        player.loopModeStream.listen((_) => notifyListeners()),
        player.errorStream.listen((e) {
          error = 'Não foi possível reproduzir este arquivo. ${e.message}';
          notifyListeners();
        }),
      ]);
      await setQueue(tracks.take(8).toList(), autoplay: false);
      ready = true;
    } catch (e) {
      error = 'O player não pôde iniciar. Tente abrir o app novamente.';
    }
    notifyListeners();
  }

  Future<AudioSource> _source(Track t) async {
    final artUri = await storage.coverUri(t.art);
    return AudioSource.uri(
      t.imported
          ? await storage.audioUri(t.source)
          : Uri.parse('asset:///assets/audio/${t.source}.wav'),
      tag: MediaItem(
        id: t.id,
        title: t.title,
        artist: t.artist,
        album: t.imported ? t.album : '${t.album} • demonstração instrumental',
        artUri: artUri,
      ),
    );
  }

  Future<void> setQueue(
    List<Track> items, {
    int index = 0,
    bool autoplay = true,
  }) async {
    if (items.isEmpty || loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final sources = await Future.wait(items.map(_source));
      await player.pause();
      await player.setAudioSources(
        sources,
        initialIndex: index.clamp(0, items.length - 1),
      );
      queue = [...items];
      if (autoplay) unawaited(_play());
    } catch (e) {
      error = 'Não foi possível abrir o áudio. Importe um arquivo compatível.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> playTrack(Track track, {List<Track>? from}) async {
    final list = from ?? tracks.take(8).toList();
    if (!list.any((t) => t.id == track.id)) list.add(track);
    await setQueue(list, index: list.indexWhere((t) => t.id == track.id));
  }

  Future<void> _play() async {
    try {
      await player.play();
    } catch (_) {
      error = 'Não foi possível reproduzir este áudio.';
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    if (loading) return;
    if (queue.isEmpty) {
      await setQueue([current]);
      return;
    }
    if (playing) {
      await player.pause();
    } else {
      if (player.processingState == ProcessingState.completed)
        await player.seek(Duration.zero);
      unawaited(_play());
    }
  }

  Future<void> next() async {
    if (player.hasNext) {
      await player.seekToNext();
    } else {
      await player.seek(Duration.zero, index: 0);
    }
  }

  Future<void> previous() async {
    if (position.inSeconds > 3) {
      await player.seek(Duration.zero);
    } else if (player.hasPrevious) {
      await player.seekToPrevious();
    } else {
      await player.seek(Duration.zero);
    }
  }

  Future<void> seek(double value) =>
      player.seek(Duration(milliseconds: value.round()));
  Future<void> shuffle() => player.setShuffleModeEnabled(!shuffled);
  Future<void> repeat() => player.setLoopMode(switch (player.loopMode) {
    LoopMode.off => LoopMode.all,
    LoopMode.all => LoopMode.one,
    LoopMode.one => LoopMode.off,
  });
  Future<void> favorite(Track track) async {
    if (!favorites.add(track.id)) favorites.remove(track.id);
    notifyListeners();
    await prefs.setStringList('favorites', favorites.toList());
  }

  List<Track> playlistTracks(String name) => (playlists[name] ?? [])
      .map((id) => tracks.where((t) => t.id == id).firstOrNull)
      .whereType<Track>()
      .toList();
  Future<void> createPlaylist(String name) async {
    final title = name.trim();
    if (title.isEmpty || playlists.containsKey(title)) return;
    playlists[title] = [];
    await _savePlaylists();
  }

  Future<void> addToPlaylist(String name, Track track) async {
    final list = playlists.putIfAbsent(name, () => []);
    if (!list.contains(track.id)) list.add(track.id);
    await _savePlaylists();
  }

  Future<void> removeFromPlaylist(String name, Track track) async {
    playlists[name]?.remove(track.id);
    await _savePlaylists();
  }

  Future<void> _savePlaylists() async {
    notifyListeners();
    await prefs.setString('playlists', jsonEncode(playlists));
  }

  Future<void> addToQueue(Track track) async {
    if (queue.isEmpty) {
      await setQueue([track], autoplay: false);
      return;
    }
    await player.addAudioSource(await _source(track));
    queue.add(track);
    notifyListeners();
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    if (oldIndex == newIndex) return;
    await player.moveAudioSource(oldIndex, newIndex);
    final item = queue.removeAt(oldIndex);
    queue.insert(newIndex, item);
    notifyListeners();
  }

  Future<void> clearQueue() async {
    await player.stop();
    await player.clearAudioSources();
    queue = [];
    notifyListeners();
  }

  Future<void> importAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
        allowMultiple: true,
        withData: kIsWeb,
      );
      if (result == null) return;
      for (final file in result.files) {
        final id =
            'local-${DateTime.now().microsecondsSinceEpoch}-${tracks.length}';
        final ext = file.name.split('.').last.toLowerCase();
        final source = await storage.persistAudio(
          id: id,
          extension: ext,
          path: kIsWeb ? null : file.path,
          bytes: file.bytes,
        );
        final title = file.name.replaceFirst(RegExp(r'\.[^.]+$'), '');
        tracks.add(
          Track(
            id: id,
            title: title,
            artist: 'No dispositivo',
            album: 'Importadas',
            art: 'chill',
            source: source,
            imported: true,
          ),
        );
      }
      await prefs.setString(
        'imported',
        Track.encode(tracks.where((t) => t.imported).toList()),
      );
      notifyListeners();
    } catch (e) {
      error = 'Não foi possível importar. Confira o arquivo e tente novamente.';
      notifyListeners();
    }
  }

  Future<void> importLyrics() async {
    try {
      final id = current.id;
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['lrc', 'txt'],
        withData: kIsWeb,
      );
      if (result == null) return;
      final file = result.files.single;
      final text = await storage.readLyrics(
        path: kIsWeb ? null : file.path,
        bytes: file.bytes,
      );
      tracks = tracks.map((t) => t.id == id ? t.withLyrics(text) : t).toList();
      queue = queue.map((t) => t.id == id ? t.withLyrics(text) : t).toList();
      await prefs.setString(
        'lyrics',
        jsonEncode({
          for (final t in tracks)
            if (t.lyrics != null) t.id: t.lyrics,
        }),
      );
      notifyListeners();
    } catch (e) {
      error = 'Não foi possível ler a letra.';
      notifyListeners();
    }
  }

  Future<void> setPreference(String key, bool value) async {
    if (key == 'serviceResults') serviceResults = value;
    if (key == 'suggestions') suggestions = value;
    notifyListeners();
    await prefs.setBool(key, value);
  }

  Future<bool> openService(bool spotify, [String? query]) async {
    final q = query ?? '${current.title} ${current.artist}';
    final uri = spotify
        ? Uri.https('open.spotify.com', '/search/$q')
        : Uri.https('music.youtube.com', '/search', {'q': q});
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      error = 'Não foi possível abrir o serviço.';
      notifyListeners();
      return false;
    }
  }

  void sleep(int? minutes) {
    _sleepTimer?.cancel();
    sleepUntil = null;
    if (minutes != null) {
      sleepUntil = DateTime.now().add(Duration(minutes: minutes));
      _sleepTimer = Timer(Duration(minutes: minutes), () {
        player.pause();
        sleepUntil = null;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void dismissError() {
    error = null;
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    unawaited(player.dispose().whenComplete(storage.releaseMedia));
    super.dispose();
  }
}
