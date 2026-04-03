import 'dart:async'; // Adicionado para o Timer
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Importando o Model e os serviços
import 'models/credential.dart';
import 'screens/credential_details_screen.dart';
import 'screens/credential_form_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'services/security_service.dart';
import 'services/database_service.dart';
import 'services/otp_service.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

ThemeData _buildPasswMobTheme({required bool isDark}) {
  return ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    primaryColor: const Color(0xFFB11B1F),
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
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

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
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializa o Hive
  await Hive.initFlutter();

  // 2. REGISTRA O ADAPTER
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(CredentialAdapter());
  }

  final security = SecurityService();
  bool isFirst = await security.isFirstAccess();

  // 3. Abre a Box principal com tratamento de erro robusto
  const String boxName = 'passwords';

  if (!isFirst) {
    try {
      final encryptionKey = await security.generateEncryptionKey();

      // Só abre se não estiver aberta para evitar conflitos
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox<Credential>(
          boxName,
          encryptionCipher: HiveAesCipher(encryptionKey),
        );
      }
    } catch (e) {
      debugPrint("Erro fatal ao abrir banco criptografado: $e");
      // Se a chave falhar, abrimos uma box vazia ou forçamos re-autenticação
    }
  } else {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<Credential>(boxName);
    }
  }

  runApp(PasswMobApp(isFirstAccess: isFirst));
}

class PasswMobApp extends StatelessWidget {
  final bool isFirstAccess;
  const PasswMobApp({super.key, required this.isFirstAccess});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'PASSWMOB',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: _buildPasswMobTheme(isDark: false),
          darkTheme: _buildPasswMobTheme(isDark: true),
          // Se for o primeiro acesso, vai para o Setup, senão Login
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
  late Future<List<Credential>> _credentialsFuture;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _credentialsFuture = _dbService.getAllCredentials();
  }

  void _refreshData() {
    setState(() {
      _credentialsFuture = _dbService.getAllCredentials();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PASSWMOB - Cofre'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
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
                hintText: 'Filtrar por nome, nota ou grupo...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFB11B1F)),
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Credential>>(
        future: _credentialsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma senha salva.'));
          }

          final fullList = snapshot.data!;
          final filtered = fullList.where((item) {
            final alias = item.alias.toLowerCase();
            final note = (item.note ?? '').toLowerCase();
            final user = (item.username ?? '').toLowerCase();
            final group = item.group.toLowerCase();

            return alias.contains(_searchQuery) ||
                note.contains(_searchQuery) ||
                user.contains(_searchQuery) ||
                group.contains(_searchQuery);
          }).toList();

          filtered.sort((a, b) => a.alias.compareTo(b.alias));

          Map<String, List<Credential>> grouped = {};
          for (var item in filtered) {
            grouped.putIfAbsent(item.group, () => []).add(item);
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB11B1F),
                        fontSize: 12,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  ...items.map((item) {
                    int originalIndex = fullList.indexOf(item);
                    bool hasOtp =
                        item.twoFactorSecret != null &&
                        item.twoFactorSecret!.isNotEmpty;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      color: const Color(0xFF1E1E1E),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white10,
                          child: Icon(
                            _getGroupIconData(category),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item.alias,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          item.username ?? '',
                          style: const TextStyle(color: Colors.white54),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasOtp)
                              _OtpDisplay(secret: item.twoFactorSecret!),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white24,
                            ),
                          ],
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
                          _refreshData();
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
          _refreshData();
        },
        backgroundColor: const Color(0xFFB11B1F),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Widget isolado para exibir o código 2FA que se atualiza sozinho a cada segundo.
class _OtpDisplay extends StatefulWidget {
  final String secret;
  const _OtpDisplay({required this.secret});

  @override
  State<_OtpDisplay> createState() => _OtpDisplayState();
}

class _OtpDisplayState extends State<_OtpDisplay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatOtp(String code) {
    if (code.length != 6) return code;
    return "${code.substring(0, 3)} ${code.substring(3, 6)}";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatOtp(OtpService.generateCode(widget.secret)),
          style: const TextStyle(
            color: Color(0xFFB11B1F),
            fontWeight: FontWeight.bold,
            fontSize: 15,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          'expira em ${OtpService.getSecondsRemaining()}s',
          style: const TextStyle(color: Colors.white24, fontSize: 10),
        ),
      ],
    );
  }
}
