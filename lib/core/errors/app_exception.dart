class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';

  factory AppException.fromError(dynamic error) {
    if (error is AppException) return error;
    return AppException(
      message: error?.toString() ?? 'Terjadi kesalahan tidak diketahui',
      originalError: error,
    );
  }
}

class AuthException extends AppException {
  const AuthException({required super.message, super.code, super.originalError});
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Koneksi internet bermasalah. Coba lagi.',
    super.code,
    super.originalError,
  });
}

class ServerException extends AppException {
  const ServerException({
    super.message = 'Terjadi kesalahan pada server. Coba lagi.',
    super.code,
    super.originalError,
  });
}

class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code,
    super.originalError,
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.code,
    super.originalError,
  });
}

class InsufficientBalanceException extends AppException {
  const InsufficientBalanceException()
      : super(message: 'Saldo tidak mencukupi untuk melakukan transaksi ini');
}
