import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart'; // O 'encrypt' usa este por baixo dos panos

class SecurityService {
  // O "cofre" seguro do sistema (iOS Keychain / Android Keystore)
  final _storage = const FlutterSecureStorage();

  // Chaves para identificar os dados guardados
  static const _masterKeyName = 'master_password';
  static const _saltKeyName = 'secret_salt';

  // Salva a configuração inicial
  Future<void> setupFirstAccess(String password, String salt) async {
    await _storage.write(key: _masterKeyName, value: password);
    await _storage.write(key: _saltKeyName, value: salt);
  }

  // Verifica se o usuário já configurou o app antes
  Future<bool> isFirstAccess() async {
    String? master = await _storage.read(key: _masterKeyName);
    return master == null;
  }

  // A MÁGICA: Transforma senha + salt em uma chave AES de 32 bytes (256 bits)
  Future<Uint8List> generateEncryptionKey() async {
    String? password = await _storage.read(key: _masterKeyName);
    String? salt = await _storage.read(key: _saltKeyName);

    if (password == null || salt == null) {
      throw Exception("Chaves não configuradas");
    }

    // Convertemos strings para bytes (Uint8List) antes de processar
    final passwordBytes = utf8.encode(password);
    final saltBytes = utf8.encode(salt);

    // PBKDF2: "Estica" a senha 10.000 vezes para torná-la forte
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(Uint8List.fromList(saltBytes), 10000, 32));

    return derivator.process(Uint8List.fromList(passwordBytes));
  }

  Future<String?> getMasterPassword() async {
    return await _storage.read(key: _masterKeyName);
  }

  Future<String?> getSecretSalt() async {
    return await _storage.read(key: _saltKeyName);
  }
}
