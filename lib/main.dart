import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Importando seus novos arquivos (ajuste o caminho se necessário)
import 'screens/credential_details_screen.dart';
import 'screens/credential_form_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/login_screen.dart';
import 'services/security_service.dart';
import 'services/database_service.dart';

void main() async {
  // 1. Garante que os plugins do sistema estejam prontos
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializa o Hive
  await Hive.initFlutter();

  final security = SecurityService();
  bool isFirst = await security.isFirstAccess();

  // Só tentamos abrir a box com chave se NÃO for o primeiro acesso
  if (!isFirst) {
    try {
      final encryptionKey = await security.generateEncryptionKey();

      // Abrimos a box usando a chave gerada!
      // Agora o Hive salva tudo criptografado automaticamente no disco.
      await Hive.openBox(
        'passwords',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      print("Erro ao abrir banco criptografado: $e");
    }
  } else {
    // Se for o primeiro acesso, abrimos sem chave apenas para não dar erro,
    // ou deixamos para abrir após o setup.
    await Hive.openBox('passwords');
  }

  // Inicia o App passando a informação do primeiro acesso
  runApp(PasswMobApp(isFirstAccess: isFirst));
}

class PasswMobApp extends StatelessWidget {
  final bool isFirstAccess;

  const PasswMobApp({super.key, required this.isFirstAccess});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PASSWMOB',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true, // Habilita o visual moderno do Android/iOS
      ),
      // Se for primeiro acesso, vai para /setup, senão vai para /home
      initialRoute: isFirstAccess ? '/setup' : '/login',
      routes: {
        '/setup': (context) => const SetupScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(),
        '/add': (context) =>
            const CredentialFormScreen(), // <--- ADICIONE ESTA LINHA
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _dbService = DatabaseService();
  String _searchQuery = ""; // Para o campo de busca

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PASSWMOB - Cofre'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Filtrar por nome, nota, user ou grupo...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Map>>(
        future: _dbService.getAllCredentials(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma senha salva.'));
          }

          // --- LOGICA DE FILTRO E ORDENAÇÃO ---
          var list = snapshot.data!;

          // 1. Filtro (Alias, Notes, Username e Group)
          var filtered = list.where((item) {
            final alias = (item['alias'] ?? '').toString().toLowerCase();
            final note = (item['note'] ?? '').toString().toLowerCase();
            final user = (item['username'] ?? '').toString().toLowerCase();
            final group = (item['group'] ?? '').toString().toLowerCase();

            return alias.contains(_searchQuery) ||
                note.contains(_searchQuery) ||
                user.contains(_searchQuery) ||
                group.contains(_searchQuery);
          }).toList();

          // 2. Ordenação por Alias (A-Z)
          filtered.sort(
            (a, b) => (a['alias'] ?? '').compareTo(b['alias'] ?? ''),
          );

          // 3. Agrupamento por Categoria
          Map<String, List<Map>> grouped = {};
          for (var item in filtered) {
            String category = item['group'] ?? 'Others';
            grouped.putIfAbsent(category, () => []).add(item);
          }

          final categories = grouped.keys.toList()..sort();

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, catIndex) {
              final category = categories[catIndex];
              final items = grouped[category]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho do Grupo
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  // Itens do Grupo
                  ...items.map((item) {
                    // Precisamos achar o index original para editar/excluir corretamente
                    int originalIndex = list.indexOf(item);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: _getGroupIcon(category),
                        title: Text(item['alias'] ?? ''),
                        subtitle: Text(item['username'] ?? ''),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CredentialDetailsScreen(
                                item: item,
                                index: originalIndex,
                              ),
                            ),
                          );
                          setState(() {});
                        },
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/add');
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Função auxiliar para ícones por categoria
  Widget _getGroupIcon(String group) {
    switch (group) {
      case 'Social Media':
        return const Icon(Icons.people, color: Colors.blue);
      case 'Banking':
        return const Icon(Icons.account_balance, color: Colors.green);
      case 'Work':
        return const Icon(Icons.work, color: Colors.brown);
      case 'Study':
        return const Icon(Icons.school, color: Colors.orange);
      default:
        return const Icon(Icons.vpn_key, color: Colors.grey);
    }
  }
}
