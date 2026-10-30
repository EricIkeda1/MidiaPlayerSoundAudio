import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/track.dart';
import '../services/music_controller.dart';
import 'widgets.dart';
import 'player.dart';
import 'secondary.dart';

class MusicShell extends StatefulWidget {
  final MusicController music;
  const MusicShell({super.key, required this.music});
  @override
  State<MusicShell> createState() => _MusicShellState();
}

class _MusicShellState extends State<MusicShell> with WidgetsBindingObserver {
  int get tab => m.navigationIndex;
  set tab(int value) => m.navigationIndex = value;
  String homeFilter = 'Tudo', libraryFilter = 'Músicas', exploreFilter = 'Tudo';
  MusicController get m => widget.music;
  @override
  void initState() {
    super.initState();
    m.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    if (m.error != null) {
      final text = m.error!;
      m.dismissError();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) message(context, text);
      });
    }
  }

  @override
  void dispose() {
    m.removeListener(_changed);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && m.ready) m.refreshDeviceLibrary();
  }

  void openPlayer(Track track) {
    m.playTrack(track, from: m.libraryTracks);
    go(context, PlayerScreen(music: m));
  }

  void playlist(String name) =>
      go(context, PlaylistScreen(music: m, name: name));
  void search() => go(context, SearchScreen(music: m));

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Backdrop(
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(
                index: tab,
                children: [_home(), _explore(), _library()],
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: MediaQuery.paddingOf(context).bottom + 12,
              child: _navigation(),
            ),
            if (m.loading)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _header(String title, {bool menu = false}) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.headlineLarge),
        ),
        IconButton(
          tooltip: menu ? 'Menu' : 'Buscar',
          onPressed: menu ? () => _openMenu() : search,
          icon: menu
              ? const Icon(Icons.more_horiz_rounded)
              : const Icon(Icons.search_rounded),
        ),
      ],
    ),
  );
  void _openMenu() => showModalBottomSheet<void>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, label) in [
              'Início',
              'Explorar',
              'Biblioteca',
            ].indexed)
              ListTile(
                leading: Icon(
                  [
                    Icons.home_rounded,
                    Icons.search_rounded,
                    Icons.library_music_rounded,
                  ][i],
                ),
                title: Text(label),
                onTap: () {
                  Navigator.pop(sheet);
                  setState(() => tab = i);
                },
              ),
            ListTile(
              leading: const Icon(Icons.hub_outlined),
              title: const Text('Serviços de música'),
              onTap: () {
                Navigator.pop(sheet);
                go(context, ServicesScreen(music: m));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configurações'),
              onTap: () {
                Navigator.pop(sheet);
                go(context, SettingsScreen(music: m));
              },
            ),
          ],
        ),
      ),
    ),
  );

  Widget _deviceAccess() => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 6),
    child: Material(
      color: Colors.white.withValues(alpha: .7),
      borderRadius: BorderRadius.circular(22),
      child: ListTile(
        leading: Icon(
          m.libraryPermission == 'granted'
              ? Icons.library_music_outlined
              : Icons.folder_open_rounded,
          color: violet,
        ),
        title: Text(
          m.libraryPermission == 'granted'
              ? '${m.tracks.where((t) => t.isDeviceTrack).length} músicas no dispositivo'
              : 'Acessar músicas do dispositivo',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          m.libraryPermission == 'granted'
              ? m.networkLabel
              : 'Permita o acesso para encontrar suas músicas',
          style: const TextStyle(fontSize: 11, color: muted),
        ),
        trailing: m.scanning
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                m.libraryPermission == 'granted'
                    ? Icons.refresh_rounded
                    : Icons.chevron_right_rounded,
                color: violet,
              ),
        onTap: m.scanning
            ? null
            : () {
                if (m.libraryPermission == 'granted') {
                  m.refreshDeviceLibrary();
                } else {
                  m.requestDeviceMusic();
                }
              },
      ),
    ),
  );

  Widget _search() => InkWell(
    onTap: search,
    borderRadius: BorderRadius.circular(28),
    child: Container(
      height: 39,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EAF4),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: const Row(
        children: [
          Icon(Icons.search_rounded, size: 18, color: muted),
          SizedBox(width: 8),
          Text(
            'Buscar músicas, artistas, álbuns...',
            style: TextStyle(fontSize: 12, color: muted),
          ),
        ],
      ),
    ),
  );
  Widget _scroll(List<Widget> children) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 112),
    children: children,
  );

  Widget _home() {
    final isGroups = ['Álbuns', 'Artistas', 'Playlists'].contains(homeFilter);
    return _scroll([
      _header('Música', menu: true),
      _search(),
      if (m.supportsDeviceLibrary && m.libraryPermission != 'granted')
        _deviceAccess(),
      const SizedBox(height: 9),
      FilterPills(
        labels: const ['Tudo', 'Músicas', 'Álbuns', 'Artistas', 'Playlists'],
        selected: homeFilter,
        onSelected: (v) => setState(() => homeFilter = v),
      ),
      if (!m.hasTracks && !isGroups)
        EmptyLibrary(music: m)
      else if (isGroups) ...[
        SectionTitle(homeFilter),
        if (homeFilter == 'Playlists') ...[
          ...m.playlists.keys.map(_playlistTile),
          ListTile(
            leading: const Icon(Icons.playlist_add_rounded, color: violet),
            title: const Text('Criar playlist'),
            onTap: () => newPlaylist(context, m),
          ),
        ] else if (!m.hasTracks)
          EmptyLibrary(music: m)
        else
          ..._groups(homeFilter == 'Artistas'),
      ] else ...[
        SectionTitle('Suas músicas', onAll: () => setState(() => tab = 2)),
        AlbumGrid(tracks: m.libraryTracks.take(4).toList(), onTap: openPlayer),
        if (m.suggestions && m.favorites.isNotEmpty) ...[
          const SectionTitle('Feito para você'),
          AlbumGrid(
            tracks: m.tracks
                .where((t) => m.favorites.contains(t.id))
                .take(4)
                .toList(),
            onTap: openPlayer,
          ),
        ],
        SectionTitle(
          'No seu dispositivo',
          onAll: () => setState(() => tab = 2),
        ),
        for (final t in m.tracks.take(5))
          MusicTile(
            track: t,
            active: m.current.id == t.id,
            onTap: () => openPlayer(t),
            onMore: () => trackMenu(context, m, t),
          ),
        SectionTitle(
          'Suas playlists',
          onAll: () => setState(() {
            tab = 2;
            libraryFilter = 'Playlists';
          }),
        ),
        ...m.playlists.keys.map(_playlistTile),
        TextButton.icon(
          onPressed: () => newPlaylist(context, m),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Criar playlist'),
        ),
      ],
    ]);
  }

  Widget _explore() => _scroll([
    Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Explorar',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          IconButton(
            tooltip: 'Serviços de música',
            onPressed: () => go(context, ServicesScreen(music: m)),
            icon: const Icon(Icons.manage_accounts_outlined),
          ),
        ],
      ),
    ),
    _search(),
    const SizedBox(height: 14),
    Row(
      children: [
        Expanded(child: _serviceChip(true)),
        const SizedBox(width: 8),
        Expanded(child: _serviceChip(false)),
        const SizedBox(width: 8),
        ActionChip(
          label: const Text(
            'Tudo',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          backgroundColor: violet,
          side: BorderSide.none,
          onPressed: () => setState(() => exploreFilter = 'Tudo'),
        ),
      ],
    ),
    SectionTitle(
      exploreFilter == 'Tudo' ? 'Destaques' : exploreFilter,
      onAll: () => go(
        context,
        CollectionScreen(music: m, title: 'Destaques', tracks: m.libraryTracks),
      ),
    ),
    AlbumGrid(
      tracks: m.libraryTracks.take(3).toList(),
      onTap: openPlayer,
      columns: 3,
    ),
    SectionTitle('Gêneros', onAll: () => _genresSheet()),
    LayoutBuilder(
      builder: (context, c) => Wrap(
        spacing: 9,
        runSpacing: 9,
        children: [
          for (final (i, genre) in [
            'Pop',
            'Rock',
            'Hip Hop',
            'Eletrônica',
            'Sertanejo',
            'MPB',
            'Indie',
            'K-Pop',
          ].indexed)
            SizedBox(
              width: (c.maxWidth - 27) / 4,
              child: InkWell(
                onTap: () => _genre(genre),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 82,
                  decoration: BoxDecoration(
                    color: const [
                      Color(0xFFEAADED),
                      Color(0xFFB1E2DD),
                      Color(0xFFF8C99F),
                      Color(0xFFC1B7FF),
                      Color(0xFFFFC9BA),
                      Color(0xFFBCE5D6),
                      Color(0xFFC5CEFF),
                      Color(0xFFFFBEC7),
                    ][i],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        [
                          Icons.album,
                          Icons.music_note_rounded,
                          Icons.speaker_rounded,
                          Icons.graphic_eq,
                          Icons.near_me,
                          Icons.mic_rounded,
                          Icons.headphones,
                          Icons.music_note,
                        ][i],
                        color: const [
                          Color(0xFF9C319F),
                          Color(0xFF207D7C),
                          Color(0xFFAB682D),
                          Color(0xFF5935C9),
                          Color(0xFFB9442D),
                          Color(0xFF267F63),
                          Color(0xFF3B56AD),
                          Color(0xFFB53754),
                        ][i],
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        genre,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    SectionTitle(
      'Adicionadas recentemente',
      onAll: () => go(
        context,
        CollectionScreen(
          music: m,
          title: 'Adicionadas recentemente',
          tracks: m.tracks.take(8).toList(),
        ),
      ),
    ),
    AlbumGrid(
      tracks: m.libraryTracks.reversed.take(3).toList(),
      onTap: openPlayer,
      columns: 3,
    ),
  ]);
  Widget _serviceChip(bool spotify) => ActionChip(
    onPressed: () => m.openService(
      spotify,
      exploreFilter == 'Tudo' ? 'Novidades' : exploreFilter,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 2),
    avatar: Icon(
      spotify ? Icons.graphic_eq_rounded : Icons.play_circle_fill_rounded,
      color: spotify ? const Color(0xFF007C63) : Colors.red,
      size: 16,
    ),
    label: Text(
      spotify ? 'Spotify' : 'YouTube Music',
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
    ),
    backgroundColor: spotify
        ? const Color(0xFFCCF1E5)
        : const Color(0xFFFFDFE9),
    side: BorderSide.none,
  );
  void _genre(String genre) {
    setState(() => exploreFilter = genre);
    go(
      context,
      CollectionScreen(
        music: m,
        title: genre,
        tracks: const [],
        externalQuery: genre,
      ),
    );
  }

  void _genresSheet() => showModalBottomSheet<void>(
    context: context,
    builder: (sheet) => Padding(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final name in [
            'Pop',
            'Rock',
            'Hip Hop',
            'Eletrônica',
            'Sertanejo',
            'MPB',
            'Indie',
            'K-Pop',
            'Jazz',
            'Clássica',
          ])
            ActionChip(
              label: Text(name),
              onPressed: () {
                Navigator.pop(sheet);
                _genre(name);
              },
            ),
        ],
      ),
    ),
  );

  Widget _library() => _scroll([
    _header('Biblioteca'),
    if (m.supportsDeviceLibrary) _deviceAccess(),
    FilterPills(
      labels: const ['Músicas', 'Álbuns', 'Artistas', 'Playlists', 'Downloads'],
      selected: libraryFilter,
      onSelected: (v) => setState(() => libraryFilter = v),
    ),
    const SizedBox(height: 15),
    if (libraryFilter == 'Playlists') ...[
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(
          backgroundColor: lavender,
          child: Icon(Icons.add_rounded, color: violet),
        ),
        title: const Text('Nova playlist'),
        onTap: () => newPlaylist(context, m),
      ),
      ...m.playlists.keys.map(_playlistTile),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFDFE9),
          child: Icon(Icons.favorite_rounded, color: Color(0xFFE24F83)),
        ),
        title: const Text('Favoritas'),
        subtitle: Text('${m.favorites.length} músicas'),
        onTap: () => go(
          context,
          CollectionScreen(
            music: m,
            title: 'Favoritas',
            tracks: m.tracks.where((t) => m.favorites.contains(t.id)).toList(),
          ),
        ),
      ),
    ] else if (libraryFilter == 'Álbuns' || libraryFilter == 'Artistas')
      ..._groups(libraryFilter == 'Artistas')
    else ...[
      Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'Reproduzir em ordem aleatória',
            onPressed: () async {
              final items = libraryFilter == 'Downloads'
                  ? m.tracks.where((t) => t.imported).toList()
                  : m.libraryTracks;
              if (items.isEmpty) return;
              await m.setQueue(items);
              if (!m.shuffled) await m.shuffle();
            },
            icon: const Icon(Icons.shuffle_rounded, color: violet),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reproduzir todas',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  '${libraryFilter == 'Downloads' ? m.tracks.where((t) => t.imported).length : m.libraryTracks.length} faixas',
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Importar músicas',
            onPressed: m.importAudio,
            icon: const Icon(Icons.add_rounded, color: violet),
          ),
        ],
      ),
      const SizedBox(height: 10),
      for (final t
          in libraryFilter == 'Downloads'
              ? m.tracks.where((t) => t.imported)
              : m.libraryTracks)
        MusicTile(
          track: t,
          active: m.current.id == t.id,
          onTap: () => openPlayer(t),
          onMore: () => trackMenu(context, m, t),
        ),
      if (!m.hasTracks) EmptyLibrary(music: m),
    ],
  ]);
  List<Widget> _groups(bool artists) {
    if (!m.hasTracks) return [EmptyLibrary(music: m)];
    final groups = <String, List<Track>>{};
    for (final t in m.libraryTracks) {
      groups
          .putIfAbsent(
            artists
                ? t.artist
                : t.album.isEmpty
                ? 'Singles'
                : t.album,
            () => [],
          )
          .add(t);
    }
    return groups.entries
        .map(
          (entry) => ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            leading: Art(
              entry.value.first.art,
              size: 54,
              radius: artists ? 40 : 12,
            ),
            title: Text(entry.key),
            subtitle: Text(
              '${entry.value.length} músicas',
              style: const TextStyle(color: muted),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => go(
              context,
              CollectionScreen(music: m, title: entry.key, tracks: entry.value),
            ),
          ),
        )
        .toList();
  }

  Widget _playlistTile(String name) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 4),
    leading: const Art('icon', size: 54, radius: 12),
    title: Text(name),
    subtitle: Text(
      '${m.playlistTracks(name).length} músicas',
      style: const TextStyle(color: muted),
    ),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => playlist(name),
  );
  Widget _navigation() => FloatingMusicNavigation(
    music: m,
    activeIndex: tab,
    onSelected: (index) => setState(() => tab = index),
    onPlayer: () => go(context, PlayerScreen(music: m)),
  );
}
