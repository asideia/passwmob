import 'package:flutter/material.dart';
import '../main.dart';
import 'change_master_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Removido o _isDarkMode local, pois usamos o themeNotifier global

  @override
  Widget build(BuildContext context) {
    // Detecta se o tema atual é dark para lógica de cores pontuais
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          // Seção: Aparência
          _buildSectionHeader('Aparência'),
          SwitchListTile(
            secondary: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              // O ícone agora herda a cor do tema automaticamente
            ),
            title: const Text('Modo Escuro'),
            value: isDark,
            activeColor: const Color(0xFFB11B1F), // Vermelho do seu logo
            onChanged: (bool isDarkValue) {
              // Atualiza o estado global
              themeNotifier.value = isDarkValue
                  ? ThemeMode.dark
                  : ThemeMode.light;
              // O setState reconstrói este widget para animar o toggle
              setState(() {});
            },
          ),

          // Divider dinâmico que funciona em ambos os modos
          Divider(
            color: isDark ? Colors.white10 : Colors.black12,
            indent: 16,
            endIndent: 16,
          ),

          // Seção: Segurança
          _buildSectionHeader('Segurança'),
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('Alterar Senha Master'),
            subtitle: const Text('Atualize sua credencial de acesso ao cofre'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangeMasterPasswordScreen(),
                ),
              );
            },
          ),

          Divider(
            color: isDark ? Colors.white10 : Colors.black12,
            indent: 16,
            endIndent: 16,
          ),

          // Seção: Dados (Escopo Futuro)
          _buildSectionHeader('Dados'),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: const Text('Exportar Credenciais'),
            subtitle: const Text('Em breve - Backup criptografado'),
            enabled: false, // O Flutter já cuida da cor "esmaecida"
          ),
          ListTile(
            leading: const Icon(Icons.file_open_outlined),
            title: const Text('Importar Dados'),
            enabled: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFB11B1F), // Vermelho Shield do PASSWMOB
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
