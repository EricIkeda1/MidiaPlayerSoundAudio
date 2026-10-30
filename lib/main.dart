import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'core/theme.dart';
import 'services/music_controller.dart';
import 'ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  if (!kIsWeb) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'app.musica.playback',
      androidNotificationChannelName: 'Reprodução de música',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'drawable/ic_stat_music',
    );
  }
  final music = MusicController();
  runApp(MusicApp(music: music));
  await music.initialize();
}

class MusicApp extends StatelessWidget {
  final MusicController music;
  const MusicApp({super.key, required this.music});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Música',
    debugShowCheckedModeBanner: false,
    theme: musicTheme(),
    builder: (context, child) {
      if (!kIsWeb) return child!;
      // Mantém o layout mobile da referência na janela do computador.
      return ColoredBox(
        color: const Color(0xFFE6E4F3),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: LayoutBuilder(
              builder: (context, constraints) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                ),
                child: child!,
              ),
            ),
          ),
        ),
      );
    },
    home: MusicShell(music: music),
  );
}
