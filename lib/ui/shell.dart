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

class _MusicShellState extends State<MusicShell> {
  int tab = 0;
  String homeFilter = 'Tudo', libraryFilter = 'Músicas', exploreFilter = 'Tudo';
  MusicController get m => widget.music;
  @override
  void initState() {
    super.initState();
    m.addListener(_changed);
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
    super.dispose();
  }

  void openPlayer(Track track) {
    m.playTrack(track);
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

  Widget _header(String title, {bool avatar = false}) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.headlineLarge),
        ),
        IconButton(
          tooltip: avatar ? 'Configurações' : 'Buscar',
          onPressed: avatar
              ? () => go(context, SettingsScreen(music: m))
              : search,
          icon: avatar
              ? const Art('avatar', size: 33, radius: 30)
              : const Icon(Icons.search_rounded),
        ),
      ],
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
      _header('Música', avatar: true),
      _search(),
      const SizedBox(height: 9),
      FilterPills(
        labels: const ['Tudo', 'Músicas', 'Álbuns', 'Artistas', 'Playlists'],
        selected: homeFilter,
        onSelected: (v) => setState(() => homeFilter = v),
      ),
      if (isGroups) ...[
        SectionTitle(homeFilter),
        if (homeFilter == 'Playlists')
          ...m.playlists.keys.map((name) => _playlistTile(name))
        else
          ..._groups(homeFilter == 'Artistas'),
      ] else ...[
        SectionTitle(
          'Tocados recentemente',
          onAll: () => setState(() => tab = 2),
        ),
        AlbumGrid(tracks: m.tracks.take(4).toList(), onTap: openPlayer),
        if (m.suggestions && m.favorites.isNotEmpty) ...[
          const SectionTitle('Seu mix de favoritas'),
          AlbumGrid(
            tracks: m.tracks
                .where((t) => m.favorites.contains(t.id))
                .take(4)
                .toList(),
            onTap: openPlayer,
          ),
        ],
        SectionTitle(
          'Feito para você',
          onAll: () => setState(() {
            tab = 2;
            libraryFilter = 'Playlists';
          }),
        ),
        LayoutBuilder(
          builder: (context, c) => Row(
            children: [
              for (final (i, name) in [
                'Mix diário',
                'Descobertas',
                'Relax',
                'Foco',
              ].indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => playlist(name),
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      children: [
                        Container(
                          height: (c.maxWidth - 30) / 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const [
                                  Color(0xFFB49AFF),
                                  Color(0xFFFF81BC),
                                  Color(0xFF8C8AFF),
                                  Color(0xFF78C5FA),
                                ][i],
                                const [
                                  Color(0xFFE6D3FF),
                                  Color(0xFFFFD3EB),
                                  Color(0xFFCCD1FF),
                                  Color(0xFFD0EFFF),
                                ][i],
                              ],
                            ),
                          ),
                          child: Center(
                            child: Transform.rotate(
                              angle: -.35,
                              child: Icon(
                                [
                                  Icons.album_rounded,
                                  Icons.auto_awesome,
                                  Icons.headphones_rounded,
                                  Icons.headset_rounded,
                                ][i],
                                color: const [
                                  Color(0xFF5C28BA),
                                  Color(0xFFAD195B),
                                  Color(0xFF2D35C2),
                                  Color(0xFF1673AE),
                                ][i],
                                size: 33,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          name,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SectionTitle(
          'Playlists para você',
          onAll: () => setState(() {
            tab = 2;
            libraryFilter = 'Playlists';
          }),
        ),
        Row(
          children: [
            for (final (i, name) in [
              'Chill Vibes',
              'Mix diário',
              'Relax',
              'Descobertas',
            ].indexed) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => playlist(name),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Art(
                          ['chill', 'after_hours', 'flowers', 'espresso'][i],
                          radius: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        if (m.tracks.any((t) => t.imported)) ...[
          SectionTitle(
            'No seu dispositivo',
            onAll: () => setState(() {
              tab = 2;
              libraryFilter = 'Downloads';
            }),
          ),
          ...m.tracks
              .where((t) => t.imported)
              .take(4)
              .map(
                (t) => MusicTile(
                  track: t,
                  onTap: () => openPlayer(t),
                  onMore: () => trackMenu(context, m, t),
                ),
              ),
        ],
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
        CollectionScreen(
          music: m,
          title: 'Destaques',
          tracks: m.tracks.skip(8).toList(),
        ),
      ),
    ),
    AlbumGrid(
      tracks: m.tracks.skip(8).take(3).toList(),
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
      'Lançamentos',
      onAll: () => go(
        context,
        CollectionScreen(
          music: m,
          title: 'Lançamentos',
          tracks: m.tracks.take(8).toList(),
        ),
      ),
    ),
    AlbumGrid(
      tracks: [m.tracks[1], m.tracks[9], m.tracks[10]],
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
        tracks: m.tracks.take(8).toList(),
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
                  : m.tracks.take(8).toList();
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
                  '${libraryFilter == 'Downloads' ? m.tracks.where((t) => t.imported).length : m.tracks.length} faixas',
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
              : [
                  m.tracks[0],
                  m.tracks[4],
                  m.tracks[5],
                  m.tracks[2],
                  m.tracks[6],
                  m.tracks[7],
                  m.tracks[3],
                  ...m.tracks.where((t) => t.imported),
                ])
        MusicTile(
          track: t,
          active: m.current.id == t.id,
          onTap: () => openPlayer(t),
          onMore: () => trackMenu(context, m, t),
        ),
      if (libraryFilter == 'Downloads' && !m.tracks.any((t) => t.imported))
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
          child: Column(
            children: [
              const Icon(Icons.library_music_outlined, size: 48, color: violet),
              const SizedBox(height: 16),
              const Text(
                'Suas músicas, aqui.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Importe arquivos do celular para ouvir offline.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: m.importAudio,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Importar músicas'),
              ),
            ],
          ),
        ),
    ],
  ]);
  List<Widget> _groups(bool artists) {
    final groups = <String, List<Track>>{};
    for (final t in m.tracks) {
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
    leading: const Art('chill', size: 54, radius: 12),
    title: Text(name),
    subtitle: Text(
      '${m.playlistTracks(name).length} músicas',
      style: const TextStyle(color: muted),
    ),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => playlist(name),
  );
  Widget _navigation() => Glass(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      child: Row(
        children: [
          for (final (i, label) in ['Início', 'Explorar', 'Biblioteca'].indexed)
            Expanded(
              child: Semantics(
                selected: tab == i,
                button: true,
                label: label,
                child: InkWell(
                  onTap: () => setState(() => tab = i),
                  borderRadius: BorderRadius.circular(28),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    decoration: BoxDecoration(
                      color: tab == i
                          ? const Color(0xFFE1DDFF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          [
                            tab == 0 ? Icons.home_rounded : Icons.home_outlined,
                            Icons.search_rounded,
                            tab == 2
                                ? Icons.library_music_rounded
                                : Icons.library_music_outlined,
                          ][i],
                          color: tab == i ? violet : const Color(0xFF535574),
                          size: 23,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: tab == i
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: tab == i ? violet : const Color(0xFF535574),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 7),
          Semantics(
            button: true,
            label: 'Abrir player: ${m.current.title}',
            child: InkWell(
              onTap: () => go(context, PlayerScreen(music: m)),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Art(m.current.art, size: 43, radius: 15),
                    if (m.playing)
                      const Icon(
                        Icons.equalizer_rounded,
                        size: 23,
                        color: Colors.white,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
