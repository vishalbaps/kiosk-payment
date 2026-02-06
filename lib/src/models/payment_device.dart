/// Represents the type of connection for the payment device.
enum DeviceType {
  bluetooth,
  network,
  usb,
  unknown;

  static DeviceType fromString(String value) {
    return DeviceType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DeviceType.unknown,
    );
  }
}

/// Represents a payment device discovered during scanning.
class PaymentDevice {
  /// The unique identifier of the device (UUID).
  final String id;

  /// The display name of the device.
  final String name;

  /// The connection type of the device.
  final DeviceType type;

  const PaymentDevice({
    required this.id,
    required this.name,
    this.type = DeviceType.bluetooth,
  });

  /// Creates a [PaymentDevice] from a map.
  factory PaymentDevice.fromMap(Map<String, dynamic> map) {
    return PaymentDevice(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown Device',
      type: map['type'] != null
          ? DeviceType.fromString(map['type'] as String)
          : DeviceType.bluetooth,
    );
  }

  /// Converts this [PaymentDevice] to a map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
    };
  }

  @override
  String toString() => 'PaymentDevice(id: $id, name: $name, type: $type)';
}
