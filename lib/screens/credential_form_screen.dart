import 'package:flutter/material.dart';
import '../models/credential.dart';
import '../services/database_service.dart';

class CredentialFormScreen extends StatefulWidget {
  const CredentialFormScreen({super.key});

  @override
  State<CredentialFormScreen> createState() => _CredentialFormScreenState();
}

class _CredentialFormScreenState extends State<CredentialFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();

  // Controllers para capturar os textos
  final _aliasController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedGroup = 'Others';
  bool _isSaving = false;
  bool _obscurePassword = true;

  final List<String> _groups = [
    'Others',
    'Social Media',
    'Banking',
    'Work',
    'Study',
    'Streaming',
    'Shopping',
  ];

  void _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        final newCredential = Credential(
          alias: _aliasController.text.trim(),
          group: _selectedGroup,
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          url: _urlController.text.trim(),
          note: _noteController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // O AWAIT aqui é crucial para garantir que a Box abra
        // com a chave de criptografia antes de tentar escrever.
        await _dbService.saveCredential(newCredential);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Credencial salva com sucesso!')),
          );
          Navigator.pop(context); // Volta para a Home
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Erro ao Salvar'),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Credencial'),
        actions: [
          if (!_isSaving)
            IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Nome / Alias
              TextFormField(
                controller: _aliasController,
                decoration: const InputDecoration(
                  labelText: 'Nome / Alias (Ex: Gmail)',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) => v!.isEmpty ? 'Informe um nome' : null,
              ),
              const SizedBox(height: 16),

              // Grupo / Categoria
              DropdownButtonFormField<String>(
                value: _selectedGroup,
                decoration: const InputDecoration(
                  labelText: 'Grupo / Categoria',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _groups.map((g) {
                  return DropdownMenuItem(value: g, child: Text(g));
                }).toList(),
                onChanged: (val) => setState(() => _selectedGroup = val!),
              ),
              const SizedBox(height: 16),

              // Usuário
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Usuário / E-mail',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              // Senha
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock_outline),
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
                // validator: (v) => v!.isEmpty ? 'Informe a senha' : null,
              ),
              const SizedBox(height: 16),

              // URL
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL / Site',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 16),

              // Notas
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas / Observações',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 30),

              // Botão Salvar
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'SALVANDO...' : 'SALVAR CREDENCIAL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
