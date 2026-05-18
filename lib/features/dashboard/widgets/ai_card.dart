import 'package:flutter/material.dart';

class AiCard extends StatelessWidget {
  final String insight;

  const AiCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.indigo.shade50,
      child: ListTile(
        leading: const Icon(Icons.auto_awesome, color: Colors.indigo),
        title: const Text("AI Finansal Analiz"),
        subtitle: Text(insight),
      ),
    );
  }
}
