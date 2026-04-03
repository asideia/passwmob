import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isScanCompleted = false;

  void _handleBarcode(BarcodeCapture capture) {
    if (_isScanCompleted) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.startsWith('otpauth://')) {
        _isScanCompleted = true;

        // Extração básica do Secret e do Label da URL otpauth
        // Exemplo: otpauth://totp/Google:user@gmail.com?secret=JBSWY3DPEHPK3PXP&issuer=Google
        try {
          final uri = Uri.parse(code);
          final secret = uri.queryParameters['secret'];
          final issuer =
              uri.queryParameters['issuer'] ??
              uri.path.split(':').first.replaceAll('/', '');

          if (secret != null) {
            Navigator.pop(context, {'secret': secret, 'label': issuer});
            return;
          }
        } catch (e) {
          debugPrint('Erro ao parsear QR Code: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR Code 2FA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => MobileScannerController().toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.normal,
              facing: CameraFacing.back,
            ),
            onDetect: _handleBarcode,
          ),
          // Overlay para guiar o usuário
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Text(
              'Aponte para o QR Code do 2FA',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                backgroundColor: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
