import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/track.dart';
import '../services/music_controller.dart';

void go(BuildContext context, Widget screen) => Navigator.of(context).push(
  PageRouteBuilder(
    pageBuilder: (_, animation, __) => screen,
    transitionsBuilder: (_, animation, __, child) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, .035), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    ),
    transitionDuration: const Duration(milliseconds: 280),
  ),
);

void message(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

class Art extends StatelessWidget {
  final String name;
  final double? size;
  final double radius;
  const Art(this.name, {super.key, this.size, this.radius = 14});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: Image.asset(
      'assets/art/$name.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        color: lavender,
        child: const Icon(Icons.music_note_rounded, color: violet),
      ),
    ),
  );
}

class Backdrop extends StatelessWidget {
  final Widget child;
  const Backdrop({super.key, required this.child});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(gradient: backgroundGradient),
    child: child,
  );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onAll;
  const SectionTitle(this.title, {super.key, this.onAll});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 23, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -.3,
            ),
          ),
        ),
        if (onAll != null)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onAll,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(
                    'Ver tudo',
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 16, color: muted),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class FilterPills extends StatelessWidget {
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelected;
  const FilterPills({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: labels
          .map(
            (label) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(label),
                selected: selected == label,
                onSelected: (_) => onSelected(label),
                showCheckmark: false,
                selectedColor: violet,
                backgroundColor: const Color(0xFFE9EAF5),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
                labelPadding: const EdgeInsets.symmetric(horizontal: 3),
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: selected == label ? Colors.white : ink,
                ),
                shape: const StadiumBorder(),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class MusicTile extends StatelessWidget {
  final Track track;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onMore;
  final Widget? trailing;
  final int? number;
  const MusicTile({
    super.key,
    required this.track,
    required this.onTap,
    this.active = false,
    this.onMore,
    this.trailing,
    this.number,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: active ? lavender : Colors.transparent,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        child: Row(
          children: [
            if (number != null)
              SizedBox(
                width: 19,
                child: Text(
                  '$number',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ),
            Art(track.art, size: 48, radius: 9),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: muted),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (active)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.equalizer_rounded, color: violet, size: 22),
              )
            else
              IconButton(
                tooltip: 'Opções da música',
                onPressed: onMore,
                icon: const Icon(Icons.more_vert_rounded, size: 21),
              ),
          ],
        ),
      ),
    ),
  );
}

class AlbumGrid extends StatelessWidget {
  final List<Track> tracks;
  final ValueChanged<Track> onTap;
  final int columns;
  const AlbumGrid({
    super.key,
    required this.tracks,
    required this.onTap,
    this.columns = 4,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
      return Wrap(
        spacing: 10,
        runSpacing: 17,
        children: tracks
            .map(
              (t) => SizedBox(
                width: width,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onTap(t),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Art(t.art, radius: 12),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        t.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: muted),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class Glass extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color color;
  const Glass({
    super.key,
    required this.child,
    this.radius = 30,
    this.color = const Color(0xCFFFFFFF),
  });
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white.withValues(alpha: .5)),
        ),
        child: child,
      ),
    ),
  );
}

String clock(Duration duration) =>
    '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

class ProgressBar extends StatelessWidget {
  final MusicController music;
  final Color color;
  const ProgressBar({
    super.key,
    required this.music,
    this.color = Colors.white,
  });
  @override
  Widget build(BuildContext context) {
    final max = music.duration.inMilliseconds.toDouble().clamp(
      1.0,
      double.infinity,
    );
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: .22),
            thumbColor: color,
            overlayColor: color.withValues(alpha: .1),
          ),
          child: Slider(
            padding: const EdgeInsets.symmetric(vertical: 10),
            min: 0,
            max: max,
            value: music.position.inMilliseconds.toDouble().clamp(0, max),
            onChanged: music.loading || !music.hasTracks ? null : music.seek,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              clock(music.position),
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: .8),
              ),
            ),
            Text(
              clock(music.duration),
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: .8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PlaybackControls extends StatelessWidget {
  final MusicController music;
  final Color color;
  final bool compact;
  const PlaybackControls({
    super.key,
    required this.music,
    this.color = Colors.white,
    this.compact = false,
  });
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      IconButton(
        tooltip: 'Aleatório',
        onPressed: music.shuffle,
        icon: Icon(
          Icons.shuffle_rounded,
          color: music.shuffled ? const Color(0xFFC9B8FF) : color,
          size: 22,
        ),
      ),
      IconButton(
        tooltip: 'Anterior',
        onPressed: music.previous,
        icon: Icon(Icons.skip_previous_rounded, color: color, size: 32),
      ),
      SizedBox(
        width: compact ? 52 : 76,
        height: compact ? 52 : 76,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
            side: BorderSide(color: color.withValues(alpha: .5)),
          ),
          onPressed: music.loading ? null : music.toggle,
          child: music.loading
              ? SizedBox(
                  width: 23,
                  height: 23,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Icon(
                  music.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: color,
                  size: compact ? 34 : 44,
                ),
        ),
      ),
      IconButton(
        tooltip: 'Próxima',
        onPressed: music.next,
        icon: Icon(Icons.skip_next_rounded, color: color, size: 32),
      ),
      IconButton(
        tooltip: 'Repetir',
        onPressed: music.repeat,
        icon: Icon(
          music.player.loopMode.name == 'one'
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded,
          color: music.player.loopMode.name == 'off'
              ? color
              : const Color(0xFFC9B8FF),
          size: 22,
        ),
      ),
    ],
  );
}

Future<void> trackMenu(
  BuildContext context,
  MusicController music,
  Track track,
) => showModalBottomSheet<void>(
  context: context,
  builder: (sheet) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MusicTile(
            track: track,
            onTap: () {},
            trailing: const SizedBox.shrink(),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              music.favorites.contains(track.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
            ),
            title: Text(
              music.favorites.contains(track.id)
                  ? 'Remover dos favoritos'
                  : 'Adicionar aos favoritos',
            ),
            onTap: () {
              music.favorite(track);
              Navigator.pop(sheet);
            },
          ),
          ListTile(
            leading: const Icon(Icons.queue_music_rounded),
            title: const Text('Adicionar à fila'),
            onTap: () {
              music.addToQueue(track);
              Navigator.pop(sheet);
              message(context, 'Adicionada à fila');
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add_rounded),
            title: const Text('Adicionar à playlist'),
            onTap: () {
              Navigator.pop(sheet);
              playlistPicker(context, music, track);
            },
          ),
          ListTile(
            leading: const Icon(Icons.open_in_new_rounded),
            title: const Text('Buscar no Spotify'),
            onTap: () {
              Navigator.pop(sheet);
              music.openService(true, '${track.title} ${track.artist}');
            },
          ),
          ListTile(
            leading: const Icon(Icons.play_circle_outline),
            title: const Text('Buscar no YouTube Music'),
            onTap: () {
              Navigator.pop(sheet);
              music.openService(false, '${track.title} ${track.artist}');
            },
          ),
        ],
      ),
    ),
  ),
);

Future<void> playlistPicker(
  BuildContext context,
  MusicController music,
  Track track,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (sheet) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheet).height * .65,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text(
              'Adicionar à playlist',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            for (final name in music.playlists.keys)
              ListTile(
                leading: const Icon(Icons.playlist_play_rounded),
                title: Text(name),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onTap: () {
                  music.addToPlaylist(name, track);
                  Navigator.pop(sheet);
                  message(context, 'Adicionada a $name');
                },
              ),
            ListTile(
              leading: const Icon(Icons.add_rounded),
              title: const Text('Nova playlist'),
              onTap: () async {
                Navigator.pop(sheet);
                final name = await newPlaylist(context, music);
                if (name != null) await music.addToPlaylist(name, track);
              },
            ),
          ],
        ),
      ),
    ),
  ),
);

Future<String?> newPlaylist(BuildContext context, MusicController music) async {
  final input = TextEditingController();
  final name = await showDialog<String>(
    context: context,
    builder: (dialog) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      title: const Text('Nova playlist'),
      content: TextField(
        controller: input,
        autofocus: true,
        maxLength: 50,
        decoration: const InputDecoration(hintText: 'Nome da playlist'),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) Navigator.pop(dialog, value.trim());
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (input.text.trim().isNotEmpty)
              Navigator.pop(dialog, input.text.trim());
          },
          child: const Text('Criar'),
        ),
      ],
    ),
  );
  // Dispose after the route's reverse animation has finished.
  Future.delayed(const Duration(seconds: 1), input.dispose);
  if (name != null) await music.createPlaylist(name);
  return name;
}

class FloatingMusicNavigation extends StatelessWidget {
  final MusicController music;
  final int activeIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onPlayer;
  const FloatingMusicNavigation({
    super.key,
    required this.music,
    required this.activeIndex,
    required this.onSelected,
    required this.onPlayer,
  });
  @override
  Widget build(BuildContext context) => Glass(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      child: Row(
        children: [
          for (final (i, label) in ['Início', 'Explorar', 'Biblioteca'].indexed)
            Expanded(
              child: Semantics(
                selected: activeIndex == i,
                button: true,
                label: label,
                child: InkWell(
                  onTap: () => onSelected(i),
                  borderRadius: BorderRadius.circular(28),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    decoration: BoxDecoration(
                      color: activeIndex == i
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
                            activeIndex == 0
                                ? Icons.home_rounded
                                : Icons.home_outlined,
                            Icons.search_rounded,
                            activeIndex == 2
                                ? Icons.library_music_rounded
                                : Icons.library_music_outlined,
                          ][i],
                          color: activeIndex == i
                              ? violet
                              : const Color(0xFF535574),
                          size: 23,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: activeIndex == i
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: activeIndex == i
                                ? violet
                                : const Color(0xFF535574),
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
            label: music.hasTracks
                ? 'Abrir player: ${music.current.title}'
                : 'Escolher uma música',
            child: InkWell(
              onTap: onPlayer,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Art(music.current.art, size: 43, radius: 15),
                    if (music.playing)
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

class EmptyLibrary extends StatelessWidget {
  final MusicController music;
  const EmptyLibrary({super.key, required this.music});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.library_music_outlined, color: violet, size: 54),
        const SizedBox(height: 18),
        const Text(
          'Suas músicas, do seu jeito.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        const Text(
          'Acesse as músicas do aparelho ou importe seus arquivos para começar.',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, height: 1.5),
        ),
        const SizedBox(height: 22),
        if (music.supportsDeviceLibrary)
          FilledButton.icon(
            onPressed: music.scanning ? null : music.requestDeviceMusic,
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('Acessar músicas do dispositivo'),
          ),
        TextButton.icon(
          onPressed: music.importAudio,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Importar músicas'),
        ),
      ],
    ),
  );
}
