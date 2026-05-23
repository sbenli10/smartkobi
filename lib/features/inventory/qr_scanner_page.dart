import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerPage extends StatelessWidget {
  const QrScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text("QR Tara")),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text("QR tarama mobil cihazda kullanılabilir."),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("QR Tara")),
      body: MobileScanner(
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          final code = barcode.rawValue;
          if (code != null) {
            Navigator.pop(context, code);
          }
        },
      ),
    );
  }
}
