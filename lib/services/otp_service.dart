import 'package:otp/otp.dart';
import 'package:base32/base32.dart';

class OtpService {
  /// Gera o código de 6 dígitos baseado na Secret Key
  static String generateCode(String? secret) {
    if (secret == null || secret.isEmpty) return "------";

    try {
      // Remove espaços que usuários costumam copiar junto
      final cleanSecret = secret.replaceAll(' ', '').toUpperCase();

      return OTP.generateTOTPCodeString(
        cleanSecret,
        DateTime.now().millisecondsSinceEpoch,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true, // Compatível com Google Authenticator
      );
    } catch (e) {
      return "Erro";
    }
  }

  /// Calcula quantos segundos faltam para o código expirar (0 a 30)
  static int getSecondsRemaining() {
    return 30 - (DateTime.now().second % 30);
  }
}
