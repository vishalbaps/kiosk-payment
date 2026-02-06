class TransactionResult {
  final bool isSuccess;
  final String? transactionId;
  final String? errorMessage;
  final String? cardType;
  final String? maskedCardNumber;
  final double? amount;
  final String? currency;
  final String? authorizationCode;
  final String? token;

  const TransactionResult({
    required this.isSuccess,
    this.transactionId,
    this.errorMessage,
    this.cardType,
    this.maskedCardNumber,
    this.amount,
    this.currency,
    this.authorizationCode,
    this.token,
  });

  factory TransactionResult.success({
    String? transactionId,
    String? cardType,
    String? maskedCardNumber,
    double? amount,
    String? currency,
    String? authorizationCode,
    String? token,
  }) {
    return TransactionResult(
      isSuccess: true,
      transactionId: transactionId,
      cardType: cardType,
      maskedCardNumber: maskedCardNumber,
      amount: amount,
      currency: currency,
      authorizationCode: authorizationCode,
      token: token,
    );
  }

  factory TransactionResult.failure(String errorMessage) {
    return TransactionResult(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}
