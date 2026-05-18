import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatelessWidget {
  const BarcodeScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
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
