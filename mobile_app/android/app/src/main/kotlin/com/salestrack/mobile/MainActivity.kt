package com.salestrack.mobile

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "MainActivity"
        private const val METHOD_CHANNEL = "com.salestrack.mobile/call_recorder"
        private const val EVENT_CHANNEL = "com.salestrack.mobile/call_events"
        private const val PERMISSION_REQUEST_CODE = 100
    }

    private var pendingPermissionResult: MethodChannel.Result? = null
    private var eventSink: EventChannel.EventSink? = null
    private var callEventHandler: Handler? = null
    private var callEventRunnable: Runnable? = null
    private var lastEventTimestamp: Long = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method channel for commands from Flutter
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermissions" -> requestCallPermissions(result)
                "checkPermissions" -> checkCallPermissions(result)
                "getLastCallEvent" -> getLastCallEvent(result)
                "getRecordingsDir" -> getRecordingsDir(result)
                "getCallRecordings" -> getCallRecordings(result)
                "startMonitoring" -> {
                    startCallMonitorService()
                    result.success(true)
                }
                "stopMonitoring" -> {
                    stopCallMonitorService()
                    result.success(true)
                }
                "deleteRecording" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        val file = File(path)
                        result.success(file.exists() && file.delete())
                    } else {
                        result.error("INVALID_ARGS", "Path required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Event channel for streaming call events to Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    startPollingCallEvents()
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    stopPollingCallEvents()
                }
            }
        )

        // Start the persistent call monitor service
        startCallMonitorService()
    }

    private fun startCallMonitorService() {
        val intent = Intent(this, CallMonitorService::class.java).apply {
            action = CallMonitorService.ACTION_START
        }
        startForegroundService(intent)
        Log.d(TAG, "CallMonitorService start requested")
    }

    private fun stopCallMonitorService() {
        val intent = Intent(this, CallMonitorService::class.java).apply {
            action = CallMonitorService.ACTION_STOP
        }
        startService(intent)
        Log.d(TAG, "CallMonitorService stop requested")
    }

    private fun requestCallPermissions(result: MethodChannel.Result) {
        val permissions = arrayOf(
            Manifest.permission.RECORD_AUDIO,
            Manifest.permission.READ_PHONE_STATE,
            Manifest.permission.READ_CALL_LOG,
            Manifest.permission.PROCESS_OUTGOING_CALLS
        )

        val notGranted = permissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        if (notGranted.isEmpty()) {
            result.success(true)
            return
        }

        pendingPermissionResult = result
        ActivityCompat.requestPermissions(this, notGranted.toTypedArray(), PERMISSION_REQUEST_CODE)
    }

    private fun checkCallPermissions(result: MethodChannel.Result) {
        val permissions = mapOf(
            "record_audio" to Manifest.permission.RECORD_AUDIO,
            "read_phone_state" to Manifest.permission.READ_PHONE_STATE,
            "read_call_log" to Manifest.permission.READ_CALL_LOG,
        )

        val status = permissions.mapValues { (_, perm) ->
            ContextCompat.checkSelfPermission(this, perm) == PackageManager.PERMISSION_GRANTED
        }

        result.success(status)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingPermissionResult?.success(allGranted)
            pendingPermissionResult = null
        }
    }

    private fun getLastCallEvent(result: MethodChannel.Result) {
        val prefs = getSharedPreferences("call_events", Context.MODE_PRIVATE)
        val event = prefs.getString("last_event", null)
        if (event == null) {
            result.success(null)
            return
        }

        val map = mapOf(
            "event" to event,
            "phoneNumber" to prefs.getString("last_number", "Unknown"),
            "isIncoming" to prefs.getBoolean("last_incoming", false),
            "recordingPath" to prefs.getString("last_recording_path", null),
            "duration" to prefs.getInt("last_duration", 0),
            "timestamp" to prefs.getLong("last_timestamp", 0),
            "error" to prefs.getString("last_error", null),
        )
        result.success(map)
    }

    private fun getRecordingsDir(result: MethodChannel.Result) {
        val dir = File(getExternalFilesDir(null), "recordings")
        if (!dir.exists()) dir.mkdirs()
        result.success(dir.absolutePath)
    }

    private fun getCallRecordings(result: MethodChannel.Result) {
        val dir = File(getExternalFilesDir(null), "recordings")
        if (!dir.exists()) {
            result.success(emptyList<Map<String, Any>>())
            return
        }

        val recordings = dir.listFiles()
            ?.filter { it.isFile && it.extension == "mp4" }
            ?.sortedByDescending { it.lastModified() }
            ?.map { file ->
                mapOf(
                    "path" to file.absolutePath,
                    "name" to file.name,
                    "size" to file.length(),
                    "modified" to file.lastModified(),
                )
            } ?: emptyList()

        result.success(recordings)
    }

    /** Poll SharedPreferences for new call events from the native service. */
    private fun startPollingCallEvents() {
        callEventHandler = Handler(Looper.getMainLooper())
        callEventRunnable = object : Runnable {
            override fun run() {
                checkForNewCallEvent()
                callEventHandler?.postDelayed(this, 1000)
            }
        }
        callEventHandler?.post(callEventRunnable!!)
    }

    private fun stopPollingCallEvents() {
        callEventRunnable?.let { callEventHandler?.removeCallbacks(it) }
        callEventHandler = null
        callEventRunnable = null
    }

    private fun checkForNewCallEvent() {
        val prefs = getSharedPreferences("call_events", Context.MODE_PRIVATE)
        val timestamp = prefs.getLong("last_timestamp", 0)

        if (timestamp > lastEventTimestamp) {
            lastEventTimestamp = timestamp
            val event = prefs.getString("last_event", null) ?: return

            val map = mapOf(
                "event" to event,
                "phoneNumber" to (prefs.getString("last_number", "Unknown") ?: "Unknown"),
                "isIncoming" to prefs.getBoolean("last_incoming", false),
                "recordingPath" to prefs.getString("last_recording_path", null),
                "duration" to prefs.getInt("last_duration", 0),
                "timestamp" to timestamp,
                "error" to prefs.getString("last_error", null),
            )

            eventSink?.success(map)
            Log.d(TAG, "Event sent to Flutter: $event")
        }
    }

    override fun onDestroy() {
        stopPollingCallEvents()
        // Note: NOT stopping CallMonitorService — it should survive activity death
        super.onDestroy()
    }
}
