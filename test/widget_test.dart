import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:happy_bite/main.dart';
import 'package:happy_bite/providers/app_provider.dart';

void main() {
  testWidgets('HappyBiteApp inicializa com a tela de cadastro', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
        ],
        child: const HappyBiteApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Happy Bite'), findsWidgets);
    expect(find.text('Comer bem começa aqui!'), findsOneWidget);
  });
}
