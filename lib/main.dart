import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Importando seus novos arquivos (ajuste o caminho se necessário)
import 'screens/setup_screen.dart';
import 'services/security_service.dart';

void main() async {
  // 1. Garante que os plugins do sistema estejam prontos
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializa o Hive
  await Hive.initFlutter();
  await Hive.openBox('passwords');

  // 3. Lógica de Segurança
  final security = SecurityService();
  bool isFirst = await security.isFirstAccess();

  // 4. Inicia o App passando a informação do primeiro acesso
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
      initialRoute: isFirstAccess ? '/setup' : '/home',
      routes: {
        '/setup': (context) => const SetupScreen(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PASSWMOB - Cofre')),
      body: const Center(
        child: Text(
          'Seu cofre está vazio.\nToque no + para começar.',
          textAlign: TextAlign.center,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("Botão pressionado!");
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
