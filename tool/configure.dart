import 'dart:io';

/// Configuração idempotente dos projetos nativos após flutter create.
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (manifest.existsSync()) {
    var xml = manifest.readAsStringSync();
    const permissions = {
      'INTERNET': '',
      'ACCESS_NETWORK_STATE': '',
      'ACCESS_WIFI_STATE': '',
      'READ_MEDIA_AUDIO': '',
      'READ_EXTERNAL_STORAGE': ' android:maxSdkVersion="32"',
      'WAKE_LOCK': '',
      'FOREGROUND_SERVICE': '',
      'FOREGROUND_SERVICE_MEDIA_PLAYBACK': '',
      'POST_NOTIFICATIONS': '',
    };
    for (final entry in permissions.entries) {
      final permission = 'android.permission.${entry.key}';
      if (!xml.contains('android:name="$permission"')) {
        xml = xml.replaceFirst(
          '<application',
          '<uses-permission android:name="$permission"${entry.value} />\n    <application',
        );
      }
    }
    xml = xml.replaceFirst(
      RegExp(r'android:label="[^"]*"'),
      'android:label="Música"',
    );
    if (!xml.contains('com.ryanheise.audioservice.AudioService"')) {
      xml = xml.replaceFirst('</application>', '''
        <service android:name="com.ryanheise.audioservice.AudioService"
            android:foregroundServiceType="mediaPlayback" android:exported="true">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService" />
            </intent-filter>
        </service>
        <receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver" android:exported="true">
            <intent-filter><action android:name="android.intent.action.MEDIA_BUTTON" /></intent-filter>
        </receiver>
    </application>''');
    }
    manifest.writeAsStringSync(xml);
    for (final file in Directory(
      'android/app/src/main/kotlin',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('MainActivity.kt')) continue;
      file.writeAsStringSync(
        file
            .readAsStringSync()
            .replaceAll(
              'import io.flutter.embedding.android.FlutterActivity',
              'import com.ryanheise.audioservice.AudioServiceActivity',
            )
            .replaceAll('FlutterActivity()', 'AudioServiceActivity()'),
      );
    }
    final gradle = File('android/app/build.gradle.kts');
    if (gradle.existsSync()) {
      gradle.writeAsStringSync(
        gradle.readAsStringSync().replaceAll(
          'minSdk = flutter.minSdkVersion',
          'minSdk = 24',
        ),
      );
    }
    final res = Directory('android/app/src/main/res/drawable');
    res.createSync(recursive: true);
    File('${res.path}/ic_stat_music.xml').writeAsStringSync('''
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#FFFFFFFF" android:pathData="M12,3v10.55A4,4 0,1 0,14 17V7h4V3z" />
</vector>''');
  }
  final keepDirectory = Directory('android/app/src/main/res/raw')
    ..createSync(recursive: true);
  File('${keepDirectory.path}/keep.xml').writeAsStringSync(
    '<resources xmlns:tools="http://schemas.android.com/tools" tools:keep="@drawable/ic_stat_music,@drawable/audio_service_*,@mipmap/ic_launcher" />',
  );
  final plist = File('ios/Runner/Info.plist');
  if (plist.existsSync()) {
    var text = plist.readAsStringSync().replaceAll(
      '<string>musica</string>',
      '<string>Música</string>',
    );
    text = text.replaceAll(
      '<string>Musica</string>',
      '<string>Música</string>',
    );
    if (!text.contains('<key>UIBackgroundModes</key>')) {
      final rootEnd = text.lastIndexOf('</dict>');
      text = text.replaceRange(
        rootEnd,
        rootEnd,
        '<key>UIBackgroundModes</key>\n<array><string>audio</string></array>\n',
      );
    }
    plist.writeAsStringSync(text);
  }
  final sample = File('test/widget_test.dart');
  if (sample.existsSync() && sample.readAsStringSync().contains('MyApp'))
    sample.deleteSync();
  print('Configurações nativas de Música prontas.');
}
