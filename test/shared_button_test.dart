import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:gestao_mvp/shared/widgets/shared_button.dart';

void main() {
  testWidgets('SharedButton exibe label e responde ao clique', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SharedButton(
          label: 'Clique aqui',
          onPressed: () => pressed = true,
        ),
      ),
    );
    expect(find.text('Clique aqui'), findsOneWidget);
    await tester.tap(find.byType(SharedButton));
    expect(pressed, true);
  });

  testWidgets('SharedButton exibe loading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SharedButton(
          label: 'Carregando',
          onPressed: () {},
          loading: true,
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Carregando'), findsNothing);
  });
}
