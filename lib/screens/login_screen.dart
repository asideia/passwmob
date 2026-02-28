import 'package:flutter/material.dart';
import '../services/security_service.dart';
import '../services/bio_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passController = TextEditingController();
  final _security = SecurityService();
  final _bioService = BioService();

  bool _obscurePassword = true;
  String? _errorMessage;

  void _unlockApp() async {
    // 1. Pegamos a senha master real que salvamos no setup
    final savedMaster = await _security.getMasterPassword();

    if (_passController.text == savedMaster) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      setState(() {
        _errorMessage = "Senha Master incorreta!";
      });
    }
  }

  // Função para tentar biometria automaticamente ou via botão
  void _authenticateWithBio() async {
    bool canBio = await _bioService.canAuthenticate();
    if (canBio) {
      bool success = await _bioService.authenticate();
      if (success && mounted) {
        // Se a biometria der certo, vamos para a Home
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      print("Biometria não disponível neste dispositivo");
    }
  }

  @override
  void initState() {
    super.initState();
    // Opcional: Tentar biometria assim que a tela abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateWithBio();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'PASSWMOB Bloqueado',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _passController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Digite sua Senha Master',
                  errorText: _errorMessage,
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _unlockApp,
                  child: const Text('Desbloquear'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
