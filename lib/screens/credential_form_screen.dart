import 'package:flutter/material.dart';
import '../services/database_service.dart';

class CredentialFormScreen extends StatefulWidget {
  const CredentialFormScreen({super.key});

  @override
  State<CredentialFormScreen> createState() => _CredentialFormScreenState();
}

class _CredentialFormScreenState extends State<CredentialFormScreen> {
  final _formKey =
      GlobalKey<FormState>(); // Para validar se os campos estão vazios
  final _dbService = DatabaseService();

  // Nossos campos (conforme seu planejamento)
  String _selectedGroup = 'Social Media';
  final _aliasController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();

  // Lista de grupos (podemos expandir depois)
  final List<String> _groups = [
    'Social Media',
    'Study',
    'Work',
    'Banking',
    'Others',
  ];

  void _save() async {
    if (_formKey.currentState!.validate()) {
      // Montamos o objeto com os dados do formulário
      final newEntry = {
        'group': _selectedGroup,
        'alias': _aliasController.text,
        'username': _usernameController.text,
        'password': _passwordController.text,
        'url': _urlController.text,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _dbService.saveCredential(newEntry);

      if (mounted) {
        Navigator.pop(context); // Fecha a tela e volta para a Home
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Credencial')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Seletor de Grupo (Dropdown)
              DropdownButtonFormField<String>(
                value: _selectedGroup,
                decoration: const InputDecoration(
                  labelText: 'Grupo / Categoria',
                ),
                items: _groups
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedGroup = val!),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _aliasController,
                decoration: const InputDecoration(
                  labelText: 'Alias (Identificador)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username / E-mail (Opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password (Opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL / Site (Opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Salvar Credencial'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
