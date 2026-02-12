import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'constants.dart';
import 'kiosk_payment_platform_interface.dart';
import 'models/payment_device.dart';
import 'models/device_status.dart';
import 'models/transaction_result.dart';
import 'models/swipe_mode.dart';

/// An implementation of [KioskPaymentPlatform] that uses method channels.
class MethodChannelKioskPayment extends KioskPaymentPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(kMethodPlatformHelper);

  final EventChannel _findDevicesEventChannel =
      const EventChannel(kEventFindSwipeDevices);
  final EventChannel _deviceStatusEventChannel =
      const EventChannel(kEventDeviceStatus);
  final EventChannel _swiperErrorEventChannel =
      const EventChannel(kEventSwiperDidFailWithError);
  final EventChannel _displayMessageEventChannel =
      const EventChannel(kEventDisplayMessage);
  final EventChannel _generateTokenEventChannel =
      const EventChannel(kEventGenerateToken);

  Stream<List<PaymentDevice>>? _foundDevicesStream;
  Stream<DeviceStatus>? _deviceStatusStream;
  Stream<String>? _errorStream;
  Stream<String>? _displayMessageStream;
  Stream<String>? _generateTokenStream;

  @override
  Future<String?> getPlatformVersion() async {
    return await methodChannel.invokeMethod<String>(
        kMethodPlatformHelper); // Helper typically returns version or similar
  }

  @override
  Future<void> initialize({
    required String endpoint,
    required String merchantId,
    bool enableLogging = true,
    SwipeMode swipeMode = SwipeMode.swipeDipTap,
  }) async {
    final Map<String, dynamic> args = {
      'endpoint': endpoint,
      'enableLogging': enableLogging,
      'merchantID': merchantId,
      'cardReadTimeout': 250,
      'swipeMode': swipeMode.value,
      'disableBeepSound': false
    };
    await methodChannel.invokeMethod(kMethodInitializeSwiper, args);
  }

  @override
  Future<void> findDevices() async {
    await methodChannel.invokeMethod(kMethodFindSwipeDevices);
  }

  @override
  Future<List<PaymentDevice>> discoverDevices() async {
    final completer = Completer<List<PaymentDevice>>();

    // Listen for devices
    final subscription = foundDevicesStream.listen((devices) {
      if (!completer.isCompleted && devices.isNotEmpty) {
        completer.complete(devices);
      }
    });

    await methodChannel.invokeMethod(kMethodFindSwipeDevices);

    try {
      return await completer.future.timeout(const Duration(seconds: 5));
    } catch (e) {
      return [];
    } finally {
      subscription.cancel();
    }
  }

  @override
  Future<void> configureDevice(PaymentDevice device) async {
    final Map<String, String> args = {'id': device.id};
    await methodChannel.invokeMethod(kMethodConfigureSwipeDevice, args);
  }

  @override
  Future<void> connectReader() async {
    await methodChannel.invokeMethod(kMethodConnectReader);
  }

  @override
  Future<bool> restartReader() async {
    return await methodChannel.invokeMethod<bool>(kMethodRestartReader) ??
        false;
  }

  @override
  Future<bool> connect({required String deviceId}) async {
    final Map<String, String> args = {'id': deviceId};
    final configured = await methodChannel.invokeMethod<bool>(
            kMethodConfigureSwipeDevice, args) ??
        false;

    if (configured) {
      await methodChannel.invokeMethod(kMethodConnectReader);
      return true;
    }
    return false;
  }

  @override
  Future<void> disconnect() async {
    await methodChannel.invokeMethod(kMethodReleaseSwiperDevice);
  }

  @override
  Future<bool> cancelTransaction() async {
    return await methodChannel.invokeMethod<bool>(kMethodCancelTransaction) ??
        false;
  }

  @override
  Future<TransactionResult> processPayment(
      {required double amount, required String currency}) async {
    // Simulate payment processing for now as specific backend logic isn't defined
    return Future.delayed(const Duration(seconds: 2), () {
      return TransactionResult.success(
          transactionId: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
          amount: amount,
          currency: currency,
          cardType: 'Visa',
          maskedCardNumber: '**** 1234');
    });
  }

  @override
  Future<void> generateToken({
    required String cardNumber,
    required String expirationDate,
    required String cvv,
    required String postalCode,
  }) async {
    final Map<String, String> args = {
      'cardNumber': cardNumber,
      'expirationDate': expirationDate,
      'cvv': cvv,
      'postalCode': postalCode,
    };
    await methodChannel.invokeMethod(kMethodGenerateToken, args);
  }

  @override
  Stream<List<PaymentDevice>> get foundDevicesStream {
    _foundDevicesStream ??=
        _findDevicesEventChannel.receiveBroadcastStream().map((event) {
      if (event is List) {
        return event
            .map((e) => PaymentDevice.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    });
    return _foundDevicesStream!;
  }

  @override
  Stream<DeviceStatus> get deviceStatusStream {
    _deviceStatusStream ??=
        _deviceStatusEventChannel.receiveBroadcastStream().map((event) {
      final status = event.toString().toLowerCase();
      return DeviceStatus.fromString(status);
    });
    return _deviceStatusStream!;
  }

  @override
  Stream<String> get errorStream {
    _errorStream ??=
        _swiperErrorEventChannel.receiveBroadcastStream().map((event) {
      return event.toString();
    });
    return _errorStream!;
  }

  @override
  Stream<String> get transactionStatusStream {
    return deviceStatusStream.map((s) => s.name);
  }

  @override
  Stream<String> get displayMessageStream {
    _displayMessageStream ??=
        _displayMessageEventChannel.receiveBroadcastStream().map((event) {
      return event.toString();
    });
    return _displayMessageStream!;
  }

  @override
  Stream<String> get onTokenGenerated {
    _generateTokenStream ??=
        _generateTokenEventChannel.receiveBroadcastStream().map((event) {
      return event.toString();
    });
    return _generateTokenStream!;
  }
}
