import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monorepo/src/app/app.dart';

void main() {
  testWidgets('MyApp renders expected shell', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
