import 'package:flutter/material.dart';
import '../services/database_service.dart';

class CredentialFormScreen extends StatefulWidget {
  const CredentialFormScreen({super.key});

  @override
  State<CredentialFormScreen> createState() => _CredentialFormScreenState();
}

class _CredentialFormScreenState extends State<CredentialFormScreen> {
  bool _obscurePassword = true; // Nova variável de estado

  final _noteController = TextEditingController();

  final _formKey =
      GlobalKey<FormState>(); // Para validar se os campos estão vazios
  final _dbService = DatabaseService();

  // Nossos campos (conforme seu planejamento)
  String _selectedGroup = 'Social Media';
  final _aliasController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  final _secretsController = TextEditingController();

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
      final newEntry = {
        'alias': _aliasController.text,
        'group': _selectedGroup,
        'username': _usernameController.text,
        'password': _passwordController.text,
        'note': _noteController.text, // Novo campo
        'secrets': _secretsController.text,
        'url': _urlController.text,
        'createdAt': DateTime.now().toIso8601String(),
      };
      await _dbService.saveCredential(newEntry);
      if (mounted) Navigator.pop(context);
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
                initialValue: _selectedGroup,
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
                obscureText: _obscurePassword, // Usa a variável
                decoration: InputDecoration(
                  labelText: 'Password (Opcional)',
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

              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL / Site (Opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              // Campo Note (Opcional)
              TextFormField(
                controller: _noteController,
                maxLines: 3, // Começa com 3 linhas, mas expande
                decoration: const InputDecoration(
                  labelText: 'Notes (App, system, info, etc.)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // Campo Secrets (Opcional)
              TextFormField(
                controller: _secretsController,
                maxLines: null, // Expansão infinita para chaves longas
                decoration: const InputDecoration(
                  labelText: 'Secrets (Passkeys, extra keys, etc.)',
                  border: OutlineInputBorder(),
                  helperText:
                      'Cole aqui suas chaves de segurança ou segredos extras.',
                ),
              ),

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
