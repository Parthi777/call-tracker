package com.salestrack.mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.MediaRecorder
import android.os.Build
import android.os.IBinder
import android.util.Log
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Foreground service that records audio during active phone calls.
 * Uses MediaRecorder with VOICE_COMMUNICATION source for call audio capture.
 */
class CallRecordingService : Service() {

    companion object {
        const val TAG = "CallRecordingService"
        const val ACTION_START = "com.salestrack.mobile.ACTION_START_RECORDING"
        const val ACTION_STOP = "com.salestrack.mobile.ACTION_STOP_RECORDING"
        const val EXTRA_PHONE_NUMBER = "phone_number"
        const val EXTRA_IS_INCOMING = "is_incoming"

        private const val CHANNEL_ID = "call_recording_channel"
        private const val NOTIFICATION_ID = 1001
    }

    private var mediaRecorder: MediaRecorder? = null
    private var isRecording = false
    private var outputFile: String? = null
    private var callStartTime: Long = 0
    private var phoneNumber: String = "Unknown"
    private var isIncoming: Boolean = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                phoneNumber = intent.getStringExtra(EXTRA_PHONE_NUMBER) ?: "Unknown"
                isIncoming = intent.getBooleanExtra(EXTRA_IS_INCOMING, false)
                startForeground(NOTIFICATION_ID, buildNotification())
                startRecording()
            }
            ACTION_STOP -> {
                stopRecording()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    private fun startRecording() {
        if (isRecording) return

        try {
            val recordingsDir = File(getExternalFilesDir(null), "recordings")
            if (!recordingsDir.exists()) recordingsDir.mkdirs()

            val dateFormat = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US)
            val timestamp = dateFormat.format(Date())
            val direction = if (isIncoming) "IN" else "OUT"
            val sanitizedNumber = phoneNumber.replace(Regex("[^\\d+]"), "")
            val fileName = "${timestamp}_${direction}_${sanitizedNumber}.mp4"

            outputFile = File(recordingsDir, fileName).absolutePath
            callStartTime = System.currentTimeMillis()

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

            // Save error event for Flutter to read
            saveCallEvent("recording_error", e.message)
        }
    }

    private fun stopRecording() {
        if (!isRecording) return

        try {
            mediaRecorder?.apply {
                stop()
                release()
            }
            Log.d(TAG, "Recording stopped: $outputFile")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping recording", e)
        } finally {
            mediaRecorder = null
            isRecording = false
        }

        val durationMs = System.currentTimeMillis() - callStartTime
        val durationSeconds = (durationMs / 1000).toInt()

        // Save completed call event for Flutter to pick up
        saveCallEvent("call_recorded", null, durationSeconds)
    }

    private fun saveCallEvent(event: String, error: String?, durationSeconds: Int = 0) {
        val prefs = getSharedPreferences("call_events", Context.MODE_PRIVATE)
        prefs.edit()
            .putString("last_event", event)
            .putString("last_number", phoneNumber)
            .putBoolean("last_incoming", isIncoming)
            .putString("last_recording_path", outputFile)
            .putInt("last_duration", durationSeconds)
            .putLong("last_timestamp", callStartTime)
            .putString("last_error", error)
            .apply()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Call Recording",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Shows when a call is being recorded"
            setShowBadge(false)
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        val direction = if (isIncoming) "incoming" else "outgoing"
        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("Recording $direction call")
            .setContentText("Call with $phoneNumber")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setOngoing(true)
            .build()
    }

    override fun onDestroy() {
        if (isRecording) {
            stopRecording()
        }
        super.onDestroy()
    }
}
