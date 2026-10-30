import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../core/theme.dart';
import '../models/track.dart';
import '../services/music_controller.dart';
import 'widgets.dart';
import 'player.dart';
import 'system_previews.dart';

class PageFrame extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  const PageFrame({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Backdrop(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Voltar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  ...?actions,
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    ),
  );
}

class SearchScreen extends StatefulWidget {
  final MusicController music;
  const SearchScreen({super.key, required this.music});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final input = TextEditingController();
  String filter = 'Tudo';
  MusicController get m => widget.music;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: m,
    builder: (context, _) {
      final results = searchTracks(m.tracks, input.text);
      return Scaffold(
        body: Backdrop(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(5, 10, 15, 5),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Voltar',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: TextField(
                          controller: input,
                          autofocus: true,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Buscar músicas, artistas...',
                            isDense: true,
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 19,
                            ),
                            suffixIcon: IconButton(
                              tooltip: 'Limpar busca',
                              onPressed: () {
                                input.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FilterPills(
                    labels: const [
                      'Tudo',
                      'Músicas',
                      'Álbuns',
                      'Artistas',
                      'Playlists',
                    ],
                    selected: filter,
                    onSelected: (v) => setState(() => filter = v),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      SectionTitle(
                        input.text.isEmpty
                            ? 'Suas músicas'
                            : 'Principais resultados',
                      ),
                      if (filter == 'Playlists') ...[
                        for (final name in m.playlists.keys.where(
                          (n) => normalize(n).contains(normalize(input.text)),
                        ))
                          ListTile(
                            leading: const Art('chill', size: 46),
                            title: Text(name),
                            onTap: () => go(
                              context,
                              PlaylistScreen(music: m, name: name),
                            ),
                          ),
                      ] else if (filter == 'Álbuns' ||
                          filter == 'Artistas') ...[
                        for (final name
                            in results
                                .map(
                                  (t) =>
                                      filter == 'Artistas' ? t.artist : t.album,
                                )
                                .toSet())
                          ListTile(
                            leading: const Icon(
                              Icons.album_rounded,
                              color: violet,
                            ),
                            title: Text(name.isEmpty ? 'Singles' : name),
                            onTap: () => go(
                              context,
                              CollectionScreen(
                                music: m,
                                title: name,
                                tracks: results
                                    .where(
                                      (t) =>
                                          (filter == 'Artistas'
                                              ? t.artist
                                              : t.album) ==
                                          name,
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                      ] else ...[
                        for (final t in results)
                          MusicTile(
                            track: t,
                            active: m.current.id == t.id,
                            onTap: () {
                              m.playTrack(t, from: results);
                              go(context, PlayerScreen(music: m));
                            },
                            onMore: () => trackMenu(context, m, t),
                          ),
                        if (results.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(30),
                            child: Text(
                              'Nenhuma música por aqui. Tente outro nome ou procure nos serviços abaixo.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: muted),
                            ),
                          ),
                      ],
                      if (m.serviceResults) ...[
                        const SectionTitle('Em outros serviços'),
                        ServiceTile(
                          spotify: true,
                          subtitle: 'Buscar no Spotify',
                          onTap: () => m.openService(true, input.text),
                        ),
                        ServiceTile(
                          spotify: false,
                          subtitle: 'Abrir no YouTube Music',
                          onTap: () => m.openService(false, input.text),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class PlaylistScreen extends StatelessWidget {
  final MusicController music;
  final String name;
  const PlaylistScreen({super.key, required this.music, required this.name});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: music,
    builder: (context, _) {
      final tracks = music.playlistTracks(name);
      return PageFrame(
        title: '',
        actions: [
          IconButton(
            tooltip: 'Adicionar músicas',
            onPressed: () => _add(context),
            icon: const Icon(Icons.playlist_add_rounded),
          ),
        ],
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            const Center(child: Art('chill', size: 140, radius: 20)),
            const SizedBox(height: 12),
            Text(
              name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${tracks.length} músicas',
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: tracks.isEmpty
                        ? null
                        : () {
                            music.setQueue(tracks);
                            go(context, PlayerScreen(music: music));
                          },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Reproduzir'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: tracks.isEmpty
                        ? null
                        : () async {
                            await music.setQueue(tracks);
                            if (!music.shuffled) await music.shuffle();
                          },
                    icon: const Icon(Icons.shuffle_rounded, size: 18),
                    label: const Text('Aleatório'),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Adicionar músicas',
                onPressed: () => _add(context),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ),
            if (tracks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Sua playlist está pronta para receber músicas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted),
                ),
              ),
            for (final (i, t) in tracks.indexed)
              MusicTile(
                track: t,
                number: i + 1,
                active: music.current.id == t.id,
                onTap: () {
                  music.playTrack(t, from: tracks);
                  go(context, PlayerScreen(music: music));
                },
                onMore: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (sheet) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.remove_circle_outline),
                            title: const Text('Remover da playlist'),
                            onTap: () {
                              music.removeFromPlaylist(name, t);
                              Navigator.pop(sheet);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.more_horiz),
                            title: const Text('Mais opções'),
                            onTap: () {
                              Navigator.pop(sheet);
                              trackMenu(context, music, t);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
  void _add(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .7,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            Text(
              'Adicionar a $name',
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            for (final t in music.tracks)
              MusicTile(
                track: t,
                onTap: () {
                  music.addToPlaylist(name, t);
                  Navigator.pop(sheet);
                  message(context, 'Música adicionada');
                },
                trailing: const Icon(Icons.add_rounded, color: violet),
              ),
          ],
        ),
      ),
    ),
  );
}

class CollectionScreen extends StatelessWidget {
  final MusicController music;
  final String title;
  final List<Track> tracks;
  final String? externalQuery;
  const CollectionScreen({
    super.key,
    required this.music,
    required this.title,
    required this.tracks,
    this.externalQuery,
  });
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: music,
    builder: (context, _) => PageFrame(
      title: title,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (externalQuery != null) ...[
            const Text(
              'Coleção de demonstração',
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 12),
            ServiceTile(
              spotify: true,
              subtitle: 'Explorar $title no Spotify',
              onTap: () => music.openService(true, externalQuery),
            ),
            ServiceTile(
              spotify: false,
              subtitle: 'Explorar no YouTube Music',
              onTap: () => music.openService(false, externalQuery),
            ),
            const SizedBox(height: 16),
          ],
          if (tracks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(36),
              child: Text(
                'Nenhuma música aqui ainda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted),
              ),
            ),
          for (final t in tracks)
            MusicTile(
              track: t,
              active: music.current.id == t.id,
              onTap: () {
                music.playTrack(t, from: tracks);
                go(context, PlayerScreen(music: music));
              },
              onMore: () => trackMenu(context, music, t),
            ),
        ],
      ),
    ),
  );
}

class QueueScreen extends StatelessWidget {
  final MusicController music;
  const QueueScreen({super.key, required this.music});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: music,
    builder: (context, _) => PageFrame(
      title: 'Fila de reprodução',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tocando agora',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (music.queue.isNotEmpty)
                  MusicTile(
                    track: music.current,
                    active: true,
                    onTap: () => go(context, PlayerScreen(music: music)),
                  ),
                const SizedBox(height: 18),
                const Text(
                  'Próximas',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Expanded(
            child: music.queue.isEmpty
                ? const Center(
                    child: Text(
                      'A fila está vazia.',
                      style: TextStyle(color: muted),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: music.queue.length,
                    onReorder: music.reorderQueue,
                    buildDefaultDragHandles: false,
                    itemBuilder: (context, i) {
                      final t = music.queue[i];
                      return MusicTile(
                        key: ValueKey('queue-$i-${t.id}'),
                        track: t,
                        active: i == music.player.currentIndex,
                        onTap: () => music.player.seek(Duration.zero, index: i),
                        trailing: ReorderableDragStartListener(
                          index: i,
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Icon(
                              Icons.drag_handle_rounded,
                              color: muted,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _queueAction(
                  Icons.shuffle_rounded,
                  'Aleatório',
                  music.shuffle,
                  active: music.shuffled,
                ),
                _queueAction(
                  Icons.repeat_rounded,
                  'Repetir',
                  music.repeat,
                  active: music.player.loopMode.name != 'off',
                ),
                _queueAction(
                  Icons.delete_sweep_outlined,
                  'Limpar fila',
                  music.clearQueue,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Widget _queueAction(
    IconData icon,
    String text,
    VoidCallback tap, {
    bool active = false,
  }) => InkWell(
    borderRadius: BorderRadius.circular(24),
    onTap: tap,
    child: Container(
      width: 87,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: active ? lavender : Colors.white.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, color: active ? violet : ink),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontSize: 11)),
        ],
      ),
    ),
  );
}

class ServiceTile extends StatelessWidget {
  final bool spotify;
  final String subtitle;
  final VoidCallback onTap;
  const ServiceTile({
    super.key,
    required this.spotify,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.white.withValues(alpha: .78),
      borderRadius: BorderRadius.circular(24),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 23,
          backgroundColor: spotify
              ? const Color(0xFF09C96C)
              : const Color(0xFFFF172F),
          child: Icon(
            spotify
                ? Icons.graphic_eq_rounded
                : Icons.play_circle_outline_rounded,
            color: Colors.white,
            size: 29,
          ),
        ),
        title: Text(
          spotify ? 'Spotify' : 'YouTube Music',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: muted),
        ),
        trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: muted),
      ),
    ),
  );
}

class ServicesScreen extends StatelessWidget {
  final MusicController music;
  const ServicesScreen({super.key, required this.music});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: music,
    builder: (context, _) => PageFrame(
      title: 'Serviços de música',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          const Text(
            'Encontre suas próximas músicas e playlists.',
            style: TextStyle(color: muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          ServiceTile(
            spotify: true,
            subtitle: 'Abrir músicas e pesquisas',
            onTap: () => music.openService(true),
          ),
          ServiceTile(
            spotify: false,
            subtitle: 'Descubra músicas e playlists',
            onTap: () => music.openService(false),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 18),
            child: Text(
              'As buscas abrem no aplicativo ou site do serviço. Não é necessário conectar sua conta aqui.',
              style: TextStyle(fontSize: 12, color: muted, height: 1.5),
            ),
          ),
          const SectionTitle('Preferências'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Mostrar resultados desses serviços nas pesquisas',
              style: TextStyle(fontSize: 14),
            ),
            value: music.serviceResults,
            onChanged: (v) => music.setPreference('serviceResults', v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Sugestões personalizadas',
              style: TextStyle(fontSize: 14),
            ),
            subtitle: const Text(
              'Mostrar mix criado a partir dos seus favoritos',
              style: TextStyle(fontSize: 11),
            ),
            value: music.suggestions,
            onChanged: (v) => music.setPreference('suggestions', v),
          ),
        ],
      ),
    ),
  );
}

class SettingsScreen extends StatelessWidget {
  final MusicController music;
  const SettingsScreen({super.key, required this.music});
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Sua música',
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const Center(child: Art('icon', size: 88, radius: 25)),
        const SizedBox(height: 15),
        const Text(
          'Música',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 24),
        _tile(
          Icons.add_rounded,
          'Importar músicas',
          'MP3, WAV, M4A, AAC, OGG e FLAC',
          music.importAudio,
        ),
        _tile(
          Icons.hub_outlined,
          'Serviços de música',
          'Spotify e YouTube Music',
          () => go(context, ServicesScreen(music: music)),
        ),
        _tile(
          Icons.timer_outlined,
          'Timer de sono',
          'Sua música descansa com você',
          () => sleepMenu(context, music),
        ),
        const SectionTitle('Prévias da interface'),
        _tile(
          Icons.notifications_none_rounded,
          'Notificação',
          'Visual inspirado na referência',
          () => go(context, SystemPreview(music: music, lockScreen: false)),
        ),
        _tile(
          Icons.lock_outline_rounded,
          'Tela bloqueada',
          'Visual inspirado na referência',
          () => go(context, SystemPreview(music: music, lockScreen: true)),
        ),
        const SizedBox(height: 20),
        Text(
          kIsWeb
              ? 'No navegador, estas telas são prévias dentro do app. Fechar a aba encerra a reprodução.'
              : 'Os controles reais de notificação e tela bloqueada são exibidos pelo sistema do aparelho durante a reprodução.',
          style: TextStyle(fontSize: 12, color: muted, height: 1.5),
        ),
        const SizedBox(height: 14),
        const Text(
          'As capas e nomes do catálogo reproduzem a referência visual. Os áudios inclusos são prévias instrumentais originais, não gravações dos artistas. Importe seus arquivos para ouvir suas músicas.',
          style: TextStyle(fontSize: 12, color: muted, height: 1.5),
        ),
        const SizedBox(height: 26),
        const Text(
          'Versão 1.0.2 • Feito em Flutter',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: muted),
        ),
      ],
    ),
  );
  Widget _tile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback tap,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      onTap: tap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
      tileColor: Colors.white.withValues(alpha: .7),
      leading: Icon(icon, color: violet),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: muted),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}
