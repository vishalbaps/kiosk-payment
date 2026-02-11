import Flutter
import UIKit
import BoltMobileSDK

enum ChannelNameEnum {
    static let kMethodPlatformHelper = "kMethodPlatformHelper"
    static let kMethodInitializeSwiper = "kMethodInitializeSwiper"
    static let kMethodFindSwipeDevices = "kMethodFindSwipeDevices"
    static let kMethodConfigureSwipeDevice = "kMethodConfigureSwipeDevice"
    static let kMethodConnectReader = "kMethodConnectReader"
    static let kMethodRestartReader = "kMethodRestartReader"
    static let kMethodReleaseSwiperDevice = "kMethodReleaseSwiperDevice"
    static let kMethodCancelTransaction = "kMethodCancelTransaction"

    static let kEventFindSwipeDevices = "kEventFindSwipeDevices"
    static let kEventDeviceStatus = "kEventDeviceStatus"
    static let kEventSwiperDidFailWithError = "kEventSwiperDidFailWithError"
    static let kEventDisplayMessage = "kEventDisplayMessage"
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
    private var displayMessageEventSink: FlutterEventSink?

    // SDK objects
    var swiper: BMSSwiperController?
    var foundDevices: [BMSDevice]?
    var tempDevice: BMSDevice?
    var enableLogging: Bool = true
    var restartReaderBlock: (() -> ())? = nil

    func initChannels(registrar: FlutterPluginRegistrar) {
        let findDevicesChannel = FlutterEventChannel(name: ChannelNameEnum.kEventFindSwipeDevices, binaryMessenger: registrar.messenger())
        findDevicesChannel.setStreamHandler(FindSwipeDevicesStreamHandler(plugin: self))

        let deviceStatusChannel = FlutterEventChannel(name: ChannelNameEnum.kEventDeviceStatus, binaryMessenger: registrar.messenger())
        deviceStatusChannel.setStreamHandler(DeviceStatusStreamHandler(plugin: self))
        
        let errorChannel = FlutterEventChannel(name: ChannelNameEnum.kEventSwiperDidFailWithError, binaryMessenger: registrar.messenger())
        errorChannel.setStreamHandler(ErrorStreamHandler(plugin: self))

        let displayMessageChannel = FlutterEventChannel(name: ChannelNameEnum.kEventDisplayMessage, binaryMessenger: registrar.messenger())
        displayMessageChannel.setStreamHandler(DisplayMessageStreamHandler(plugin: self))
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

        case ChannelNameEnum.kMethodRestartReader:
             result(restartReader())

         case ChannelNameEnum.kMethodReleaseSwiperDevice:
              result(releaseSwiperDevice())

         case ChannelNameEnum.kMethodCancelTransaction:
              result(cancelTransaction())

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func initializeSwiper(data: [String: Any]) -> Bool {

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

    func restartReader() -> Bool {
        if self.restartReaderBlock != nil &&
            self.swiper?.connectionState == BMSSwiperConnectionState.connected {
            self.restartReaderBlock!()
            return true
        }
        return false
    }

    func cancelTransaction() -> Bool {
        let deadlineTime = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            self.swiper?.cancelTransaction()
        }
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
        case .connected:
            status = "connected"
            // Auto-cancel transaction to enter idle state
            _ = cancelTransaction()
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
        self.restartReaderBlock = completion
        print("errorrrrr--: \(error.localizedDescription ?? "")")
        
        // Check if error is canceledTransaction
        let nsError = error as NSError
        if nsError.domain == BMSSwiperErrorDomain && nsError.code == BMSSwiperError.canceledTransaction.rawValue {
             print("Transaction canceled (idle state)")
             // Do not send error to Flutter for cancellation?
             // Or maybe we want to know? 
             // user request implies they just want "connect only". 
             // If we send error, UI might show it. Let's suppress it for cleaner UX.
             return
        }
        
        let message = String(format: "An error occurred: %@", error.localizedDescription)
        if let sink = swiperDidFailWithErrorEventSink {
            sink(message)
        }
    }
    
    // Required stubs
    public func swiperDidStartCardRead(_ swiper: BMSSwiper) {}
    public func swiper(_ swiper: BMSSwiper, didGenerateTokenWith account: BMSAccount?, completion: @escaping (() -> Void)) {
        self.restartReaderBlock = completion
    }
    
    public func swiper(_ swiper: BMSSwiperController!, displayMessage message: String!, canCancel cancelable: Bool) {

        print("displayMessage before: \(message ?? "")")
        
        var finalMessage = message
        if let msg = message, let data = msg.data(using: .isoLatin1), let decoded = String(data: data, encoding: .utf8) {
            finalMessage = decoded
        }
        
        print("displayMessage after: \(finalMessage ?? "")")

        if let sink = displayMessageEventSink {
            sink(finalMessage)
        }
    }
    
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

    class DisplayMessageStreamHandler: NSObject, FlutterStreamHandler {
        weak var plugin: KioskPaymentPlugin?
        init(plugin: KioskPaymentPlugin) { self.plugin = plugin }
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            plugin?.displayMessageEventSink = events
            return nil
        }
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            plugin?.displayMessageEventSink = nil
            return nil
        }
    }
}
