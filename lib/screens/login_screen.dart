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
    // CORREÇÃO: Usamos o authenticate() que compara os Hashes internamente
    final isValid = await _security.authenticate(_passController.text);

    if (isValid) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      setState(() {
        _errorMessage = "Senha Master incorreta!";
      });
    }
  }

  void _authenticateWithBio() async {
    bool canBio = await _bioService.canAuthenticate();
    if (canBio) {
      bool success = await _bioService.authenticate();
      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateWithBio();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          // Adicionado para evitar erro de overflow no teclado
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_person,
                size: 100,
                color: Color(0xFFB11B1F),
              ),
              const SizedBox(height: 30),
              const Text(
                'Bloqueado',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 40),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB11B1F),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Desbloquear'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _authenticateWithBio,
                icon: const Icon(Icons.fingerprint),
                label: const Text("Usar Biometria"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
