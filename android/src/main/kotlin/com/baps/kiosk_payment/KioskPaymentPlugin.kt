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
import java.math.BigDecimal

class KioskPaymentPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
    
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var context: Context? = null
    
    // Event sinks
    private var findSwipeDevicesEventSink: EventChannel.EventSink? = null
    private var deviceStatusEventSink: EventChannel.EventSink? = null
    private var swiperDidFailWithErrorEventSink: EventChannel.EventSink? = null

    // SDK objects
    private var foundDevices: MutableList<BluetoothDevice> = mutableListOf()
    private var selectedDevice: BluetoothDevice? = null
    private var swiperController: SwiperController? = null

    companion object {
        const val kMethodPlatformHelper = "kMethodPlatformHelper"
        const val kMethodInitializeSwiper = "kMethodInitializeSwiper"
        const val kMethodFindSwipeDevices = "kMethodFindSwipeDevices"
        const val kMethodConfigureSwipeDevice = "kMethodConfigureSwipeDevice"
        const val kMethodConnectReader = "kMethodConnectReader"
        const val kMethodReleaseSwiperDevice = "kMethodReleaseSwiperDevice"

        const val kEventFindSwipeDevices = "kEventFindSwipeDevices"
        const val kEventDeviceStatus = "kEventDeviceStatus"
        const val kEventSwiperDidFailWithError = "kEventSwiperDidFailWithError"
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, kMethodPlatformHelper)
        channel.setMethodCallHandler(this)

        setupEventChannels(flutterPluginBinding)
    }

    private fun setupEventChannels(binding: FlutterPlugin.FlutterPluginBinding) {
        EventChannel(binding.binaryMessenger, kEventFindSwipeDevices).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                findSwipeDevicesEventSink = events
            }
            override fun onCancel(arguments: Any?) {
                findSwipeDevicesEventSink = null
            }
        })

        EventChannel(binding.binaryMessenger, kEventDeviceStatus).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                deviceStatusEventSink = events
            }
            override fun onCancel(arguments: Any?) {
                deviceStatusEventSink = null
            }
        })

        EventChannel(binding.binaryMessenger, kEventSwiperDidFailWithError).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                swiperDidFailWithErrorEventSink = events
            }
            override fun onCancel(arguments: Any?) {
                swiperDidFailWithErrorEventSink = null
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
            kMethodReleaseSwiperDevice -> {
                releaseSwiperDevice(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun findSwipeDevices(result: Result) {
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
        val device = selectedDevice
        activity?.let { act ->
            val listener = object : SwiperControllerListener {
                override fun onTokenGenerated(account: CCConsumerAccount?, error: CCConsumerError?) {
                    // Handle token return
                }

                override fun onStartTokenGeneration() {}
                override fun onError(error: SwiperError) {
                    updateStatus("disconnected")
                    activity?.runOnUiThread {
                        swiperDidFailWithErrorEventSink?.success(error.name)
                    }
                }
                override fun onSwiperReadyForCard(type: CardProcessingType) {
                    updateStatus("connected")
                }
                override fun onSwiperConnected() {
                    updateStatus("connected")
                }
                override fun onSwiperDisconnected() {
                    updateStatus("disconnected")
                }
                override fun onBatteryState(state: BatteryState) {}
                override fun onDeviceConfigurationUpdate(update: String?) {}
                override fun onDeviceConfigurationProgressUpdate(progress: Double) {}
                override fun onDeviceConfigurationComplete(complete: Boolean) {}
                override fun onCardRemoved() {}
                override fun onRemoveCardRequested() {}
                override fun showDeviceMessage(message: DeviceMessage, state: DeviceState) {}
                override fun onTimeout() {}
            }
            
            val device = selectedDevice
            if (device != null) {
                val swiper = CCSwiperControllerFactory().create(act, listener, device.address, false)
                swiper.startTransaction(SwiperCaptureMode.SWIPE_DIP_TAP, 0.0)
                result.success(true)
            } else {
                result.error("NO_DEVICE_SELECTED", "Please select a device first", null)
            }
        }
    }

    private fun releaseSwiperDevice(result: Result) {
        // Implement release logic if available in SDK
        updateStatus("disconnected")
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
