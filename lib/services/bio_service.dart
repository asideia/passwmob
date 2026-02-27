import 'package:local_auth/local_auth.dart';

class BioService {
  final LocalAuthentication _auth = LocalAuthentication();

  // Verifica se o aparelho tem hardware de biometria e se está configurado
  Future<bool> canAuthenticate() async {
    final bool canCheck = await _auth.canCheckBiometrics;
    final bool isSupported = await _auth.isDeviceSupported();
    return canCheck || isSupported;
  }

  // Chama a digital/FaceID
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Autentique-se para abrir o cofre',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
        sensitiveTransaction: true,
        // options: const AuthenticationOptions(
        //   stickyAuth: true, // Mantém o login se o app for pro background rápido
        //   biometricOnly:
        //       true, // Força apenas digital/rosto (não PIN do sistema)
        // ),
      );
    } catch (e) {
      return false;
    }
  }
}
