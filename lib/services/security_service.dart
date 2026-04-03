import 'dart:convert';
import 'dart:math'; // Necessário para Random.secure()
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

class SecurityService {
  final _storage = const FlutterSecureStorage();

  static const String _masterPasswordKey = 'master_password';
  static const String _encryptionKeyName = 'hive_encryption_key';

  /// Verifica se é o primeiro acesso
  Future<bool> isFirstAccess() async {
    String? password = await _storage.read(key: _masterPasswordKey);
    return password == null;
  }

  /// Método solicitado pelo seu setup_screen.dart
  Future<void> setupFirstAccess(String password) async {
    await saveMasterPassword(password);
    await generateEncryptionKey(); // Já deixa a chave de criptografia pronta
  }

  /// Salva o hash da senha mestre
  Future<void> saveMasterPassword(String password) async {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes).toString();
    await _storage.write(key: _masterPasswordKey, value: hash);
  }

  /// Autentica o usuário (usado pelo login_screen.dart)
  Future<bool> authenticate(String password) async {
    final storedHash = await _storage.read(key: _masterPasswordKey);
    if (storedHash == null) return false;

    final inputBytes = utf8.encode(password);
    final inputHash = sha256.convert(inputBytes).toString();
    return storedHash == inputHash;
  }

  /// Gera ou recupera a chave de 64 bytes para o Hive
  Future<List<int>> generateEncryptionKey() async {
    String? keyBase64 = await _storage.read(key: _encryptionKeyName);

    if (keyBase64 == null) {
      // Correção do erro .shuffle(): Gerando 64 bytes aleatórios reais
      final random = Random.secure();
      final key = List<int>.generate(64, (_) => random.nextInt(256));

      await _storage.write(
        key: _encryptionKeyName,
        value: base64UrlEncode(key),
      );
      return key;
    }

    return base64Url.decode(keyBase64);
  }

  /// Apaga tudo (Reset)
  Future<void> resetAll() async {
    await _storage.deleteAll();
  }
}
