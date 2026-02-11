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
  StreamSubscription? _displayMessageSubscription;

  PaymentBloc({required PaymentRepository repository})
      : _repository = repository,
        super(const PaymentState()) {
    on<InitializeEvent>(_onInitialize);
    on<SearchDevicesEvent>(_onSearchDevices);
    on<SelectDeviceEvent>(_onSelectDevice);
    on<ConnectDeviceEvent>(_onConnectDevice);
    on<DisconnectDeviceEvent>(_onDisconnectDevice);
    on<RestartReaderEvent>(_onRestartReader);
    on<DevicesUpdatedEvent>(_onDevicesUpdated);
    on<StatusUpdatedEvent>(_onStatusUpdated);
    on<PaymentErrorEvent>(_onPaymentError);
    on<ProcessPaymentEvent>(_onProcessPayment);
    on<ClearTransactionEvent>(_onClearTransaction);
    on<DisplayMessageEvent>(_onDisplayMessage);
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
    _displayMessageSubscription = _repository.displayMessages.listen((message) {
      add(DisplayMessageEvent(message));
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

  Future<void> _onRestartReader(
      RestartReaderEvent event, Emitter<PaymentState> emit) async {
    emit(state.copyWith(displayMessage: null, errorMessage: null));
    await _repository.restartReader();
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
    emit(state.copyWith(errorMessage: event.error, isProcessingPayment: false));
  }

  Future<void> _onProcessPayment(
      ProcessPaymentEvent event, Emitter<PaymentState> emit) async {
    emit(state.copyWith(
        isProcessingPayment: true, errorMessage: null, lastTransaction: null));
    try {
      final result = await _repository.processPayment(
        amount: event.amount,
        currency: event.currency,
      );
      emit(state.copyWith(
        isProcessingPayment: false,
        lastTransaction: result,
      ));
    } catch (e) {
      emit(state.copyWith(
        isProcessingPayment: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onClearTransaction(
      ClearTransactionEvent event, Emitter<PaymentState> emit) {
    emit(state.copyWith(
        lastTransaction: null)); // Helper to clear previous results
  }

  void _onDisplayMessage(
      DisplayMessageEvent event, Emitter<PaymentState> emit) {
    emit(state.copyWith(displayMessage: event.message));
  }

  @override
  Future<void> close() {
    _devicesSubscription?.cancel();
    _statusSubscription?.cancel();
    _errorSubscription?.cancel();
    _displayMessageSubscription?.cancel();
    return super.close();
  }
}
