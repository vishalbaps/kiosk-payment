import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'kiosk_payment_method_channel.dart';
import 'models/payment_device.dart';
import 'models/device_status.dart';
import 'models/transaction_result.dart';

abstract class KioskPaymentPlatform extends PlatformInterface {
  /// Constructs a KioskPaymentPlatform.
  KioskPaymentPlatform() : super(token: _token);

  static final Object _token = Object();

  static KioskPaymentPlatform _instance = MethodChannelKioskPayment();

  /// The default instance of [KioskPaymentPlatform] to use.
  ///
  /// Defaults to [MethodChannelKioskPayment].
  static KioskPaymentPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [KioskPaymentPlatform] when
  /// they register themselves.
  static set instance(KioskPaymentPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  Future<void> initialize({
    required String endpoint,
    required String merchantId,
    bool enableLogging = true,
  });

  Future<List<PaymentDevice>> discoverDevices() {
    throw UnimplementedError('discoverDevices() has not been implemented.');
  }

  Future<void> findDevices();

  Future<void> configureDevice(PaymentDevice device);

  Future<bool> connect({required String deviceId}) {
    throw UnimplementedError('connect() has not been implemented.');
  }

  Future<void> connectReader();

  Future<void> disconnect();

  Future<TransactionResult> processPayment(
      {required double amount, required String currency}) {
    throw UnimplementedError('processPayment() has not been implemented.');
  }

  // Streams
  Stream<List<PaymentDevice>> get foundDevicesStream;
  Stream<DeviceStatus> get deviceStatusStream;
  Stream<String> get errorStream;
  Stream<String> get transactionStatusStream;
}
