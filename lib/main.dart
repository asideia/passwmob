import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Importando seus novos arquivos (ajuste o caminho se necessário)
import 'screens/credential_details_screen.dart';
import 'screens/credential_form_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/login_screen.dart';
import 'services/security_service.dart';
import 'services/database_service.dart';

ThemeData _buildPasswMobTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark, // Define o modo escuro como padrão
    primaryColor: const Color(0xFFB11B1F),
    scaffoldBackgroundColor: Colors.black,

    // Configuração das cores de superfície (Cards, Diálogos)
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFB11B1F),
      secondary: Colors.white,
      surface: Color(0xFF121212), // Um cinza bem escuro para os cards
      onSurface: Colors.white,
    ),

    // Estilo padrão dos Inputs (Fields)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFB11B1F), width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
    ),

    // Estilo dos Botões Elevados
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFB11B1F),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),

    // Estilo da AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
  );
}

// Função auxiliar para ícones por categoria
// Widget _getGroupIcon(String group) {
//   switch (group) {
//     case 'Social Media':
//       return const Icon(Icons.people, color: Colors.blue);
//     case 'Banking':
//       return const Icon(Icons.account_balance, color: Colors.green);
//     case 'Work':
//       return const Icon(Icons.work, color: Colors.brown);
//     case 'Study':
//       return const Icon(Icons.school, color: Colors.orange);
//     default:
//       return const Icon(Icons.vpn_key, color: Colors.grey);
//   }
// }

// Mude de Widget para IconData
IconData _getGroupIconData(String group) {
  switch (group) {
    case 'Social Media':
      return Icons.people;
    case 'Banking':
      return Icons.account_balance;
    case 'Work':
      return Icons.work;
    case 'Study':
      return Icons.school;
    default:
      return Icons.vpn_key;
  }
}

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
      theme: _buildPasswMobTheme(),
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
                hintText: 'Filtrar credenciais...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFFB11B1F),
                ), // Ícone vermelho
                filled: true,
                fillColor: const Color(
                  0xFF1E1E1E,
                ), // Fundo levemente mais claro que o scaffold
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Alterado de azul para branco
                        letterSpacing:
                            1.2, // Um toque extra de design para títulos
                        fontSize: 13,
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
                      color: const Color(
                        0xFF121212,
                      ), // Fundo do card cinza muito escuro
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.05),
                        ), // Borda sutil
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(
                            0.1,
                          ), // Fundo cinza translúcido
                          child: Icon(
                            _getGroupIconData(category),
                            color: Colors.white, // Ícone agora é Branco
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item['alias'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        subtitle: Text(
                          item['username'] ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                          ), // Subtítulo discreto
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.white.withOpacity(
                            0.2,
                          ), // Seta quase invisível
                        ),
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
}
