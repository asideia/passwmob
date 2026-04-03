import 'package:hive_flutter/hive_flutter.dart';
import '../models/credential.dart';
import 'security_service.dart';

class DatabaseService {
  static const String _boxName = 'passwords';
  final SecurityService _security = SecurityService();

  /// MÉTODO CHAVE: Garante que a box esteja aberta e pronta para uso.
  /// Se a box fechar por falta de memória ou erro de sistema, este método a reabre.
  Future<Box<Credential>> _getOpenBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<Credential>(_boxName);
    }

    try {
      // Busca a chave de criptografia gerada no SecurityService
      final encryptionKey = await _security.generateEncryptionKey();

      return await Hive.openBox<Credential>(
        _boxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      // Caso haja erro na chave (ex: mudança de versão), tenta abrir sem para não travar o app
      // ou propaga o erro para ser tratado na UI.
      return await Hive.openBox<Credential>(_boxName);
    }
  }

  /// Retorna todas as credenciais (Garante abertura antes)
  Future<List<Credential>> getAllCredentials() async {
    final box = await _getOpenBox();
    return box.values.toList();
  }

  /// Salva uma nova credencial (Garante abertura antes)
  Future<void> saveCredential(Credential credential) async {
    final box = await _getOpenBox();
    try {
      await box.add(credential);
    } catch (e) {
      throw Exception("Erro ao salvar no Hive: $e");
    }
  }

  /// Atualiza uma credencial existente
  Future<void> updateCredential(int index, Credential credential) async {
    final box = await _getOpenBox();
    try {
      await box.putAt(index, credential);
    } catch (e) {
      throw Exception("Erro ao atualizar no Hive: $e");
    }
  }

  /// Deleta uma credencial
  Future<void> deleteCredential(int index) async {
    final box = await _getOpenBox();
    try {
      await box.deleteAt(index);
    } catch (e) {
      throw Exception("Erro ao deletar no Hive: $e");
    }
  }

  /// Limpa toda a base (Reset de Fábrica)
  Future<void> clearAll() async {
    final box = await _getOpenBox();
    try {
      await box.clear();
    } catch (e) {
      throw Exception("Erro ao limpar base de dados: $e");
    }
  }
}
