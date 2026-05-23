import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatelessWidget {
  const BarcodeScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text("Barkod Tara")),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text("Barkod tarama mobil cihazda kullanılabilir."),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Barkod Tara")),
      body: MobileScanner(
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          final String? code = barcode.rawValue;

          if (code != null) {
            Navigator.pop(context, code);
          }
        },
      ),
    );
  }
}
