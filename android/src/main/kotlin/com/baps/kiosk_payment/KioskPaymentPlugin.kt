package com.baps.kiosk_payment

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import android.app.Activity
import android.content.Context
import android.bluetooth.BluetoothDevice
import com.bolt.consumersdk.*
import com.bolt.consumersdk.domain.*
import com.bolt.consumersdk.swiper.*
import com.bolt.consumersdk.swiper.enums.*
import com.bolt.consumersdk.listeners.BluetoothSearchResponseListener
import android.os.Handler
import android.os.Looper
import java.math.BigDecimal
import android.util.Log

class KioskPaymentPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var context: Context? = null

    // Event sinks
    private var findSwipeDevicesEventSink: EventChannel.EventSink? = null
    private var deviceStatusEventSink: EventChannel.EventSink? = null
    private var swiperDidFailWithErrorEventSink: EventChannel.EventSink? = null
    private var displayMessageEventSink: EventChannel.EventSink? = null

    // SDK objects
    private var foundDevices: MutableList<BluetoothDevice> = mutableListOf()
    private var selectedDevice: BluetoothDevice? = null
    private var swiperController: SwiperController? = null
    private var swiperControllerListener: SwiperControllerListener? = null

    companion object {
        const val kMethodPlatformHelper = "kMethodPlatformHelper"
        const val kMethodInitializeSwiper = "kMethodInitializeSwiper"
        const val kMethodFindSwipeDevices = "kMethodFindSwipeDevices"
        const val kMethodConfigureSwipeDevice = "kMethodConfigureSwipeDevice"
        const val kMethodConnectReader = "kMethodConnectReader"
        const val kMethodRestartReader = "kMethodRestartReader"
        const val kMethodReleaseSwiperDevice = "kMethodReleaseSwiperDevice"
        const val kMethodCancelTransaction = "kMethodCancelTransaction"

        const val kEventFindSwipeDevices = "kEventFindSwipeDevices"
        const val kEventDeviceStatus = "kEventDeviceStatus"
        const val kEventSwiperDidFailWithError = "kEventSwiperDidFailWithError"
        const val kEventDisplayMessage = "kEventDisplayMessage"
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, kMethodPlatformHelper)
        channel.setMethodCallHandler(this)

        setupEventChannels(flutterPluginBinding)
    }

    private fun setupEventChannels(binding: FlutterPlugin.FlutterPluginBinding) {
        EventChannel(binding.binaryMessenger, kEventFindSwipeDevices).setStreamHandler(object :
            EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                findSwipeDevicesEventSink = events
            }

            override fun onCancel(arguments: Any?) {
                findSwipeDevicesEventSink = null
            }
        })

        EventChannel(binding.binaryMessenger, kEventDeviceStatus).setStreamHandler(object :
            EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                deviceStatusEventSink = events
            }

            override fun onCancel(arguments: Any?) {
                deviceStatusEventSink = null
            }
        })

        EventChannel(
            binding.binaryMessenger, kEventSwiperDidFailWithError
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                swiperDidFailWithErrorEventSink = events
            }

            override fun onCancel(arguments: Any?) {
                swiperDidFailWithErrorEventSink = null
            }
        })

        EventChannel(binding.binaryMessenger, kEventDisplayMessage).setStreamHandler(object :
            EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                displayMessageEventSink = events
            }

            override fun onCancel(arguments: Any?) {
                displayMessageEventSink = null
            }
        })
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            kMethodInitializeSwiper -> {
                val endpoint = call.argument<String>("endpoint") ?: "fts.cardconnect.com"
                CCConsumer.getInstance().getApi().setEndPoint(endpoint)
                result.success(true)
            }

            kMethodFindSwipeDevices -> {
                findSwipeDevices(result)
            }

            kMethodConfigureSwipeDevice -> {
                val id = call.argument<String>("id")
                selectedDevice = foundDevices.find { it.address == id }
                result.success(selectedDevice != null)
            }

            kMethodConnectReader -> {
                connectReader(result)
            }

            kMethodRestartReader -> {
                restartReader(result)
            }

            kMethodReleaseSwiperDevice -> {
                releaseSwiperDevice(result)
            }

            kMethodCancelTransaction -> {
                cancelTransaction(result)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun findSwipeDevices(result: Result) {
        updateStatus("searching")
        foundDevices.clear()
        val api = CCConsumer.getInstance().getApi()

        // true for allowOnlyVP3300
        api.startBluetoothDeviceSearch(object : BluetoothSearchResponseListener {
            override fun onDeviceFound(device: BluetoothDevice) {
                foundDevices.add(device)
                val deviceList = foundDevices.map {
                    mapOf("name" to it.name, "id" to it.address)
                }
                activity?.runOnUiThread {
                    findSwipeDevicesEventSink?.success(deviceList)
                }
            }

            override fun onSearchCancelled() {
                // Done or Cancelled
            }
        }, context, true)

        result.success(true)
    }

    private fun connectReader(result: Result) {
        updateStatus("connecting")
        val device = selectedDevice
        activity?.let { act ->
            swiperControllerListener = object : SwiperControllerListener {
                override fun onTokenGenerated(
                    account: CCConsumerAccount?, error: CCConsumerError?
                ) {
                    Log.d("KioskPaymentPlugin", "onTokenGenerated: called")
                    if (error != null) {
                        Log.e("KioskPaymentPlugin", "onTokenGenerated error: ${error.getResponseMessage()}")
                        activity?.runOnUiThread {
                            swiperDidFailWithErrorEventSink?.success(error.getResponseMessage())
                        }
                    } else if (account != null) {
                        Log.d(
                            "KioskPaymentPlugin",
                            "onTokenGenerated success: token=${account.getToken()}"
                        )
                        // This indicates a transaction completed successfully,
                        // so we can update the status accordingly.
                        updateStatus("transaction_completed")
                    } else {
                        Log.w("KioskPaymentPlugin", "onTokenGenerated: received null account and null error.")
                    }
                }

                override fun onStartTokenGeneration() {
                    Log.d("onStartTokenGeneration", "onStartTokenGeneration")
                }
                override fun onError(error: SwiperError) {
                    Log.d("SwiperError", "${error.name}")
                    if (error == SwiperError.TRANSACTION_CANCELED) {
                        // Do not send error to Flutter for cancellation?
                        // Or maybe we want to know?
                        // user request implies they just want "connect only".
                        // If we send error, UI might show it. Let's suppress it for cleaner UX.
                        return
                    }
                    activity?.runOnUiThread {
                        swiperDidFailWithErrorEventSink?.success(error.name)
                    }
                }

                override fun onSwiperReadyForCard(type: CardProcessingType) {
                    Log.d("KioskPaymentPlugin", "Ready for card: ${type.name}")
                }


                override fun onSwiperConnected() {

                    Log.d("KioskPaymentPlugin", "Swiper Connected")
                    updateStatus("connected")
//                    // Auto-cancel transaction to enter idle state
//                    Handler(Looper.getMainLooper()).postDelayed({
//                        swiperController?.stopTransaction()
//                    }, 1000)
                }

                override fun onSwiperDisconnected() {

                    Log.d("KioskPaymentPlugin", "Swiper Disconnected")
                    updateStatus("disconnected")
                }

                override fun onBatteryState(state: BatteryState) {}
                override fun onDeviceConfigurationUpdate(update: String?) {
                    Log.d("KioskPaymentPlugin", "Device configuration update: $update")

                }

                override fun onDeviceConfigurationProgressUpdate(progress: Double) {
                    Log.d("KioskPaymentPlugin", "Device configuration progress: $progress")

                }

                override fun onDeviceConfigurationComplete(complete: Boolean) {}
                override fun onCardRemoved() {
                    Log.d("KioskPaymentPlugin", "onCardRemoved")
                }
                override fun onRemoveCardRequested() {
                    Log.d("KioskPaymentPlugin", "onRemoveCardRequested")
                }
                override fun showDeviceMessage(message: DeviceMessage, state: DeviceState) {
                    Log.d("KioskPaymentPlugin", "Device Message: ${message.getMessage()}")

                    activity?.runOnUiThread {
                        displayMessageEventSink?.success(message.getMessage())
                    }
                }

                override fun onTimeout() {}
            }

            val device = selectedDevice
            if (device != null) {
                swiperController =
                    CCSwiperControllerFactory().create(act, swiperControllerListener!!, device.address, false)
                swiperController?.startTransaction(SwiperCaptureMode.SWIPE_DIP_TAP, 2.0)
                result.success(true)
            } else {
                result.error("NO_DEVICE_SELECTED", "Please select a device first", null)
            }
        }
    }

    private fun releaseSwiperDevice(result: Result) {
        swiperController?.stopTransaction()
        updateStatus("disconnected")
        result.success(true)
    }

    private fun restartReader(result: Result) {
        Log.d("KioskPaymentPlugin", "restartReader called")
        // On Android, we can just start transaction again if swiper is connected
        swiperController?.let { swiper ->
            Log.d("KioskPaymentPlugin", "swiperController is not null, starting transaction")
            activity?.runOnUiThread {
                try {
                    swiper.stopTransaction()
                    swiper.startTransaction(SwiperCaptureMode.SWIPE_DIP_TAP, 2.0)
                    Log.d("KioskPaymentPlugin", "startTransaction called successfully")
                    result.success(true)
                } catch (e: Exception) {
                    Log.e("KioskPaymentPlugin", "Error starting transaction: ${e.message}")
                    result.error("RESTART_ERROR", e.message, null)
                }
            }
        } ?: run {
            Log.e("KioskPaymentPlugin", "swiperController is null in restartReader")
            result.error("SWIPER_NOT_INITIALIZED", "Swiper is not initialized", null)
        }
    }

    private fun cancelTransaction(result: Result) {
        Handler(Looper.getMainLooper()).postDelayed({
            swiperController?.stopTransaction()
        }, 1000)
        result.success(true)
    }

    private fun updateStatus(status: String) {
        activity?.runOnUiThread {
            deviceStatusEventSink?.success(status)
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }
}
