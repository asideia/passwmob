import 'package:flutter/material.dart';
import '../services/security_service.dart'; // Importando o serviço correto

class ChangeMasterPasswordScreen extends StatefulWidget {
  const ChangeMasterPasswordScreen({super.key});

  @override
  State<ChangeMasterPasswordScreen> createState() =>
      _ChangeMasterPasswordScreenState();
}

class _ChangeMasterPasswordScreenState
    extends State<ChangeMasterPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _security = SecurityService();

  // Controllers para validação atual
  final _currentPasswordController = TextEditingController();
  final _currentSaltController = TextEditingController();

  // Controllers para novos dados
  final _newPasswordController = TextEditingController();
  final _newSaltController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureText = true;

  void _updatePassword() async {
    if (_formKey.currentState!.validate()) {
      // 1. Buscar os dados que estão atualmente no Secure Storage
      final storedPassword = await _security.getMasterPassword();
      final storedSalt = await _security.getSecretSalt();

      // 2. Validar se o que o usuário digitou como "Atual" está correto
      if (_currentPasswordController.text != storedPassword ||
          _currentSaltController.text != storedSalt) {
        _showSnackBar('Senha ou Salt atuais incorretos!', Colors.red);
        return;
      }

      // 3. Salvar as novas credenciais
      await _security.setupFirstAccess(
        _newPasswordController.text,
        _newSaltController.text,
      );

      _showSnackBar('Credenciais atualizadas com sucesso!', Colors.green);
      if (mounted) Navigator.pop(context);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // Função auxiliar para os campos de senha
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: _obscureText,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFFB11B1F),
          ),
          onPressed: () => setState(() => _obscureText = !_obscureText),
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usamos o tema do contexto para cores dinâmicas
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Alterar Acesso Master')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Atenção: A alteração da senha e do salt afeta a chave de criptografia do cofre.',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // SEÇÃO ATUAL
              _buildSectionTitle('CONFIRMAÇÃO ATUAL'),
              _buildPasswordField(
                controller: _currentPasswordController,
                label: 'Senha Master Atual',
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _currentSaltController,
                decoration: const InputDecoration(labelText: 'Salt Atual'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(),
              ),

              // SEÇÃO NOVA
              _buildSectionTitle('NOVAS CREDENCIAIS'),
              _buildPasswordField(
                controller: _newPasswordController,
                label: 'Nova Senha Master',
                validator: (v) =>
                    v!.length < 6 ? 'Mínimo de 6 caracteres' : null,
              ),
              const SizedBox(height: 10),
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirme a Nova Senha',
                validator: (v) => v != _newPasswordController.text
                    ? 'As senhas não coincidem'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _newSaltController,
                decoration: const InputDecoration(labelText: 'Novo Salt'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB11B1F),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'ATUALIZAR ACESSO',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFFB11B1F),
        ),
      ),
    );
  }
}
