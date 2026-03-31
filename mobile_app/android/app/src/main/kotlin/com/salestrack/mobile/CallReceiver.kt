package com.salestrack.mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.util.Log

/**
 * BroadcastReceiver that detects incoming and outgoing call state changes.
 * Starts/stops the CallRecordingService accordingly.
 */
class CallReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "CallReceiver"
        private var lastState = TelephonyManager.CALL_STATE_IDLE
        private var isIncoming = false
        private var savedNumber: String? = null
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            // Outgoing call detected
            Intent.ACTION_NEW_OUTGOING_CALL -> {
                savedNumber = intent.getStringExtra(Intent.EXTRA_PHONE_NUMBER)
                Log.d(TAG, "Outgoing call to: $savedNumber")
            }
            // Phone state changed (incoming call or state transition)
            TelephonyManager.ACTION_PHONE_STATE_CHANGED -> {
                val stateStr = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
                val number = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
                val state = when (stateStr) {
                    TelephonyManager.EXTRA_STATE_IDLE -> TelephonyManager.CALL_STATE_IDLE
                    TelephonyManager.EXTRA_STATE_RINGING -> TelephonyManager.CALL_STATE_RINGING
                    TelephonyManager.EXTRA_STATE_OFFHOOK -> TelephonyManager.CALL_STATE_OFFHOOK
                    else -> return
                }

                if (state == lastState) return

                when (state) {
                    TelephonyManager.CALL_STATE_RINGING -> {
                        // Incoming call ringing
                        isIncoming = true
                        savedNumber = number
                        Log.d(TAG, "Incoming call from: $savedNumber")
                    }
                    TelephonyManager.CALL_STATE_OFFHOOK -> {
                        // Call answered or outgoing call connected
                        if (lastState == TelephonyManager.CALL_STATE_RINGING) {
                            // Incoming call answered
                            isIncoming = true
                        } else if (lastState == TelephonyManager.CALL_STATE_IDLE) {
                            // Outgoing call started
                            isIncoming = false
                        }
                        Log.d(TAG, "Call offhook — incoming=$isIncoming, number=$savedNumber")
                        startRecording(context)
                    }
                    TelephonyManager.CALL_STATE_IDLE -> {
                        // Call ended
                        if (lastState == TelephonyManager.CALL_STATE_RINGING) {
                            // Missed call (rang but never answered)
                            Log.d(TAG, "Missed call from: $savedNumber")
                            notifyFlutter(context, "missed", savedNumber)
                        } else if (lastState == TelephonyManager.CALL_STATE_OFFHOOK) {
                            // Call ended after being active
                            Log.d(TAG, "Call ended — stopping recording")
                            stopRecording(context)
                        }
                    }
                }
                lastState = state
            }
        }
    }

    private fun startRecording(context: Context) {
        val serviceIntent = Intent(context, CallRecordingService::class.java).apply {
            action = CallRecordingService.ACTION_START
            putExtra(CallRecordingService.EXTRA_PHONE_NUMBER, savedNumber ?: "Unknown")
            putExtra(CallRecordingService.EXTRA_IS_INCOMING, isIncoming)
        }
        context.startForegroundService(serviceIntent)
    }

    private fun stopRecording(context: Context) {
        val serviceIntent = Intent(context, CallRecordingService::class.java).apply {
            action = CallRecordingService.ACTION_STOP
        }
        context.startService(serviceIntent)
    }

    private fun notifyFlutter(context: Context, event: String, number: String?) {
        // Send missed call event to Flutter via shared preferences (picked up by MethodChannel)
        val prefs = context.getSharedPreferences("call_events", Context.MODE_PRIVATE)
        prefs.edit()
            .putString("last_event", event)
            .putString("last_number", number ?: "Unknown")
            .putLong("last_timestamp", System.currentTimeMillis())
            .apply()
    }
}
