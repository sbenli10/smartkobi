import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkobi/main.dart';

void main() {
  testWidgets('SmartKobiApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartKobiApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(SmartKobiApp), findsOneWidget);
  });
}
