import 'package:equatable/equatable.dart';
import 'package:kiosk_payment/kiosk_payment.dart';

class PaymentState extends Equatable {
  final List<PaymentDevice> devices;
  final PaymentDevice? selectedDevice;
  final DeviceStatus connectionStatus;
  final String? errorMessage;
  final bool isScanning;

  const PaymentState({
    this.devices = const [],
    this.selectedDevice,
    this.connectionStatus = DeviceStatus.disconnected,
    this.errorMessage,
    this.isScanning = false,
  });

  PaymentState copyWith({
    List<PaymentDevice>? devices,
    PaymentDevice? selectedDevice,
    DeviceStatus? connectionStatus,
    String? errorMessage,
    bool? isScanning,
  }) {
    return PaymentState(
      devices: devices ?? this.devices,
      selectedDevice: selectedDevice ?? this.selectedDevice,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      errorMessage: errorMessage,
      isScanning: isScanning ?? this.isScanning,
    );
  }

  @override
  List<Object?> get props =>
      [devices, selectedDevice, connectionStatus, errorMessage, isScanning];
}
