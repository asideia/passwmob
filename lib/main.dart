import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Importando seus novos arquivos (ajuste o caminho se necessário)
import 'screens/credential_details_screen.dart';
import 'screens/credential_form_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'services/security_service.dart';
import 'services/database_service.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

ThemeData _buildPasswMobTheme({required bool isDark}) {
  return ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,

    // Vermelho Shield Red do seu logo
    primaryColor: const Color(0xFFB11B1F),

    // Cores de Fundo
    scaffoldBackgroundColor: isDark ? Colors.black : Colors.white,

    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFB11B1F),
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: const Color(0xFFB11B1F),
      surface: isDark ? const Color(0xFF121212) : Colors.grey[100],
      secondary: const Color(0xFFB11B1F),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? Colors.black : Colors.white,
      foregroundColor: isDark ? Colors.white : Colors.black,
      elevation: 0,
      centerTitle: true,
    ),

    // Mantém o estilo dos Inputs coerente
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
      hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
      prefixIconColor: const Color(0xFFB11B1F),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

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
    // 2. O Builder "escuta" o themeNotifier
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'PASSWMOB',
          debugShowCheckedModeBanner: false,

          // 3. Define qual tema usar baseado no themeNotifier
          themeMode: currentMode,

          // Tema Claro (Light)
          theme: _buildPasswMobTheme(isDark: false),

          // Tema Escuro (Dark)
          darkTheme: _buildPasswMobTheme(isDark: true),

          initialRoute: isFirstAccess ? '/setup' : '/login',
          routes: {
            '/setup': (context) => const SetupScreen(),
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomePage(),
            '/add': (context) => const CredentialFormScreen(),
          },
        );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Filtrar por nome, nota, user ou grupo...',
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white54
                      : Colors.black54,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: const Color(
                    0xFFB11B1F,
                  ), // Mantém o vermelho do logo como destaque
                ),
                // A mágica acontece aqui:
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E) // Cinza escuro no Dark
                    : Colors.grey[200], // Cinza claro no Light
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
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
