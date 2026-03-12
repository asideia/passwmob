import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necessário para o Clipboard
import '../services/database_service.dart';

class CredentialDetailsScreen extends StatefulWidget {
  final Map item;
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

  // Estado de controle
  bool _isEditing = false;
  bool _obscure = true;

  late TextEditingController _aliasController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _urlController;
  late TextEditingController _noteController;
  late TextEditingController _secretsController;
  late String _selectedGroup;

  final List<String> _groups = [
    'Social Media',
    'Study',
    'Work',
    'Banking',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    // Inicializa os campos com os valores que vieram do banco
    _aliasController = TextEditingController(text: widget.item['alias']);
    _usernameController = TextEditingController(text: widget.item['username']);
    _passwordController = TextEditingController(text: widget.item['password']);
    _urlController = TextEditingController(text: widget.item['url']);
    _selectedGroup = widget.item['group'] ?? 'Others';
    _noteController = TextEditingController(text: widget.item['note'] ?? '');
    _secretsController = TextEditingController(
      text: widget.item['secrets'] ?? '',
    );
  }

  // Função para copiar texto e mostrar um aviso (SnackBar)
  void _copyToClipboard(String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Credencial"),
        content: const Text(
          "Isso apagará os dados permanentemente. Confirmar?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              await _dbService.deleteCredential(widget.index);
              if (mounted) {
                Navigator.pop(context); // Fecha o alerta
                Navigator.pop(context); // Volta para a Home
              }
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      // Criamos o mapa com TODOS os campos definidos no seu escopo de prioridades
      final updatedData = {
        'alias': _aliasController.text, // Necessário
        'group': _selectedGroup, // Necessário
        'username': _usernameController.text, // Opcional
        'password': _passwordController.text, // Opcional
        'url': _urlController.text, // Opcional
        'note': _noteController.text, // Opcional (Novo)
        'secrets': _secretsController.text, // Opcional (Novo)
        'createdAt':
            widget.item['createdAt'], // Mantém a data de criação original
        'updatedAt': DateTime.now()
            .toIso8601String(), // Marca a última alteração
      };

      try {
        // 1. Atualiza no Banco de Dados (Hive)
        await _dbService.updateCredential(widget.index, updatedData);

        // 2. Feedback Visual para o usuário
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Alterações salvas com sucesso!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // 3. Transição de estado: sai do modo de edição e volta para visualização
          setState(() {
            _isEditing = false;
          });
        }
      } catch (e) {
        // Caso ocorra algum erro no banco (ex: falta de espaço ou chave corrompida)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Função para formatar a data de forma legível
  String _formatDate(dynamic date) {
    if (date == null) return "N/A";
    DateTime dateTime;
    if (date is String) {
      dateTime = DateTime.parse(date);
    } else {
      dateTime = date;
    }
    return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editando' : 'Detalhes'),
        leading: _isEditing
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  // Se cancelar, restauramos os valores originais do controlador
                  setState(() {
                    _aliasController.text = widget.item['alias'];
                    _usernameController.text = widget.item['username'];
                    _passwordController.text = widget.item['password'];
                    _urlController.text = widget.item['url'];
                    _selectedGroup = widget.item['group'] ?? 'Others';
                    _isEditing = false;
                  });
                },
              )
            : null, // Mantém o botão "voltar" padrão do Flutter quando não edita
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isEditing)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    "Dica: Pressione e segure um campo para copiar.",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),

              // Campo Grupo
              DropdownButtonFormField<String>(
                value: _selectedGroup,
                items: _groups
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: _isEditing
                    ? (val) => setState(() => _selectedGroup = val!)
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Grupo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // Reutilizamos essa lógica para os campos de texto
              _buildEditableField(
                controller: _aliasController,
                label: 'Alias',
                enabled: _isEditing,
              ),
              const SizedBox(height: 15),

              _buildEditableField(
                controller: _usernameController,
                label: 'Username / E-mail',
                enabled: _isEditing,
              ),
              const SizedBox(height: 15),

              // Campo de Senha com Olhinho
              GestureDetector(
                onLongPress: () =>
                    _copyToClipboard(_passwordController.text, 'Senha'),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  enabled: _isEditing,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              _buildEditableField(
                controller: _urlController,
                label: 'URL / Site',
                enabled: _isEditing,
              ),

              // ... campos anteriores (Alias, Username, Password, URL)
              const SizedBox(height: 15),
              _buildEditableField(
                controller: _noteController,
                label: 'Notes',
                enabled: _isEditing,
                maxLines: 3,
              ),

              const SizedBox(height: 15),
              _buildEditableField(
                controller: _secretsController,
                label: 'Secrets / Passkeys',
                enabled: _isEditing,
                maxLines: 5, // Visualização maior para chaves complexas
              ),

              // SEÇÃO DE AUDITORIA (Datas do Sistema)
              if (!_isEditing) ...[
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 10),
                Text(
                  "METADADOS DO REGISTRO",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB11B1F).withOpacity(0.8),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 15),
                _buildAuditInfo(
                  Icons.add_circle_outline,
                  "Criado em:",
                  _formatDate(widget.item['createdAt']),
                  isDark,
                ),
                const SizedBox(height: 8),
                _buildAuditInfo(
                  Icons.history,
                  "Última alteração:",
                  _formatDate(widget.item['updatedAt']),
                  isDark,
                ),
                const SizedBox(height: 60),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helper para criar campos que podem ser copiados
  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required bool enabled,
    int? maxLines = 1, // Por padrão 1 linha, mas aceita mais
  }) {
    return GestureDetector(
      onLongPress: () => _copyToClipboard(controller.text, label),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: !enabled ? const Icon(Icons.copy_all, size: 18) : null,
        ),
      ),
    );
  }

  // Widget para mostrar as datas (não editáveis)
  Widget _buildAuditInfo(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black87,
            fontFamily: 'monospace', // Estilo técnico para datas
          ),
        ),
      ],
    );
  }
}
