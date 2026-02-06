# Kiosk Payment

A Flutter plugin for kiosk payment device integration. This package provides a clean abstraction for payment device discovery, connection, and transaction processing on both Android and iOS platforms.

## Features

- 🔍 **Device Discovery** - Scan and discover available payment devices
- 🔗 **Device Connection** - Connect/disconnect to payment terminals
- 💳 **Transaction Processing** - Initiate and process payments
- 📊 **Transaction Status** - Real-time transaction status updates
- ⚠️ **Error Handling** - Comprehensive error handling and recovery

## Getting Started

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  kiosk_payment:
    path: ../kiosk-payment  # or use git/pub reference
```

### Usage

```dart
import 'package:kiosk_payment/kiosk_payment.dart';

// Initialize the payment service
final kioskPayment = KioskPayment();

// Discover devices
final devices = await kioskPayment.discoverDevices();

// Connect to a device
await kioskPayment.connect(deviceId: devices.first.id);

// Process a payment
final result = await kioskPayment.processPayment(
  amount: 100.00,
  currency: 'USD',
);

// Disconnect
await kioskPayment.disconnect();
```

## Platform Setup

### Android

Add the following permissions to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
```

### iOS

Add the following to your `Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth access to connect to payment devices</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs Bluetooth access to connect to payment devices</string>
```

## Example

Check out the [example](example/) folder for a complete sample application.

## API Reference

### KioskPayment

The main class for interacting with payment devices.

#### Methods

| Method | Description |
|--------|-------------|
| `discoverDevices()` | Scans for available payment devices |
| `connect({required String deviceId})` | Connects to a specific device |
| `disconnect()` | Disconnects from the current device |
| `processPayment({required double amount, required String currency})` | Initiates a payment transaction |
| `cancelTransaction()` | Cancels the current transaction |
| `getDeviceStatus()` | Returns the current device status |

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
