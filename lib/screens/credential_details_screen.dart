import 'package:flutter/material.dart';
import 'package:passwmob/screens/qr_scanner_screen.dart';
import '../models/credential.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart'; // Certifique-se de ter o intl no pubspec

class CredentialDetailsScreen extends StatefulWidget {
  final Credential item;
  final int index;

  const CredentialDetailsScreen({
    super.key,
    required this.item,
    required this.index,
  });

  @override
  State<CredentialDetailsScreen> createState() =>
      _CredentialDetailsScreenState();
}

class _CredentialDetailsScreenState extends State<CredentialDetailsScreen> {
  final _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _aliasController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _urlController;
  late TextEditingController _noteController;
  late String _selectedGroup;

  // Variável para controlar a visibilidade da senha
  bool _obscurePassword = true;

  // Variáveis para controlar 2FA durante a edição
  String? _current2FASecret;
  String? _current2FALabel;

  @override
  void initState() {
    super.initState();
    _aliasController = TextEditingController(text: widget.item.alias);
    _usernameController = TextEditingController(
      text: widget.item.username ?? '',
    );
    _passwordController = TextEditingController(
      text: widget.item.password ?? '',
    );
    _urlController = TextEditingController(text: widget.item.url ?? '');
    _noteController = TextEditingController(text: widget.item.note ?? '');
    _selectedGroup = widget.item.group;
    _current2FASecret = widget.item.twoFactorSecret;
    _current2FALabel = widget.item.twoFactorLabel;
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      // Criamos um NOVO objeto com os dados atualizados
      final updatedCredential = Credential(
        alias: _aliasController.text,
        group: _selectedGroup,
        username: _usernameController.text,
        password: _passwordController.text,
        note: _noteController.text,
        url: _urlController.text,
        twoFactorSecret: _current2FASecret,
        twoFactorLabel: _current2FALabel,
        createdAt: widget.item.createdAt, // Mantém a data original
        updatedAt: DateTime.now(), // Atualiza a data de modificação
      );

      await _dbService.updateCredential(widget.index, updatedCredential);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alterações salvas com sucesso!')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _confirmDelete() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Credencial'),
        content: const Text('Tem certeza que deseja apagar esta senha?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbService.deleteCredential(widget.index);
      if (mounted) Navigator.pop(context);
    }
  }

  void _showManualOtpDialog() async {
    final secretController = TextEditingController();
    final labelController = TextEditingController(text: "Código Manual");

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurar 2FA Manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'Identificador (ex: Conta)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: secretController,
              decoration: const InputDecoration(labelText: 'Chave Secreta'),
              autocorrect: false,
              enableSuggestions: false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (secretController.text.trim().isNotEmpty) {
                setState(() {
                  _current2FASecret = secretController.text.trim();
                  _current2FALabel = labelController.text.trim();
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _confirmDelete,
          ),
          IconButton(icon: const Icon(Icons.check), onPressed: _saveChanges),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informações de Sistema (Read Only)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoTile("Criado em", _formatDate(widget.item.createdAt)),
                  _infoTile(
                    "Atualizado em",
                    _formatDate(widget.item.updatedAt),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Campos Editáveis
              _buildTextField('Nome / Alias', _aliasController, Icons.label),
              const SizedBox(height: 16),

              _buildDropdownGroup(),
              const SizedBox(height: 16),

              _buildTextField('Usuário', _usernameController, Icons.person),
              const SizedBox(height: 16),

              _buildTextField(
                'Senha',
                _passwordController,
                Icons.lock,
                isPassword: true,
              ),
              const SizedBox(height: 16),

              _buildTextField('URL', _urlController, Icons.link),
              const SizedBox(height: 16),

              _buildTextField(
                'Notas',
                _noteController,
                Icons.note,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Seção de 2FA
              const Text(
                "Autenticação 2FA",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_current2FASecret != null)
                ListTile(
                  tileColor: Colors.blueGrey.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(Icons.vibration),
                  title: Text(_current2FALabel ?? "Código 2FA Ativo"),
                  subtitle: const Text("Configurado"),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => setState(() => _current2FASecret = null),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QrScannerScreen(),
                            ),
                          );

                          if (result != null && result is Map<String, String>) {
                            setState(() {
                              _current2FASecret = result['secret'];
                              _current2FALabel = result['label'];
                            });
                          }
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text("QR Code"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showManualOtpDialog,
                        icon: const Icon(Icons.edit),
                        label: const Text("Manual"),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      // obscureText: isPassword,
      obscureText: isPassword ? _obscurePassword : false,
      maxLines: isPassword ? 1 : maxLines,
      // decoration: InputDecoration(
      //   labelText: label,
      //   prefixIcon: Icon(icon),
      //   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      // ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        // Adiciona o ícone do olhinho apenas se for campo de senha
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
      ),
      // validator: (value) =>
      //     value == null || value.isEmpty ? 'Obrigatório' : null,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Obrigatório';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownGroup() {
    final groups = ['Social Media', 'Banking', 'Work', 'Study', 'Others'];
    return DropdownButtonFormField<String>(
      value: groups.contains(_selectedGroup) ? _selectedGroup : 'Others',
      decoration: InputDecoration(
        labelText: 'Grupo',
        prefixIcon: const Icon(Icons.group_work),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: groups
          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
          .toList(),
      onChanged: (value) => setState(() => _selectedGroup = value!),
    );
  }
}
