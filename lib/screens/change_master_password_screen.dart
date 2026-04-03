import 'package:flutter/material.dart';
import '../services/security_service.dart';

class ChangeMasterPasswordScreen extends StatefulWidget {
  const ChangeMasterPasswordScreen({super.key});

  @override
  State<ChangeMasterPasswordScreen> createState() =>
      _ChangeMasterPasswordScreenState();
}

class _ChangeMasterPasswordScreenState
    extends State<ChangeMasterPasswordScreen> {
  final _securityService = SecurityService();
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Validar se a senha atual está correta (comparando hashes no SecurityService)
      final isCurrentCorrect = await _securityService.authenticate(
        _currentPasswordController.text,
      );

      if (!isCurrentCorrect) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A senha atual está incorreta.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // 2. Salvar o novo hash da senha mestre
      // Como separamos a Master Password da Encryption Key, os dados no Hive
      // permanecem acessíveis após essa troca.
      await _securityService.saveMasterPassword(_newPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Senha mestre alterada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Segurança')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.security_update_good,
                size: 64,
                color: Color(0xFFB11B1F),
              ),
              const SizedBox(height: 24),
              const Text(
                'Alterar Senha Mestre',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sua senha mestre é a única forma de acessar seus dados. Se você a alterar, certifique-se de memorizá-la.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              _buildPasswordField(
                label: 'Senha Atual',
                controller: _currentPasswordController,
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              const SizedBox(height: 20),

              _buildPasswordField(
                label: 'Nova Senha Mestre',
                controller: _newPasswordController,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                validator: (v) {
                  if (v == null || v.length < 8)
                    return 'A senha deve ter pelo menos 8 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _buildPasswordField(
                label: 'Confirmar Nova Senha',
                controller: _confirmPasswordController,
                obscure: true, // Sempre oculto
                validator: (v) {
                  if (v != _newPasswordController.text)
                    return 'As senhas não coincidem';
                  return null;
                },
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isLoading ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFFB11B1F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'CONFIRMAR ALTERAÇÃO',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    VoidCallback? onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator ?? (v) => v!.isEmpty ? 'Campo obrigatório' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: onToggle != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: onToggle,
              )
            : null,
      ),
    );
  }
}
