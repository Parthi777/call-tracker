package com.salestrack.mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.Cursor
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.CallLog
import android.telephony.TelephonyCallback
import android.telephony.TelephonyManager
import android.util.Log
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Persistent foreground service that monitors call state AND records audio.
 * Also polls the Android Call Log to catch calls that happened while
 * the process was killed (common on Android 14+/16).
 */
class CallMonitorService : Service() {

    companion object {
        const val TAG = "CallMonitorService"
        const val ACTION_START = "com.salestrack.mobile.ACTION_START_MONITOR"
        const val ACTION_STOP = "com.salestrack.mobile.ACTION_STOP_MONITOR"

        private const val CHANNEL_ID = "call_monitor_channel"
        private const val NOTIFICATION_ID = 2001
        private const val CALL_LOG_POLL_INTERVAL = 5000L // 5 seconds
    }

    private var telephonyCallback: TelephonyCallback? = null
    private var outgoingCallReceiver: BroadcastReceiver? = null

    private var lastCallState = TelephonyManager.CALL_STATE_IDLE
    private var isIncomingCall = false
    private var savedPhoneNumber: String? = null

    // Recording state
    private var mediaRecorder: MediaRecorder? = null
    private var isRecording = false
    private var outputFile: String? = null
    private var callStartTime: Long = 0

    // Call log polling
    private var callLogHandler: Handler? = null
    private var callLogRunnable: Runnable? = null
    private var lastProcessedCallTimestamp: Long = 0

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()

        // Load last processed timestamp so we don't re-process old calls
        val prefs = getSharedPreferences("call_monitor", Context.MODE_PRIVATE)
        lastProcessedCallTimestamp = prefs.getLong("last_call_log_ts", System.currentTimeMillis())

        Log.d(TAG, "CallMonitorService created, lastProcessedCallTimestamp=$lastProcessedCallTimestamp")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                if (isRecording) stopRecording()
                unregisterListeners()
                stopCallLogPolling()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            else -> {
                startForeground(NOTIFICATION_ID, buildNotification("Monitoring calls..."))
                registerCallStateListener()
                registerOutgoingCallReceiver()
                startCallLogPolling()
            }
        }
        return START_STICKY
    }

    // ==================== CALL STATE LISTENER (real-time) ====================

    private fun registerCallStateListener() {
        if (telephonyCallback != null) return

        val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val callback = object : TelephonyCallback(), TelephonyCallback.CallStateListener {
                override fun onCallStateChanged(state: Int) {
                    handleCallStateChange(state)
                }
            }
            telephonyCallback = callback
            try {
                telephonyManager.registerTelephonyCallback(mainExecutor, callback)
                Log.d(TAG, "TelephonyCallback registered")
            } catch (e: SecurityException) {
                Log.e(TAG, "Failed to register TelephonyCallback", e)
            }
        }
    }

    private fun registerOutgoingCallReceiver() {
        if (outgoingCallReceiver != null) return

        outgoingCallReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                when (intent.action) {
                    Intent.ACTION_NEW_OUTGOING_CALL -> {
                        savedPhoneNumber = intent.getStringExtra(Intent.EXTRA_PHONE_NUMBER)
                        isIncomingCall = false
                        Log.d(TAG, "Outgoing call to: $savedPhoneNumber")
                    }
                    TelephonyManager.ACTION_PHONE_STATE_CHANGED -> {
                        val number = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
                        if (number != null) {
                            savedPhoneNumber = number
                            Log.d(TAG, "Incoming number: $number")
                        }
                    }
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_NEW_OUTGOING_CALL)
            addAction(TelephonyManager.ACTION_PHONE_STATE_CHANGED)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(outgoingCallReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(outgoingCallReceiver, filter)
        }
        Log.d(TAG, "Outgoing call receiver registered")
    }

    private fun handleCallStateChange(state: Int) {
        if (state == lastCallState) return

        Log.d(TAG, "Call state: $lastCallState -> $state, number=$savedPhoneNumber, incoming=$isIncomingCall")

        when (state) {
            TelephonyManager.CALL_STATE_RINGING -> {
                isIncomingCall = true
            }
            TelephonyManager.CALL_STATE_OFFHOOK -> {
                if (lastCallState == TelephonyManager.CALL_STATE_RINGING) {
                    isIncomingCall = true
                } else if (lastCallState == TelephonyManager.CALL_STATE_IDLE) {
                    isIncomingCall = false
                }
                val nm = getSystemService(NotificationManager::class.java)
                val dir = if (isIncomingCall) "incoming" else "outgoing"
                nm.notify(NOTIFICATION_ID, buildNotification("Recording $dir call..."))
                startRecording()
            }
            TelephonyManager.CALL_STATE_IDLE -> {
                if (lastCallState == TelephonyManager.CALL_STATE_OFFHOOK) {
                    stopRecording()
                } else if (lastCallState == TelephonyManager.CALL_STATE_RINGING) {
                    saveCallEvent("missed", duration = 0)
                }
                val nm = getSystemService(NotificationManager::class.java)
                nm.notify(NOTIFICATION_ID, buildNotification("Monitoring calls..."))
            }
        }
        lastCallState = state
    }

    // ==================== RECORDING ====================

    private fun startRecording() {
        if (isRecording) return
        callStartTime = System.currentTimeMillis()

        try {
            val recordingsDir = File(getExternalFilesDir(null), "recordings")
            if (!recordingsDir.exists()) recordingsDir.mkdirs()

            val dateFormat = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US)
            val timestamp = dateFormat.format(Date())
            val direction = if (isIncomingCall) "IN" else "OUT"
            val sanitizedNumber = (savedPhoneNumber ?: "Unknown").replace(Regex("[^\\d+]"), "")
            val fileName = "${timestamp}_${direction}_${sanitizedNumber}.mp4"

            outputFile = File(recordingsDir, fileName).absolutePath

            mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(this)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }

            mediaRecorder?.apply {
                setAudioSource(MediaRecorder.AudioSource.VOICE_COMMUNICATION)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setAudioEncodingBitRate(128000)
                setAudioSamplingRate(44100)
                setOutputFile(outputFile)
                prepare()
                start()
            }

            isRecording = true
            Log.d(TAG, "Recording started: $outputFile")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start recording", e)
            isRecording = false
            mediaRecorder?.release()
            mediaRecorder = null
        }
    }

    private fun stopRecording() {
        val durationMs = System.currentTimeMillis() - callStartTime
        val durationSeconds = (durationMs / 1000).toInt()

        if (isRecording) {
            try {
                mediaRecorder?.apply { stop(); release() }
                Log.d(TAG, "Recording stopped: $outputFile (${durationSeconds}s)")
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping recording", e)
            } finally {
                mediaRecorder = null
                isRecording = false
            }
        }
        saveCallEvent("call_recorded", duration = durationSeconds)
    }

    // ==================== CALL LOG POLLING (fallback) ====================

    private fun startCallLogPolling() {
        if (callLogHandler != null) return
        callLogHandler = Handler(Looper.getMainLooper())
        callLogRunnable = object : Runnable {
            override fun run() {
                pollCallLog()
                callLogHandler?.postDelayed(this, CALL_LOG_POLL_INTERVAL)
            }
        }
        // First poll after 3 seconds to catch calls missed during process restart
        callLogHandler?.postDelayed(callLogRunnable!!, 3000)
        Log.d(TAG, "Call log polling started")
    }

    private fun stopCallLogPolling() {
        callLogRunnable?.let { callLogHandler?.removeCallbacks(it) }
        callLogHandler = null
        callLogRunnable = null
    }

    /**
     * Read the Android Call Log for calls newer than lastProcessedCallTimestamp.
     * This catches calls that happened while the process was killed.
     */
    private fun pollCallLog() {
        try {
            val cursor: Cursor? = contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(
                    CallLog.Calls.NUMBER,
                    CallLog.Calls.TYPE,
                    CallLog.Calls.DURATION,
                    CallLog.Calls.DATE,
                ),
                "${CallLog.Calls.DATE} > ?",
                arrayOf(lastProcessedCallTimestamp.toString()),
                "${CallLog.Calls.DATE} ASC"
            )

            cursor?.use {
                while (it.moveToNext()) {
                    val number = it.getString(0) ?: "Unknown"
                    val type = it.getInt(1)
                    val duration = it.getInt(2)
                    val date = it.getLong(3)

                    // Skip if this is the current active call (state != IDLE)
                    if (lastCallState != TelephonyManager.CALL_STATE_IDLE) continue

                    val isIncoming = type == CallLog.Calls.INCOMING_TYPE || type == CallLog.Calls.MISSED_TYPE
                    val isMissed = type == CallLog.Calls.MISSED_TYPE
                    val event = if (isMissed) "missed" else "call_recorded"

                    Log.d(TAG, "Call log entry: number=$number, type=$type, duration=$duration, date=$date")

                    // Check if we already have this event (avoid duplicates)
                    val prefs = getSharedPreferences("call_events", Context.MODE_PRIVATE)
                    val lastTs = prefs.getLong("last_timestamp", 0)
                    // Use a tolerance of 10 seconds to avoid duplicate detection
                    if (Math.abs(lastTs - date) < 10000) {
                        Log.d(TAG, "Skipping duplicate call log entry (already processed via real-time)")
                        lastProcessedCallTimestamp = date
                        continue
                    }

                    // Save this as a call event for Flutter to pick up
                    savedPhoneNumber = number
                    isIncomingCall = isIncoming
                    saveCallEvent(event, duration = duration)

                    lastProcessedCallTimestamp = date
                }
            }

            // Persist the timestamp
            getSharedPreferences("call_monitor", Context.MODE_PRIVATE).edit()
                .putLong("last_call_log_ts", lastProcessedCallTimestamp)
                .apply()

        } catch (e: SecurityException) {
            Log.e(TAG, "No permission to read call log", e)
        } catch (e: Exception) {
            Log.e(TAG, "Error polling call log", e)
        }
    }

    // ==================== HELPERS ====================

    private fun saveCallEvent(event: String, duration: Int) {
        val prefs = getSharedPreferences("call_events", Context.MODE_PRIVATE)
        prefs.edit()
            .putString("last_event", event)
            .putString("last_number", savedPhoneNumber ?: "Unknown")
            .putBoolean("last_incoming", isIncomingCall)
            .putString("last_recording_path", outputFile)
            .putInt("last_duration", duration)
            .putLong("last_timestamp", System.currentTimeMillis())
            .apply()
        Log.d(TAG, "Event saved: $event, number=$savedPhoneNumber, incoming=$isIncomingCall, duration=${duration}s")
    }

    private fun unregisterListeners() {
        val tm = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        telephonyCallback?.let {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                tm.unregisterTelephonyCallback(it)
            }
        }
        telephonyCallback = null
        outgoingCallReceiver?.let {
            try { unregisterReceiver(it) } catch (_: Exception) {}
        }
        outgoingCallReceiver = null
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID, "Call Monitoring", NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Active when monitoring calls"
            setShowBadge(false)
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    private fun buildNotification(text: String): Notification {
        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("SalesTrack")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setOngoing(true)
            .build()
    }

    override fun onDestroy() {
        if (isRecording) stopRecording()
        unregisterListeners()
        stopCallLogPolling()
        super.onDestroy()
        Log.d(TAG, "CallMonitorService destroyed")
    }
}
