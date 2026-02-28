import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Importando seus novos arquivos (ajuste o caminho se necessário)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PASSWMOB - Cofre')),
      body: FutureBuilder<List<Map>>(
        future: _dbService.getAllCredentials(), // Busca os dados no Hive
        builder: (context, snapshot) {
          // 1. Enquanto carrega
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Se estiver vazio
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma senha salva ainda.'));
          }

          final credentials = snapshot.data!;

          // 3. Lista de senhas
          return ListView.builder(
            itemCount: credentials.length,
            itemBuilder: (context, index) {
              final item = credentials[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.vpn_key)),
                  title: Text(item['alias'] ?? 'Sem nome'),
                  subtitle: Text(item['group'] ?? 'Geral'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Futuro: Abrir detalhes
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Esperamos o usuário voltar da tela de cadastro
          await Navigator.pushNamed(context, '/add');
          // Quando ele voltar, atualizamos a lista
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
