import 'package:hive_flutter/hive_flutter.dart';
import 'security_service.dart';

class DatabaseService {
  final _security = SecurityService();
  static const _boxName = 'passwords';

  // Abre a caixa do Hive com criptografia real
  Future<Box> _getEncryptedBox() async {
    final encryptionKey = await _security.generateEncryptionKey();
    return await Hive.openBox(
      _boxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  // Salva uma credencial
  Future<void> saveCredential(Map<String, dynamic> data) async {
    final box = await _getEncryptedBox();
    await box.add(
      data,
    ); // O Hive criptografa o Map inteiro automaticamente aqui
  }

  // Busca todas as senhas para mostrar na Home
  Future<List<Map>> getAllCredentials() async {
    final box = await _getEncryptedBox();
    return box.values.cast<Map>().toList();
  }

  // Deletar usando o index da lista
  Future<void> deleteCredential(int index) async {
    final box = await _getEncryptedBox();
    await box.deleteAt(index);
  }

  // Editar usando o index
  Future<void> updateCredential(int index, Map<String, dynamic> data) async {
    final box = await _getEncryptedBox();
    await box.putAt(index, data);
  }

  // No seu DatabaseService
  Future<String?> getMasterPassword() async {
    var box = await Hive.openBox('settings');
    return box.get('master_password');
  }

  Future<void> saveMasterPassword(String newPassword) async {
    var box = await Hive.openBox('settings');
    await box.put('master_password', newPassword);
  }
}
