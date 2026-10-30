package app.musica.musica

import android.Manifest
import android.app.NotificationManager
import android.content.ContentUris
import android.content.Intent
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : AudioServiceActivity() {
    private val worker = Executors.newSingleThreadExecutor()
    private var pendingScan: MethodChannel.Result? = null
    private var networkCallback: ConnectivityManager.NetworkCallback? = null
    private val permissionCode = 5041
    private val notificationCode = 5042
    private var pendingNotification: MethodChannel.Result? = null
    private val audioPermission: String
        get() = if (Build.VERSION.SDK_INT >= 33) Manifest.permission.READ_MEDIA_AUDIO
                else Manifest.permission.READ_EXTERNAL_STORAGE

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.musica/device_library")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "notificationStatus" -> result.success(notificationState())
                    "preparePlayback" -> {
                        val asked = getPreferences(MODE_PRIVATE).getBoolean("askedNotifications", false)
                        if (Build.VERSION.SDK_INT >= 33 && call.argument<Boolean>("requestPermission") != false &&
                            !asked && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            if (pendingNotification != null) result.error("BUSY", "Autorização em andamento.", null)
                            else {
                                pendingNotification = result
                                getPreferences(MODE_PRIVATE).edit().putBoolean("askedNotifications", true).apply()
                                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), notificationCode)
                            }
                        } else result.success(notificationState())
                    }
                    "openNotificationSettings" -> {
                        if (Build.VERSION.SDK_INT >= 26) startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                            .putExtra(Settings.EXTRA_APP_PACKAGE, packageName))
                        else startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")))
                        result.success(null)
                    }
                    "scanMusic" -> {
                        if (pendingScan != null) {
                            result.error("BUSY", "Uma leitura já está em andamento.", null)
                        } else if (checkSelfPermission(audioPermission) == PackageManager.PERMISSION_GRANTED) {
                            scanMusic(result)
                        } else if (call.argument<Boolean>("requestPermission") == true) {
                            pendingScan = result
                            getPreferences(MODE_PRIVATE).edit().putBoolean("askedAudio", true).apply()
                            requestPermissions(arrayOf(audioPermission), permissionCode)
                        } else {
                            result.success(mapOf("status" to permissionStatus(), "tracks" to emptyList<Any>()))
                        }
                    }
                    "openSettings" -> {
                        startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.parse("package:$packageName")))
                        result.success(null)
                    }
                    "openWifiSettings" -> {
                        val action = if (Build.VERSION.SDK_INT >= 29) Settings.Panel.ACTION_INTERNET_CONNECTIVITY else Settings.ACTION_WIFI_SETTINGS
                        startActivity(Intent(action))
                        result.success(null)
                    }
                    "shareLyrics" -> {
                        val share = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, call.argument<String>("text") ?: "")
                        }
                        startActivity(Intent.createChooser(share, "Compartilhar letra"))
                        result.success(null)
                    }
                    "networkStatus" -> result.success(networkStatus())
                    "audioExtension" -> {
                        val source = call.argument<String>("source")
                        try {
                            val mime = if (source?.startsWith("content://media/") == true) contentResolver.getType(Uri.parse(source)) else null
                            result.success(when(mime) {
                                "audio/mpeg" -> "mp3"
                                "audio/mp4", "audio/x-m4a" -> "m4a"
                                "audio/wav", "audio/x-wav" -> "wav"
                                "audio/ogg", "application/ogg" -> "ogg"
                                "audio/flac", "audio/x-flac" -> "flac"
                                "audio/aac" -> "aac"
                                else -> "audio"
                            })
                        } catch (_: Exception) { result.success("audio") }
                    }
                    "readAudio" -> {
                        val source = call.argument<String>("source")
                        if (source == null || !source.startsWith("content://media/")) {
                            result.error("INVALID_URI", "Áudio inválido.", null)
                        } else worker.execute {
                            try {
                                val bytes = contentResolver.openInputStream(Uri.parse(source))?.use { it.readBytes() }
                                    ?: throw IllegalStateException("Arquivo indisponível")
                                runOnUiThread { result.success(bytes) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("READ_FAILED", "Não foi possível ler este áudio.", null) }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "app.musica/network_events")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    val manager = getSystemService(CONNECTIVITY_SERVICE) as ConnectivityManager
                    fun publish() { runOnUiThread { events.success(networkStatus()) } }
                    networkCallback = object : ConnectivityManager.NetworkCallback() {
                        override fun onAvailable(network: Network) = publish()
                        override fun onLost(network: Network) = publish()
                        override fun onCapabilitiesChanged(network: Network, caps: NetworkCapabilities) = publish()
                    }
                    manager.registerDefaultNetworkCallback(networkCallback!!)
                    publish()
                }
                override fun onCancel(arguments: Any?) { stopNetworkCallback() }
            })
    }

    private fun permissionStatus(): String {
        val asked = getPreferences(MODE_PRIVATE).getBoolean("askedAudio", false)
        return if (!asked) "notRequested"
            else if (shouldShowRequestPermissionRationale(audioPermission)) "denied"
            else "permanentlyDenied"
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == notificationCode) {
            pendingNotification?.success(notificationState())
            pendingNotification = null
            return
        }
        if (requestCode != permissionCode) return
        val result = pendingScan ?: return
        pendingScan = null
        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            scanMusic(result)
        } else {
            result.success(mapOf("status" to permissionStatus(), "tracks" to emptyList<Any>()))
        }
    }

    private fun scanMusic(result: MethodChannel.Result) {
        worker.execute {
            try {
                val tracks = mutableListOf<Map<String, Any>>()
                val uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                val columns = arrayOf(MediaStore.Audio.Media._ID, MediaStore.Audio.Media.TITLE,
                    MediaStore.Audio.Media.ARTIST, MediaStore.Audio.Media.ALBUM,
                    MediaStore.Audio.Media.DISPLAY_NAME)
                contentResolver.query(uri, columns, "${MediaStore.Audio.Media.IS_MUSIC} != 0", null,
                    "${MediaStore.Audio.Media.TITLE} COLLATE NOCASE ASC")?.use { cursor ->
                    while (cursor.moveToNext()) {
                        val id = cursor.getLong(0)
                        fun label(index: Int, fallback: String): String = cursor.getString(index)
                            ?.takeUnless { it.isBlank() || it == "<unknown>" } ?: fallback
                        tracks.add(mapOf("id" to "device:$id", "title" to label(1, label(4, "Música")),
                            "artist" to label(2, "Artista desconhecido"), "album" to label(3, "No dispositivo"),
                            "art" to "icon", "source" to ContentUris.withAppendedId(uri, id).toString(), "imported" to true))
                    }
                }
                runOnUiThread { result.success(mapOf("status" to "granted", "tracks" to tracks)) }
            } catch (e: SecurityException) {
                runOnUiThread { result.success(mapOf("status" to "denied", "tracks" to emptyList<Any>())) }
            } catch (e: Exception) {
                runOnUiThread { result.error("SCAN_FAILED", "Não foi possível consultar as músicas.", null) }
            }
        }
    }

    private fun notificationState(): Map<String, Any> {
        // Referências estáticas e keep.xml preservam estes recursos no APK.
        val primary = R.drawable.ic_stat_music
        val launcher = R.mipmap.ic_launcher
        val primaryFound = resources.getIdentifier("ic_stat_music", "drawable", packageName) == primary && primary != 0
        val fallbackFound = resources.getIdentifier("ic_launcher", "mipmap", packageName) == launcher && launcher != 0
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        val channelAllowed = Build.VERSION.SDK_INT < 26 || manager.getNotificationChannel("app.musica.playback")?.importance != NotificationManager.IMPORTANCE_NONE
        return mapOf("allowed" to (manager.areNotificationsEnabled() && channelAllowed),
            "iconValid" to (primaryFound || fallbackFound),
            "iconResource" to if (primaryFound) "drawable/ic_stat_music" else "mipmap/ic_launcher")
    }

    private fun networkStatus(): Map<String, Any> {
        val manager = getSystemService(CONNECTIVITY_SERVICE) as ConnectivityManager
        val caps = manager.getNetworkCapabilities(manager.activeNetwork)
        return mapOf("connected" to (caps != null),
            "internet" to (caps?.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED) == true),
            "wifi" to (caps?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true))
    }

    private fun stopNetworkCallback() {
        networkCallback?.let { callback ->
            try { (getSystemService(CONNECTIVITY_SERVICE) as ConnectivityManager).unregisterNetworkCallback(callback) }
            catch (_: Exception) { }
        }
        networkCallback = null
    }

    override fun onDestroy() {
        stopNetworkCallback()
        pendingScan?.error("CANCELLED", "Leitura cancelada.", null)
        pendingScan = null
        pendingNotification?.error("CANCELLED", "Autorização cancelada.", null)
        pendingNotification = null
        worker.shutdown()
        super.onDestroy()
    }
}
