enum DeviceStatus {
  connected,
  disconnected,
  connecting,
  configuring,
  scanning,
  error,
  unknown;

  static DeviceStatus fromString(String value) {
    return DeviceStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DeviceStatus.unknown,
    );
  }
}
