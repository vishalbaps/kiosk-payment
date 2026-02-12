import 'package:equatable/equatable.dart';
import 'package:kiosk_payment/kiosk_payment.dart';

class PaymentState extends Equatable {
  final List<PaymentDevice> devices;
  final PaymentDevice? selectedDevice;
  final DeviceStatus connectionStatus;
  final String? errorMessage;
  final bool isScanning;
  final bool isProcessingPayment;
  final TransactionResult? lastTransaction;
  final String? displayMessage;
  final String? generatedToken;

  const PaymentState({
    this.devices = const [],
    this.selectedDevice,
    this.connectionStatus = DeviceStatus.disconnected,
    this.errorMessage,
    this.isScanning = false,
    this.isProcessingPayment = false,
    this.lastTransaction,
    this.displayMessage,
    this.generatedToken,
  });

  PaymentState copyWith({
    List<PaymentDevice>? devices,
    PaymentDevice? selectedDevice,
    DeviceStatus? connectionStatus,
    String? errorMessage,
    bool? isScanning,
    bool? isProcessingPayment,
    TransactionResult? lastTransaction,
    String? displayMessage,
    String? generatedToken,
  }) {
    return PaymentState(
      devices: devices ?? this.devices,
      selectedDevice: selectedDevice ?? this.selectedDevice,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      errorMessage: errorMessage,
      isScanning: isScanning ?? this.isScanning,
      isProcessingPayment: isProcessingPayment ?? this.isProcessingPayment,
      lastTransaction: lastTransaction ?? this.lastTransaction,
      displayMessage: displayMessage,
      generatedToken: generatedToken,
    );
  }

  @override
  List<Object?> get props => [
        devices,
        selectedDevice,
        connectionStatus,
        errorMessage,
        isScanning,
        isProcessingPayment,
        lastTransaction,
        displayMessage,
        generatedToken,
      ];
}
