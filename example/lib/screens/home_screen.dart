import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import 'package:kiosk_payment/kiosk_payment.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiosk Payment Example'),
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusSection(state),
                const SizedBox(height: 20),
                _buildActionButtons(context, state),
                const SizedBox(height: 20),
                const Text(
                  'Available Devices:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _buildDeviceList(context, state),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusSection(PaymentState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Status: ${state.connectionStatus.name.toUpperCase()}',
                style: const TextStyle(fontSize: 16)),
            if (state.selectedDevice != null)
              Text('Selected: ${state.selectedDevice!.name}',
                  style: const TextStyle(fontSize: 14, color: Colors.blue)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, PaymentState state) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            context.read<PaymentBloc>().add(SearchDevicesEvent());
          },
          child: const Text('Search Devices'),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          ElevatedButton(
            onPressed: state.selectedDevice != null
                ? () {
                    context.read<PaymentBloc>().add(ConnectDeviceEvent());
                  }
                : null,
            child: const Text('Connect'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<PaymentBloc>().add(DisconnectDeviceEvent());
            },
            child: const Text('Disconnect'),
          ),
        ]),
      ],
    );
  }

  Widget _buildDeviceList(BuildContext context, PaymentState state) {
    if (state.isScanning && state.devices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.devices.isEmpty) {
      return const Center(child: Text('No devices found'));
    }

    return ListView.builder(
      itemCount: state.devices.length,
      itemBuilder: (context, index) {
        final device = state.devices[index];
        final isSelected = state.selectedDevice?.id == device.id;

        return ListTile(
          title: Text(device.name),
          subtitle: Text(device.id),
          trailing:
              isSelected ? const Icon(Icons.check, color: Colors.green) : null,
          onTap: () {
            context.read<PaymentBloc>().add(SelectDeviceEvent(device));
          },
        );
      },
    );
  }
}
