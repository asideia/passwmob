import 'package:flutter/material.dart';
import '../services/security_service.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _passController = TextEditingController();
  final _saltController = TextEditingController();
  final _security = SecurityService();

  // 1. Criamos a variável que controla a visibilidade
  bool _obscurePassword = true;

  void _saveAndStart() async {
    if (_passController.text.isNotEmpty && _saltController.text.isNotEmpty) {
      await _security.setupFirstAccess(
        _passController.text,
        _saltController.text,
      );
      // Após salvar, envia o usuário para a Home
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text('Defina sua Senha Master e um Salt Secreto.'),
              const SizedBox(height: 20),

              // O Campo da Senha Master atualizado:
              TextField(
                controller: _passController,
                obscureText: _obscurePassword, // Usa a nossa variável aqui
                decoration: InputDecoration(
                  labelText: 'Senha Master',
                  border: const OutlineInputBorder(),
                  // 2. Adicionamos o ícone no final do campo (suffixIcon)
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      // 3. O setState avisa o Flutter para redesenhar a tela
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),
              TextField(
                controller: _saltController,
                decoration: const InputDecoration(
                  labelText: 'Seu Secret Salt (ex: frase ou palavra)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _saveAndStart,
                child: const Text('Configurar PASSWMOB'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
