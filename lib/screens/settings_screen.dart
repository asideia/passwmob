import 'package:flutter/material.dart';
import '../main.dart'; // Para acessar o themeNotifier
import '../services/security_service.dart';
import '../services/database_service.dart';
import '../services/file_service.dart';
import 'change_master_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _securityService = SecurityService();
  final _dbService = DatabaseService();
  final _fileService = FileService();

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset de Fábrica'),
        content: const Text(
          'Isso apagará TODAS as suas senhas e a senha mestre permanentemente. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () async {
              await _dbService.clearAll();
              await _securityService.resetAll();
              if (mounted) {
                // Reinicia o app do zero
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/setup', (route) => false);
              }
            },
            child: const Text(
              'APAGAR TUDO',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _importData() async {
    try {
      final count = await _fileService.importCredentialsFromCsv();
      if (mounted) {
        if (count > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$count credenciais importadas!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhum dado importado.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _exportData() async {
    try {
      final path = await _fileService.exportCredentialsToCsv();
      if (mounted && path != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Arquivo salvo em: $path')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Aparência'),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (_, ThemeMode currentMode, __) {
              return ListTile(
                leading: Icon(
                  currentMode == ThemeMode.dark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
                title: const Text('Tema do Aplicativo'),
                subtitle: Text(
                  currentMode == ThemeMode.dark ? 'Escuro' : 'Claro',
                ),
                trailing: Switch(
                  value: currentMode == ThemeMode.dark,
                  onChanged: (isDark) {
                    themeNotifier.value = isDark
                        ? ThemeMode.dark
                        : ThemeMode.light;
                  },
                ),
              );
            },
          ),

          const Divider(),
          const _SectionHeader(title: 'Segurança'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Alterar Senha Mestre'),
            subtitle: const Text('Trocar a senha de acesso ao cofre'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangeMasterPasswordScreen(),
                ),
              );
            },
          ),

          const Divider(),
          const _SectionHeader(title: 'Dados e Armazenamento'),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Local do Banco'),
            subtitle: const Text('Memória Interna Criptografada'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text(
              'Limpar Base de Dados',
              style: TextStyle(color: Colors.redAccent),
            ),
            subtitle: const Text('Remove todas as credenciais salvas'),
            onTap: _showResetDialog,
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text(
              'Importar CSV',
              style: TextStyle(color: Colors.redAccent),
            ),
            subtitle: const Text('Adicionar credenciais em massa'),
            onTap: _importData,
          ),
          ListTile(
            leading: const Icon(Icons.download_for_offline_outlined),
            title: const Text(
              'Exportar CSV',
              style: TextStyle(color: Colors.redAccent),
            ),
            subtitle: const Text('Backup local das suas senhas'),
            onTap: _exportData,
          ),

          const Divider(),
          const _SectionHeader(title: 'Sobre'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('PASSWMOB'),
            subtitle: Text(
              'Versão 1.0.0-Beta\nDesenvolvido com ❤︎ por AsIdeia.',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
