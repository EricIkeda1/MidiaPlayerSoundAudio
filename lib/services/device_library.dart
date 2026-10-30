import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/track.dart';

class DeviceScan {
  final String status;
  final List<Track> tracks;
  const DeviceScan(this.status, this.tracks);
}

class DeviceLibrary {
  static const channel = MethodChannel('app.musica/device_library');
  static const events = EventChannel('app.musica/network_events');
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static Future<DeviceScan> scan({bool requestPermission = false}) async {
    if (!supported) return const DeviceScan('unsupported', []);
    final result = await channel.invokeMapMethod<String, dynamic>('scanMusic', {
      'requestPermission': requestPermission,
    });
    final rows = result?['tracks'] as List? ?? [];
    return DeviceScan(
      result?['status'] as String? ?? 'denied',
      rows
          .map((row) => Track.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList(),
    );
  }

  static Future<Map<String, dynamic>> preparePlayback({
    bool requestPermission = true,
  }) async {
    if (!supported) return {};
    try {
      return await channel.invokeMapMethod<String, dynamic>('preparePlayback', {
            'requestPermission': requestPermission,
          }) ??
          {};
    } on MissingPluginException {
      // Atualização parcial: o ícone do launcher já existe no manifesto do APK antigo.
      return {
        'iconValid': true,
        'iconResource': 'mipmap/ic_launcher',
        'allowed': false,
      };
    }
  }

  static Future<Map<String, dynamic>> notificationStatus() async {
    if (!supported) return {};
    try {
      return await channel.invokeMapMethod<String, dynamic>(
            'notificationStatus',
          ) ??
          {};
    } on MissingPluginException {
      return {
        'iconValid': true,
        'iconResource': 'mipmap/ic_launcher',
        'allowed': false,
      };
    }
  }

  static Future<void> openNotificationSettings() async {
    if (!supported) return;
    try {
      await channel.invokeMethod<void>('openNotificationSettings');
    } on MissingPluginException {
      await openSettings();
    }
  }

  static Future<void> openSettings() async {
    if (supported) await channel.invokeMethod<void>('openSettings');
  }

  static Future<void> openWifiSettings() async {
    if (supported) await channel.invokeMethod<void>('openWifiSettings');
  }

  static Future<bool> shareLyrics(String text) async {
    if (!supported) return false;
    await channel.invokeMethod<void>('shareLyrics', {'text': text});
    return true;
  }

  static Future<Map<String, dynamic>> network() async => supported
      ? Map<String, dynamic>.from(
          await channel.invokeMapMethod('networkStatus') ?? {},
        )
      : {};
  static Stream<Map<String, dynamic>> get networkChanges => supported
      ? events.receiveBroadcastStream().map(
          (row) => Map<String, dynamic>.from(row as Map),
        )
      : const Stream.empty();
}
