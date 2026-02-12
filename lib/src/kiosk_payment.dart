import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
  ///
  /// This method automatically handles Bluetooth permissions and radio status.
  Future<void> searchDevices() async {
    if (Platform.isAndroid) {
      final hasPermissions = await _handlePermissions();
      if (!hasPermissions) {
        throw Exception('Bluetooth permission is required.');
      }

      BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();

        // Wait for the adapter to actually turn on
        state = await FlutterBluePlus.adapterState
            .where((s) => s == BluetoothAdapterState.on)
            .first
            .timeout(const Duration(seconds: 30), onTimeout: () => state);

        if (state != BluetoothAdapterState.on) {
          throw Exception('Bluetooth is disabled. Please enable it and try again.');
        }
      }
    }

    await _platform.findDevices();
  }

  /// Opens the app's settings page
  Future<bool> openAppSettings() {
    return ph.openAppSettings();
  }

  Future<bool> _handlePermissions() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = deviceInfo.version.sdkInt;

    ph.PermissionStatus scanStatus;
    ph.PermissionStatus connectStatus;

    if (sdkInt >= 31) {
      // Android 12+
      Map<ph.Permission, ph.PermissionStatus> statuses = await [
        ph.Permission.bluetoothScan,
        ph.Permission.bluetoothConnect,
      ].request();

      scanStatus = statuses[ph.Permission.bluetoothScan]!;
      connectStatus = statuses[ph.Permission.bluetoothConnect]!;
    } else {
      // Android < 12
      Map<ph.Permission, ph.PermissionStatus> statuses = await [
        ph.Permission.bluetooth,
        ph.Permission.location,
      ].request();

      scanStatus = statuses[ph.Permission.bluetooth]!;
      connectStatus = statuses[ph.Permission.location]!;
    }

    if (scanStatus.isPermanentlyDenied || connectStatus.isPermanentlyDenied) {
      await ph.openAppSettings();
      return false;
    }

    return scanStatus.isGranted && connectStatus.isGranted;
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

  Future<TransactionResult> processPayment({required double amount, required String currency}) {
    return _platform.processPayment(amount: amount, currency: currency);
  }

  /// Disconnect the current device
  Future<void> disconnect() {
    return _platform.disconnect();
  }

  /// Stream of discovered devices
  Stream<List<PaymentDevice>> get foundDevicesStream => _platform.foundDevicesStream;

  /// Stream of connection status
  Stream<DeviceStatus> get deviceStatusStream => _platform.deviceStatusStream;

  Stream<String> get transactionStatusStream => _platform.transactionStatusStream;

  /// Stream of errors
  Stream<String> get errorStream => _platform.errorStream;

  /// Stream of display messages
  Stream<String> get displayMessageStream => _platform.displayMessageStream;
}
