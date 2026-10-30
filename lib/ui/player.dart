import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../models/track.dart';
import '../services/music_controller.dart';
import 'widgets.dart';
import 'secondary.dart';

class PlayerScreen extends StatelessWidget {
  final MusicController music;
  const PlayerScreen({super.key, required this.music});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: music,
    builder: (context, _) {
      final track = music.current;
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFC58BBA),
                  Color(0xFFA84B6E),
                  Color(0xFF3A293F),
                ],
                stops: [0, .48, 1],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, c) {
                  final cover = math.min(c.maxWidth - 60, c.maxHeight * .43);
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: c.maxHeight),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Voltar',
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: .16,
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextButton(
                                            onPressed: () => go(
                                              context,
                                              LyricsScreen(music: music),
                                            ),
                                            style: TextButton.styleFrom(
                                              foregroundColor: const Color(
                                                0xFF694575,
                                              ),
                                              backgroundColor: Colors.white
                                                  .withValues(alpha: .85),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 28,
                                                  ),
                                              minimumSize: const Size(0, 35),
                                            ),
                                            child: const Text('Letra'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                music.openService(false),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.white70,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                  ),
                                            ),
                                            child: const Text('Vídeo'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Opções',
                                  onPressed: () =>
                                      trackMenu(context, music, track),
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              width: cover,
                              height: cover,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .18),
                                    blurRadius: 35,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: Art(track.art, radius: 26),
                            ),
                            const SizedBox(height: 23),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        track.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 25,
                                          letterSpacing: -.6,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        track.artist,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Favoritar',
                                  onPressed: () => music.favorite(track),
                                  icon: Icon(
                                    music.favorites.contains(track.id)
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: const Color(0xFFFF719A),
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ProgressBar(music: music),
                            const SizedBox(height: 12),
                            PlaybackControls(music: music),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _action(
                                  Icons.playlist_add_rounded,
                                  'Adicionar',
                                  () => playlistPicker(context, music, track),
                                ),
                                _action(
                                  Icons.download_rounded,
                                  'Importar',
                                  music.importAudio,
                                ),
                                _action(
                                  Icons.lyrics_outlined,
                                  'Letras',
                                  () => go(context, LyricsScreen(music: music)),
                                ),
                                _action(
                                  Icons.queue_music_rounded,
                                  'Fila',
                                  () => go(context, QueueScreen(music: music)),
                                ),
                              ],
                            ),
                            if (!track.imported)
                              Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: InkWell(
                                  onTap: () => message(
                                    context,
                                    'O áudio é uma prévia instrumental original. Importe suas músicas para ouvir as gravações reais.',
                                  ),
                                  child: const Text(
                                    'Áudio de demonstração',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );
  Widget _action(IconData icon, String label, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(24),
    child: Padding(
      padding: const EdgeInsets.all(3),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .11),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white70, size: 23),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

// Texto visível na referência enviada pelo usuário; não é uma letra obtida de um serviço.
const referenceLyrics = '''[00:00.00]I said, ooh
[00:03.00]I’m blinded by the lights
[00:06.00]No, I can’t sleep
[00:09.00]until I feel your touch
[00:12.00]I said, ooh, I’m drowning in the night
[00:15.00]Oh, when I’m like this
[00:18.00]you’re the one I trust
[00:21.00]Hey, hey, hey''';

class LyricsScreen extends StatefulWidget {
  final MusicController music;
  const LyricsScreen({super.key, required this.music});
  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  double fontSize = 29;
  final scroll = ScrollController();
  String lastId = '';
  int previousLine = -1;
  final lineKeys = <int, GlobalKey>{};
  MusicController get m => widget.music;
  @override
  void initState() {
    super.initState();
    m.addListener(_update);
  }

  void _update() {
    if (!mounted) return;
    setState(() {});
    final lines = _lines();
    final active = _active(lines);
    if (lastId != m.current.id) {
      lineKeys.clear();
      previousLine = -1;
      lastId = m.current.id;
    }
    if (active != previousLine) {
      previousLine = active;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = lineKeys[active]?.currentContext;
        if (target != null)
          Scrollable.ensureVisible(
            target,
            alignment: .22,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
          );
      });
    }
  }

  List<LyricLine> _lines() => parseLrc(
    m.current.lyrics ?? (m.current.id == 'blinding' ? referenceLyrics : ''),
  );
  int _active(List<LyricLine> lines) {
    var result = 0;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].time <= m.position) result = i;
    }
    return result;
  }

  @override
  void dispose() {
    m.removeListener(_update);
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = m.current, lines = _lines();
    final plain = track.lyrics != null && lines.isEmpty ? track.lyrics : null;
    final active = _active(lines);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFCE7EF), Color(0xFFF4D0E5), Color(0xFFDCD9FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 12, 3),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Voltar',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Art(track.art, size: 40, radius: 9),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            track.artist,
                            style: const TextStyle(fontSize: 11, color: muted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Importar letra',
                      onPressed: m.importLyrics,
                      icon: const Icon(Icons.more_vert_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .25),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .7),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Center(
                            child: Text(
                              'Letra',
                              style: TextStyle(
                                color: violet,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () => m.openService(false),
                          child: const Text(
                            'Vídeo',
                            style: TextStyle(color: muted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: lines.isEmpty && plain == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lyrics_outlined,
                                size: 48,
                                color: violet,
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Essa música ainda não tem letra.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: m.importLyrics,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Importar .lrc ou .txt'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        controller: scroll,
                        padding: const EdgeInsets.fromLTRB(28, 10, 28, 50),
                        children: [
                          if (plain != null)
                            Text(
                              plain,
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w700,
                                height: 1.5,
                              ),
                            )
                          else
                            for (final (i, line) in lines.indexed)
                              Padding(
                                key: lineKeys.putIfAbsent(i, () => GlobalKey()),
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () => m.seek(
                                    line.time.inMilliseconds.toDouble(),
                                  ),
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 250),
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w700,
                                      height: 1.28,
                                      letterSpacing: -.7,
                                      color: i == active
                                          ? ink
                                          : const Color(0xFF9B879F),
                                    ),
                                    child: Text(line.text),
                                  ),
                                ),
                              ),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
                child: Glass(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          tooltip: 'Tamanho da letra',
                          onPressed: () => setState(
                            () => fontSize = fontSize == 29
                                ? 35
                                : fontSize == 35
                                ? 24
                                : 29,
                          ),
                          icon: const Icon(Icons.text_fields_rounded),
                        ),
                        IconButton(
                          tooltip: 'Copiar letra',
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(
                                text:
                                    plain ??
                                    lines.map((l) => l.text).join('\n'),
                              ),
                            );
                            message(context, 'Letra copiada');
                          },
                          icon: const Icon(Icons.copy_rounded, size: 22),
                        ),
                        IconButton(
                          tooltip: 'Reproduzir ou pausar',
                          onPressed: m.toggle,
                          icon: Icon(
                            m.playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Timer',
                          onPressed: () => sleepMenu(context, m),
                          icon: Icon(
                            Icons.timer_outlined,
                            color: m.sleepUntil == null ? ink : violet,
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
      ),
    );
  }
}

void sleepMenu(BuildContext context, MusicController music) =>
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Timer de sono',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              for (final min in [15, 30, 45, 60])
                ListTile(
                  leading: const Icon(Icons.bedtime_outlined),
                  title: Text('Parar em $min minutos'),
                  onTap: () {
                    music.sleep(min);
                    Navigator.pop(sheet);
                    message(context, 'Timer de $min minutos ativado');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.timer_off_outlined),
                title: const Text('Desativar timer'),
                onTap: () {
                  music.sleep(null);
                  Navigator.pop(sheet);
                },
              ),
            ],
          ),
        ),
      ),
    );
