import 'package:equatable/equatable.dart';
import 'package:kiosk_payment/kiosk_payment.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object> get props => [];
}

class InitializeEvent extends PaymentEvent {}

class SearchDevicesEvent extends PaymentEvent {}

class SelectDeviceEvent extends PaymentEvent {
  final PaymentDevice device;

  const SelectDeviceEvent(this.device);

  @override
  List<Object> get props => [device];
}

class ConnectDeviceEvent extends PaymentEvent {}

class DisconnectDeviceEvent extends PaymentEvent {}

class RestartReaderEvent extends PaymentEvent {}

class DevicesUpdatedEvent extends PaymentEvent {
  final List<PaymentDevice> devices;

  const DevicesUpdatedEvent(this.devices);

  @override
  List<Object> get props => [devices];
}

class StatusUpdatedEvent extends PaymentEvent {
  final DeviceStatus status;

  const StatusUpdatedEvent(this.status);

  @override
  List<Object> get props => [status];
}

class PaymentErrorEvent extends PaymentEvent {
  final String error;
  const PaymentErrorEvent(this.error);
  @override
  List<Object> get props => [error];
}

class ProcessPaymentEvent extends PaymentEvent {
  final double amount;
  final String currency;

  const ProcessPaymentEvent({required this.amount, required this.currency});

  @override
  List<Object> get props => [amount, currency];
}

class ClearTransactionEvent extends PaymentEvent {}

class DisplayMessageEvent extends PaymentEvent {
  final String message;
  const DisplayMessageEvent(this.message);
  @override
  List<Object> get props => [message];
}
