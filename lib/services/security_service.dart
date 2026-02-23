import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  // No futuro, aqui faremos a derivação da chave KEK para o Hive
}
