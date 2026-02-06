import Flutter
import UIKit
import BoltMobileSDK

enum ChannelNameEnum {
    static let kMethodPlatformHelper = "kMethodPlatformHelper"
    static let kMethodInitializeSwiper = "kMethodInitializeSwiper"
    static let kMethodFindSwipeDevices = "kMethodFindSwipeDevices"
    static let kMethodConfigureSwipeDevice = "kMethodConfigureSwipeDevice"
    static let kMethodConnectReader = "kMethodConnectReader"
    static let kMethodReleaseSwiperDevice = "kMethodReleaseSwiperDevice"

    static let kEventFindSwipeDevices = "kEventFindSwipeDevices"
    static let kEventDeviceStatus = "kEventDeviceStatus"
    static let kEventSwiperDidFailWithError = "kEventSwiperDidFailWithError"
}

public class KioskPaymentPlugin: NSObject, FlutterPlugin, BMSSwiperControllerDelegate {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: ChannelNameEnum.kMethodPlatformHelper, binaryMessenger: registrar.messenger())
        let instance = KioskPaymentPlugin()
        instance.initChannels(registrar: registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // Event sinks
    private var findSwipeDevicesEventSink: FlutterEventSink?
    private var deviceStatusEventSink: FlutterEventSink?
    private var swiperDidFailWithErrorEventSink: FlutterEventSink?

    // SDK objects
    var swiper: BMSSwiperController?
    var foundDevices: [BMSDevice]?
    var tempDevice: BMSDevice?
    var merchantID: String?
    var enableLogging: Bool = true

    func initChannels(registrar: FlutterPluginRegistrar) {
        let findDevicesChannel = FlutterEventChannel(name: ChannelNameEnum.kEventFindSwipeDevices, binaryMessenger: registrar.messenger())
        findDevicesChannel.setStreamHandler(FindSwipeDevicesStreamHandler(plugin: self))

        let deviceStatusChannel = FlutterEventChannel(name: ChannelNameEnum.kEventDeviceStatus, binaryMessenger: registrar.messenger())
        deviceStatusChannel.setStreamHandler(DeviceStatusStreamHandler(plugin: self))
        
        let errorChannel = FlutterEventChannel(name: ChannelNameEnum.kEventSwiperDidFailWithError, binaryMessenger: registrar.messenger())
        errorChannel.setStreamHandler(ErrorStreamHandler(plugin: self))
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case ChannelNameEnum.kMethodInitializeSwiper:
             result(initializeSwiper(data: call.arguments as! [String: Any]))
            
        case ChannelNameEnum.kMethodFindSwipeDevices:
            result(findSwipeDevices())

        case ChannelNameEnum.kMethodConfigureSwipeDevice:
             result(configureSwipeDevice(data: call.arguments as? [String : String]))

        case ChannelNameEnum.kMethodConnectReader:
             result(connectReader())

        case ChannelNameEnum.kMethodReleaseSwiperDevice:
             result(releaseSwiperDevice())

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func initializeSwiper(data: [String: Any]) -> Bool {
        merchantID = (data["merchantID"] as? String) ?? ""
        enableLogging = (data["enableLogging"] as? Bool) ?? false
        // Basic init of API
        BMSAPI.instance().endpoint = (data["endpoint"] as? String) ?? "fts.cardconnect.com"
        BMSAPI.instance().enableLogging = self.enableLogging
        return true
    }

    func findSwipeDevices() -> Bool {
        _ = releaseSwiperDevice()
        swiper = BMSSwiperController(delegate: self, swiper: BMSSwiperType.VP3300, loggingEnabled: self.enableLogging)
        swiper?.findDevices()
        return true
    }

    func configureSwipeDevice(data: [String:String]?) -> Bool {
        self.swiper?.cancelFindDevices()
        self.tempDevice = self.foundDevices?.first(where: { BMSDevice in
            BMSDevice.uuid.uuidString == data?["id"]
        })
        return true
    }
    
    func connectReader() -> Bool {
        if self.swiper == nil {
             swiper = BMSSwiperController(delegate: self, swiper: BMSSwiperType.VP3300, loggingEnabled: self.enableLogging)
        }
        
        if let device = self.tempDevice {
            // Defaulting to swipeDipTap
            swiper?.connect(toDevice: device.uuid, mode: BMSCardReadMode.swipeDipTap)
            swiper?.beepSetting = BMSDeviceBeepSetting.settingNone
            swiper?.cardReadTimeout = 250
            return true
        }
        return false
    }

    func releaseSwiperDevice() -> Bool {
        self.swiper?.releaseDevice()
        self.swiper = nil
        return true
    }

    // MARK: - BMSSwiperControllerDelegate
    public func swiper(_ swiper: BMSSwiperController!, foundDevices devices: [Any]!) {
        self.foundDevices = devices as? [BMSDevice]
        
        guard let sink = findSwipeDevicesEventSink else { return }
        
        var deviceList: [[String: String]] = []
        self.foundDevices?.forEach({ BMSDevice in
            deviceList.append(["name": BMSDevice.name, "id": BMSDevice.uuid.uuidString])
        })
        sink(deviceList)
    }

    public func swiper(_ swiper: BMSSwiper, connectionStateHasChanged state: BMSSwiperConnectionState) {
        var status = "unknown"
        switch state {
        case .connected: status = "connected"
        case .disconnected: status = "disconnected"
        case .connecting: status = "connecting"
        case .configuring: status = "configuring"
        case .searching: status = "searching"
        @unknown default: status = "unknown"
        }
        
        if let sink = deviceStatusEventSink {
            sink(status)
        }
    }
    
    public func swiper(_ swiper: BMSSwiper, didFailWithError error: Error, completion: @escaping () -> Void) {
        let message = String(format: "An error occurred: %@", error.localizedDescription)
        if let sink = swiperDidFailWithErrorEventSink {
            sink(message)
        }
    }
    
    // Required stubs
    public func swiperDidStartCardRead(_ swiper: BMSSwiper) {}
    public func swiper(_ swiper: BMSSwiper, didGenerateTokenWith account: BMSAccount?, completion: @escaping (() -> Void)) {}
    public func swiper(_ swiper: BMSSwiperController!, displayMessage message: String!, canCancel cancelable: Bool) {}
    public func swiper(_ swiper: BMSSwiperController!, configurationProgress progress: Float) {}

    // Helper classes for StreamHandlers to avoid strong reference cycles or just to organize
    class FindSwipeDevicesStreamHandler: NSObject, FlutterStreamHandler {
        weak var plugin: KioskPaymentPlugin?
        init(plugin: KioskPaymentPlugin) { self.plugin = plugin }
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            plugin?.findSwipeDevicesEventSink = events
            return nil
        }
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            plugin?.findSwipeDevicesEventSink = nil
            return nil
        }
    }
    
    class DeviceStatusStreamHandler: NSObject, FlutterStreamHandler {
        weak var plugin: KioskPaymentPlugin?
        init(plugin: KioskPaymentPlugin) { self.plugin = plugin }
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            plugin?.deviceStatusEventSink = events
            return nil
        }
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            plugin?.deviceStatusEventSink = nil
            return nil
        }
    }

    class ErrorStreamHandler: NSObject, FlutterStreamHandler {
        weak var plugin: KioskPaymentPlugin?
        init(plugin: KioskPaymentPlugin) { self.plugin = plugin }
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            plugin?.swiperDidFailWithErrorEventSink = events
            return nil
        }
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            plugin?.swiperDidFailWithErrorEventSink = nil
            return nil
        }
    }
}
