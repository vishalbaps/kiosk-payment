import 'package:kiosk_payment/kiosk_payment.dart';

class PaymentRepository {
  final KioskPayment _kioskPayment;

  PaymentRepository({KioskPayment? kioskPayment})
      : _kioskPayment = kioskPayment ?? KioskPayment();

  Future<void> initialize() async {
    // In a real app, these values would come from environment config
    await _kioskPayment.initialize(
      endpoint: "fts.cardconnect.com",
      merchantId: "TEST_MERCHANT_ID",
      enableLogging: true,
    );
  }

  Future<void> searchDevices() async {
    await _kioskPayment.searchDevices();
  }

  Future<void> connectLineItem(PaymentDevice device) async {
    await _kioskPayment.selectDevice(device);
    await _kioskPayment.connectDevice();
  }

  Future<void> disconnect() async {
    await _kioskPayment.disconnect();
  }

  Stream<List<PaymentDevice>> get foundDevices =>
      _kioskPayment.foundDevicesStream;
  Stream<DeviceStatus> get status => _kioskPayment.deviceStatusStream;
  Stream<String> get errors => _kioskPayment.errorStream;
}
