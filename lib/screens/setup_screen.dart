import 'package:flutter/material.dart';
import '../services/security_service.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _passController = TextEditingController();
  final _confirmController =
      TextEditingController(); // Troquei o Salt por Confirmação
  final _security = SecurityService();

  bool _obscurePassword = true;

  void _saveAndStart() async {
    if (_passController.text.isNotEmpty) {
      if (_passController.text != _confirmController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('As senhas não coincidem!')),
        );
        return;
      }

      // CORREÇÃO: Passamos apenas 1 argumento conforme definido no SecurityService
      await _security.setupFirstAccess(_passController.text);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuração Inicial')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.security, size: 80, color: Color(0xFFB11B1F)),
              const SizedBox(height: 20),
              const Text(
                'Defina sua Senha Master.\nEsta senha criptografa todo o seu cofre.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _passController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Nova Senha Master',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _confirmController,
                obscureText: _obscurePassword,
                decoration: const InputDecoration(
                  labelText: 'Confirme a Senha Master',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveAndStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB11B1F),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Configurar PASSWMOB'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
