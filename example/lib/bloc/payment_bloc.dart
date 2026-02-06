import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/payment_repository.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _repository;
  StreamSubscription? _devicesSubscription;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _errorSubscription;

  PaymentBloc({required PaymentRepository repository})
      : _repository = repository,
        super(const PaymentState()) {
    on<InitializeEvent>(_onInitialize);
    on<SearchDevicesEvent>(_onSearchDevices);
    on<SelectDeviceEvent>(_onSelectDevice);
    on<ConnectDeviceEvent>(_onConnectDevice);
    on<DisconnectDeviceEvent>(_onDisconnectDevice);
    on<DevicesUpdatedEvent>(_onDevicesUpdated);
    on<StatusUpdatedEvent>(_onStatusUpdated);
    on<PaymentErrorEvent>(_onPaymentError);
  }

  Future<void> _onInitialize(
      InitializeEvent event, Emitter<PaymentState> emit) async {
    await _repository.initialize();
    _devicesSubscription = _repository.foundDevices.listen((devices) {
      add(DevicesUpdatedEvent(devices));
    });
    _statusSubscription = _repository.status.listen((status) {
      add(StatusUpdatedEvent(status));
    });
    _errorSubscription = _repository.errors.listen((error) {
      add(PaymentErrorEvent(error));
    });
  }

  Future<void> _onSearchDevices(
      SearchDevicesEvent event, Emitter<PaymentState> emit) async {
    emit(state.copyWith(isScanning: true, errorMessage: null));
    await _repository.searchDevices();
  }

  Future<void> _onSelectDevice(
      SelectDeviceEvent event, Emitter<PaymentState> emit) async {
    emit(state.copyWith(selectedDevice: event.device));
  }

  Future<void> _onConnectDevice(
      ConnectDeviceEvent event, Emitter<PaymentState> emit) async {
    if (state.selectedDevice != null) {
      emit(state.copyWith(errorMessage: null));
      await _repository.connectLineItem(state.selectedDevice!);
    }
  }

  Future<void> _onDisconnectDevice(
      DisconnectDeviceEvent event, Emitter<PaymentState> emit) async {
    await _repository.disconnect();
  }

  void _onDevicesUpdated(
      DevicesUpdatedEvent event, Emitter<PaymentState> emit) {
    emit(state.copyWith(devices: event.devices));
  }

  void _onStatusUpdated(StatusUpdatedEvent event, Emitter<PaymentState> emit) {
    // If status is connected or disconnected, stop scanning spinner (just a logic assumption)
    emit(state.copyWith(connectionStatus: event.status));
  }

  void _onPaymentError(PaymentErrorEvent event, Emitter<PaymentState> emit) {
    emit(state.copyWith(errorMessage: event.error));
  }

  @override
  Future<void> close() {
    _devicesSubscription?.cancel();
    _statusSubscription?.cancel();
    _errorSubscription?.cancel();
    return super.close();
  }
}
