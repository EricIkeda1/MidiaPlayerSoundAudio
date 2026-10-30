import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audio_session/audio_session.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/track.dart';
import 'platform/media_storage.dart' as storage;
import 'device_library.dart';

class MusicController extends ChangeNotifier {
  final AudioPlayer player = AudioPlayer();
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final Map<String, Future<Uri>> _covers = {};
  List<Track> tracks = [];
  List<Track> queue = [];
  Set<String> favorites = {};
  Map<String, List<String>> playlists = {};
  bool serviceResults = true,
      suggestions = true,
      loading = false,
      ready = false;
  String? error;
  int navigationIndex = 0;
  bool scanning = false;
  String libraryPermission = 'notRequested';
  Map<String, dynamic> connection = {};
  bool get supportsDeviceLibrary => DeviceLibrary.supported;
  List<Track> get localTracks => tracks.where((t) => t.imported).toList();
  List<Track> get libraryTracks => tracks;
  bool get hasTracks => tracks.isNotEmpty;
  Map<String, dynamic> notifications = {};
  String get networkLabel => connection.isEmpty
      ? 'Conexão do sistema'
      : connection['connected'] != true
      ? 'Sem conexão'
      : connection['wifi'] == true
      ? (connection['internet'] == true
            ? 'Wi-Fi conectado'
            : 'Wi-Fi sem internet')
      : connection['internet'] == true
      ? 'Internet conectada'
      : 'Rede sem internet';
  void selectTab(int index) {
    navigationIndex = index;
    notifyListeners();
  }

  Timer? _sleepTimer;
  DateTime? sleepUntil;
  Track get current => queue.isNotEmpty
      ? queue[(player.currentIndex ?? 0).clamp(0, queue.length - 1)]
      : tracks.firstOrNull ?? emptyTrack;
  bool get playing => player.playing;
  bool get shuffled => player.shuffleModeEnabled;
  Duration get position => player.position;
  Duration get duration => player.duration ?? Duration.zero;

  Future<void> initialize() async {
    try {
      favorites = (await prefs.getStringList('favorites') ?? []).toSet();
      favorites.removeAll(retiredTrackIds);
      await prefs.setStringList('favorites', favorites.toList());
      serviceResults = await prefs.getBool('serviceResults') ?? true;
      suggestions = await prefs.getBool('suggestions') ?? true;
      final imported = await prefs.getString('imported');
      if (imported != null) {
        for (final track in Track.decode(imported)) {
          if (track.imported &&
              !retiredTrackIds.contains(track.id) &&
              await storage.hasAudio(track.source))
            tracks.add(track);
        }
      }
      final saved = await prefs.getString('playlists');
      if (saved != null) {
        playlists = (jsonDecode(saved) as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, List<String>.from(value as List)),
        );
      }
      playlists = cleanLegacyPlaylists(playlists);
      await prefs.setString('playlists', jsonEncode(playlists));
      final lyrics = await prefs.getString('lyrics');
      if (lyrics != null) {
        final map = jsonDecode(lyrics) as Map<String, dynamic>;
        map.removeWhere((key, _) => retiredTrackIds.contains(key));
        await prefs.setString('lyrics', jsonEncode(map));
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
      if (supportsDeviceLibrary) {
        _subscriptions.add(
          DeviceLibrary.networkChanges.listen((value) {
            connection = value;
            notifyListeners();
          }, onError: (_) {}),
        );
        await refreshDeviceLibrary();
      }
    } catch (e) {
      error = 'O player não pôde iniciar. Tente abrir o app novamente.';
    }
    notifyListeners();
  }

  Future<AudioSource> _source(Track t) async {
    final artUri = await _covers.putIfAbsent(
      t.art,
      () => storage.coverUri(t.art),
    );
    return AudioSource.uri(
      await storage.audioUri(t.source),
      tag: MediaItem(
        id: t.id,
        title: t.title,
        artist: t.artist,
        album: t.album,
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
      await preparePlayback(requestPermission: autoplay);
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
    final list = List<Track>.of(from ?? libraryTracks);
    if (!list.any((t) => t.id == track.id)) list.add(track);
    await setQueue(list, index: list.indexWhere((t) => t.id == track.id));
  }

  Future<void> _play() async {
    try {
      await preparePlayback();
      await player.play();
    } catch (_) {
      error = 'Não foi possível reproduzir este áudio.';
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    if (loading || !hasTracks) return;
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
    if (queue.isEmpty) return;
    if (player.hasNext) {
      await player.seekToNext();
    } else {
      await player.seek(Duration.zero, index: 0);
    }
  }

  Future<void> previous() async {
    if (queue.isEmpty) return;
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

  Future<void> refreshDeviceLibrary({bool requestPermission = false}) async {
    if (!supportsDeviceLibrary || scanning) return;
    scanning = true;
    notifyListeners();
    try {
      connection = await DeviceLibrary.network();
      notifications = await DeviceLibrary.notificationStatus();
      final result = await DeviceLibrary.scan(
        requestPermission: requestPermission,
      );
      libraryPermission = result.status;
      final stored = await prefs.getString('lyrics');
      final lyrics = stored == null
          ? <String, dynamic>{}
          : jsonDecode(stored) as Map<String, dynamic>;
      final scanned = result.tracks
          .map(
            (t) => lyrics[t.id] is String
                ? t.withLyrics(lyrics[t.id] as String)
                : t,
          )
          .toList();
      tracks = mergeDeviceTracks(tracks, scanned);
      if (libraryPermission == 'granted' &&
          localTracks.isNotEmpty &&
          !playing &&
          queue.isEmpty) {
        await setQueue(localTracks, autoplay: false);
      }
      // Não mantenha áudio acessível depois da revogação da permissão.
      if (libraryPermission != 'granted' && queue.any((t) => t.isDeviceTrack)) {
        await clearQueue();
      }
    } catch (_) {
      error = 'Não foi possível atualizar as músicas do dispositivo.';
    } finally {
      scanning = false;
      notifyListeners();
    }
  }

  Future<void> requestDeviceMusic() async {
    if (!supportsDeviceLibrary) {
      await importAudio();
      return;
    }
    if (libraryPermission == 'permanentlyDenied') {
      await DeviceLibrary.openSettings();
      return;
    }
    await refreshDeviceLibrary(requestPermission: true);
  }

  Future<void> preparePlayback({bool requestPermission = true}) async {
    notifications = await DeviceLibrary.preparePlayback(
      requestPermission: requestPermission,
    );
    if (supportsDeviceLibrary && notifications['iconValid'] != true) {
      throw StateError(
        'Ícone da notificação não está instalado. Reinstale o APK atualizado.',
      );
    }
  }

  Future<void> openNotificationSettings() =>
      DeviceLibrary.openNotificationSettings();

  Future<void> openNetworkSettings() => DeviceLibrary.openWifiSettings();
  Future<bool> shareLyrics(String text) async {
    if (await DeviceLibrary.shareLyrics(text)) return true;
    await Clipboard.setData(ClipboardData(text: text));
    return false;
  }

  Future<void> downloadCurrent() async {
    try {
      final track = current;
      if (!hasTracks) return;
      final bytes = await storage.readAudio(track.source);
      final title = track.title.replaceAll(RegExp(r'[^a-zA-Z0-9À-ÿ _-]'), '_');
      final extension = '.${await storage.audioExtension(track.source)}';
      await storage.saveDownload(
        bytes,
        '$title$extension',
        'application/octet-stream',
      );
    } catch (_) {
      error =
          'Não foi possível salvar o áudio. Verifique a permissão e tente novamente.';
      notifyListeners();
    }
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
            art: 'icon',
            source: source,
            imported: true,
          ),
        );
      }
      await prefs.setString(
        'imported',
        Track.encode(
          tracks.where((t) => t.imported && !t.isDeviceTrack).toList(),
        ),
      );
      notifyListeners();
    } catch (e) {
      error = 'Não foi possível importar. Confira o arquivo e tente novamente.';
      notifyListeners();
    }
  }

  Future<void> importLyrics() async {
    try {
      if (!hasTracks) return;
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
    final q =
        query ?? (hasTracks ? '${current.title} ${current.artist}' : 'Música');
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
