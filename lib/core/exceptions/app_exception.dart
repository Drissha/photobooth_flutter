class AppException implements Exception {
  const AppException({
    required this.code,
    required this.userMessage,
    this.solution = '',
    this.technicalMessage = '',
  });

  final String code;
  final String userMessage;
  final String solution;
  final String technicalMessage;

  @override
  String toString() => '[$code] $userMessage';
}
