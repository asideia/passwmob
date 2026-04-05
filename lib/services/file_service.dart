import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../models/credential.dart';
import 'database_service.dart';

class FileService {
  final DatabaseService _dbService = DatabaseService();

  /// Importa credenciais de um arquivo CSV selecionado pelo usuário.
  Future<int> importCredentialsFromCsv() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) return 0;

    final bytes = result.files.single.bytes!;
    // Usamos allowMalformed para evitar quebras por caracteres especiais
    final csvString = utf8.decode(bytes, allowMalformed: true);
    final List<List<dynamic>> csvTable = const CsvToListConverter().convert(
      csvString,
    );

    if (csvTable.isEmpty) return 0;

    final List<dynamic> header = csvTable[0];
    final Map<String, int> col = {
      'alias': header.indexOf('alias'),
      'group': header.indexOf('group'),
      'user': header.indexOf('user'),
      'passa': header.indexOf('passa'),
      'url': header.indexOf('url'),
      'notes': header.indexOf('notes'),
      'otp_secret': header.indexOf('otp_secret'),
      'otp_label': header.indexOf('otp_label'),
    };

    // Verifica se colunas essenciais existem
    if (col['alias'] == -1 || col['group'] == -1) {
      throw Exception(
        "Formato CSV inválido. Colunas 'alias' e 'group' são obrigatórias.",
      );
    }

    int count = 0;

    // Função auxiliar para extrair dados com segurança
    String? getSafeValue(List<dynamic> row, String colName) {
      final index = col[colName];
      if (index != null && index != -1 && index < row.length) {
        final val = row[index].toString().trim();
        return val.isEmpty ? null : val;
      }
      return null;
    }

    for (int i = 1; i < csvTable.length; i++) {
      final row = csvTable[i];
      if (row.isEmpty || row[0].toString().trim().isEmpty) continue;

      final credential = Credential(
        alias: getSafeValue(row, 'alias') ?? 'Sem Título',
        group: getSafeValue(row, 'group') ?? 'Others',
        username: getSafeValue(row, 'user'),
        password: getSafeValue(row, 'passa'),
        url: getSafeValue(row, 'url'),
        note: getSafeValue(row, 'notes'),
        twoFactorSecret: getSafeValue(row, 'otp_secret'),
        twoFactorLabel: getSafeValue(row, 'otp_label'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _dbService.saveCredential(credential);
      count++;
    }
    return count;
  }

  /// Exporta todas as credenciais do banco para um arquivo CSV.
  Future<String?> exportCredentialsToCsv() async {
    final credentials = await _dbService.getAllCredentials();
    if (credentials.isEmpty) return null;

    List<List<dynamic>> rows = [];

    // Cabeçalho
    rows.add([
      "alias",
      "group",
      "user",
      "passa",
      "url",
      "notes",
      "otp_secret",
      "otp_label",
    ]);

    // Dados
    for (var item in credentials) {
      rows.add([
        item.alias,
        item.group,
        item.username ?? "",
        item.password ?? "",
        item.url ?? "",
        item.note ?? "",
        item.twoFactorSecret ?? "",
        item.twoFactorLabel ?? "",
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final Uint8List bytes = Uint8List.fromList(utf8.encode(csvData));

    // No Android/iOS, o parâmetro 'bytes' é obrigatório para que o sistema gerencie a gravação.
    // O plugin cuidará de salvar o conteúdo dos bytes no arquivo escolhido pelo usuário.
    return await FilePicker.platform.saveFile(
      dialogTitle: 'Salvar exportação',
      fileName: 'passwmob_export_${DateTime.now().millisecondsSinceEpoch}.csv',
      bytes: bytes,
    );
  }
}
