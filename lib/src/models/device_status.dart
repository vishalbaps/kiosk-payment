enum DeviceStatus {
  connected,
  disconnected,
  connecting,
  configuring,
  scanning,
  readyForCard,
  processing,
  cardRemoved,
  removeCardRequested,
  transactionCompleted,
  error,
  unknown;

  static DeviceStatus fromString(String value) {
    // Handle common SDK state names
    String normalizedValue = value.toLowerCase();

    // Map common SDK states to our enum
    if (normalizedValue == 'idle') return DeviceStatus.connected;
    if (normalizedValue.contains('waiting_for_card') || normalizedValue.contains('waitingforcard'))
      return DeviceStatus.readyForCard;
    if (normalizedValue.contains('card_inserted') ||
        normalizedValue.contains('card_swiped') ||
        normalizedValue.contains('card_detected')) return DeviceStatus.processing;
    if (normalizedValue.contains('reading_card') || normalizedValue.contains('readingcard'))
      return DeviceStatus.processing;
    if (normalizedValue.contains('card_removed') || normalizedValue.contains('cardremoved'))
      return DeviceStatus.cardRemoved;
    if (normalizedValue.contains('remove_card_requested') ||
        normalizedValue.contains('removecardrequested') ||
        normalizedValue == 'remove_card') return DeviceStatus.removeCardRequested;
    if (normalizedValue.contains('completed') ||
        normalizedValue.contains('success') ||
        normalizedValue.contains('transactioncompleted') ||
        normalizedValue == 'transaction_completed') return DeviceStatus.transactionCompleted;

    // Direct mapping
    String simpleValue = normalizedValue.replaceAll('_', '');
    return DeviceStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == simpleValue,
      orElse: () => DeviceStatus.unknown,
    );
  }
}
