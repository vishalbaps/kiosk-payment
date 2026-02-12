import 'kiosk_payment_platform_interface.dart';
import 'models/payment_device.dart';
import 'models/device_status.dart';
import 'models/transaction_result.dart';
import 'models/swipe_mode.dart';

class KioskPayment {
  factory KioskPayment() => _instance;

  KioskPayment._internal();

  /// The singleton instance
  static final KioskPayment _instance = KioskPayment._internal();

  KioskPaymentPlatform get _platform => KioskPaymentPlatform.instance;

  Future<String?> getPlatformVersion() {
    return _platform.getPlatformVersion();
  }

  /// Initialize the payment SDK
  Future<void> initialize({
    required String endpoint,
    required String merchantId,
    bool enableLogging = true,
    SwipeMode swipeMode = SwipeMode.swipeDipTap,
  }) {
    return _platform.initialize(
      endpoint: endpoint,
      merchantId: merchantId,
      enableLogging: enableLogging,
      swipeMode: swipeMode,
    );
  }

  Future<List<PaymentDevice>> discoverDevices() {
    return _platform.discoverDevices();
  }

  /// Start searching for devices. Listen to [foundDevicesStream].
  Future<void> searchDevices() {
    return _platform.findDevices();
  }

  /// Select and configure a device before connecting
  Future<void> selectDevice(PaymentDevice device) {
    return _platform.configureDevice(device);
  }

  Future<bool> connect({required String deviceId}) {
    return _platform.connect(deviceId: deviceId);
  }

  /// Connect to the configured device
  Future<void> connectDevice() {
    return _platform.connectReader();
  }

  /// Restart the reader to accept a new card
  Future<bool> restartReader() {
    return _platform.restartReader();
  }

  Future<bool> cancelTransaction() {
    return _platform.cancelTransaction();
  }

  Future<TransactionResult> processPayment(
      {required double amount, required String currency}) {
    return _platform.processPayment(amount: amount, currency: currency);
  }

  /// Generate a token manually for a card
  Future<void> generateToken({
    required String cardNumber,
    required String expirationDate,
    required String cvv,
    required String postalCode,
  }) {
    return _platform.generateToken(
      cardNumber: cardNumber,
      expirationDate: expirationDate,
      cvv: cvv,
      postalCode: postalCode,
    );
  }

  /// Disconnect the current device
  Future<void> disconnect() {
    return _platform.disconnect();
  }

  /// Stream of discovered devices
  Stream<List<PaymentDevice>> get foundDevicesStream =>
      _platform.foundDevicesStream;

  /// Stream of connection status
  Stream<DeviceStatus> get deviceStatusStream => _platform.deviceStatusStream;

  Stream<String> get transactionStatusStream =>
      _platform.transactionStatusStream;

  /// Stream of errors
  Stream<String> get errorStream => _platform.errorStream;

  /// Stream of display messages
  Stream<String> get displayMessageStream => _platform.displayMessageStream;

  /// Stream of generated tokens (from swipe or manual call)
  Stream<String> get onTokenGenerated => _platform.onTokenGenerated;
}
