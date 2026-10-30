import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/music_controller.dart';
import 'widgets.dart';

class SystemPreview extends StatefulWidget {
  final MusicController music;
  final bool lockScreen;
  const SystemPreview({
    super.key,
    required this.music,
    required this.lockScreen,
  });
  @override
  State<SystemPreview> createState() => _SystemPreviewState();
}

class _SystemPreviewState extends State<SystemPreview> {
  double brightness = .5;
  final enabled = <int>{0, 2};
  MusicController get m => widget.music;
  bool get lock => widget.lockScreen;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: m,
    builder: (context, _) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: lock
                  ? const [
                      Color(0xFF6554E6),
                      Color(0xFFC19FEC),
                      Color(0xFFF5B4AD),
                      Color(0xFF8F6DCF),
                    ]
                  : const [
                      Color(0xFF354656),
                      Color(0xFF596A7A),
                      Color(0xFF3E485C),
                    ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                if (lock) ...[
                  Positioned(
                    left: -90,
                    right: -100,
                    top: 245,
                    height: 450,
                    child: Transform.rotate(
                      angle: -.3,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(190),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFB69BE9), Color(0xFFEDACB7)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -130,
                    bottom: -150,
                    width: 500,
                    height: 400,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFD389C7), Color(0xFF735DC2)],
                        ),
                      ),
                    ),
                  ),
                ],
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 90),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Voltar',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            lock
                                ? 'Prévia • Tela bloqueada'
                                : 'Prévia • Notificação',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Sobre a prévia',
                          onPressed: () => message(
                            context,
                            'Esta é uma prévia dentro do app. A aparência da notificação real depende do seu aparelho.',
                          ),
                          icon: const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    if (lock) ...[
                      const SizedBox(height: 28),
                      const Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '9:41',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                          fontSize: 78,
                          letterSpacing: -3,
                        ),
                      ),
                      const Text(
                        'Segunda-feira, 26 de outubro',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      const SizedBox(height: 80),
                    ] else ...[
                      const SizedBox(height: 8),
                      const Text(
                        '9:41  Seg, 26 de outubro',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final (i, icon) in [
                            Icons.wifi_rounded,
                            Icons.bluetooth_rounded,
                            Icons.volume_up_rounded,
                            Icons.vibration_rounded,
                            Icons.screen_share_outlined,
                          ].indexed)
                            InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () => setState(() {
                                if (!enabled.add(i)) enabled.remove(i);
                              }),
                              child: CircleAvatar(
                                radius: 25,
                                backgroundColor: enabled.contains(i)
                                    ? const Color(0xFF3C6BFF)
                                    : Colors.white.withValues(alpha: .13),
                                child: Icon(
                                  icon,
                                  color: Colors.white,
                                  size: 23,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Glass(
                        radius: 30,
                        color: Colors.white.withValues(alpha: .2),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 15),
                              child: Icon(
                                Icons.brightness_6_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: brightness,
                                onChanged: (v) =>
                                    setState(() => brightness = v),
                                activeColor: Colors.white70,
                                inactiveColor: Colors.white24,
                                thumbColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _mediaCard(context),
                    if (!lock) ...[
                      const SizedBox(height: 12),
                      _serviceRow(true),
                      const SizedBox(height: 10),
                      _serviceRow(false),
                      const SizedBox(height: 22),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white24),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Fechar prévia'),
                        ),
                      ),
                    ],
                  ],
                ),
                if (lock)
                  Positioned(
                    bottom: 30,
                    left: 24,
                    right: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _shortcut(
                          Icons.flashlight_on_rounded,
                          'Atalho ilustrativo da lanterna',
                        ),
                        _shortcut(
                          Icons.camera_alt_rounded,
                          'Atalho ilustrativo da câmera',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Widget _shortcut(IconData icon, String text) => IconButton.filled(
    style: IconButton.styleFrom(
      backgroundColor: Colors.black.withValues(alpha: .18),
      padding: const EdgeInsets.all(17),
    ),
    tooltip: text,
    onPressed: () => message(context, text),
    icon: Icon(icon, color: Colors.white),
  );
  Widget _mediaCard(BuildContext context) => Glass(
    radius: 28,
    color: lock ? const Color(0x886C3657) : Colors.white.withValues(alpha: .13),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Art(m.current.art, size: 67, radius: 12),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Música',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      m.current.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.current.artist,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!lock)
                IconButton(
                  tooltip: 'Fechar prévia',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.white54,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          ProgressBar(music: m),
          PlaybackControls(music: m, compact: true),
        ],
      ),
    ),
  );
  Widget _serviceRow(bool spotify) => Glass(
    radius: 24,
    color: Colors.white.withValues(alpha: .7),
    child: ListTile(
      dense: true,
      onTap: () => m.openService(spotify),
      leading: CircleAvatar(
        backgroundColor: spotify ? const Color(0xFF00C868) : Colors.red,
        child: Icon(
          spotify ? Icons.graphic_eq : Icons.play_circle_outline,
          color: Colors.white,
        ),
      ),
      title: Text(
        spotify ? 'Continuar no Spotify' : 'Abrir no YouTube Music',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      subtitle: const Text(
        'Abrir pesquisa no serviço',
        style: TextStyle(fontSize: 10),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 19),
    ),
  );
}
