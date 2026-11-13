import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:happy_bite/main.dart';
import 'package:happy_bite/models/produto.dart';
import 'package:happy_bite/providers/app_provider.dart';
import 'package:happy_bite/screens/detalhes_screen.dart';

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

    expect(find.text('Como podemos te chamar?'), findsOneWidget);
    expect(find.text('Digite seu nome'), findsOneWidget);
  });

  testWidgets('DetalhesScreen exibe Alerta de Restrição quando produto Oreo contém Glúten', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = AppProvider();
    await provider.salvarCadastro('Anuska', ['Glúten']);

    final produtoOreo = Produto(
      codigo: '7622210449283',
      nome: 'Biscoito Recheado Oreo',
      marca: 'Mondelez',
      ingredientes: 'Farinha de trigo, açúcar, gordura vegetal, cacau em pó...',
      nutricional: 'Nutri-Score: E',
      alergenicos: 'gluten, soja',
      imagemUrl: '',
      notaDesrotulando: 2.5,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppProvider>.value(value: provider),
        ],
        child: MaterialApp(
          home: DetalhesScreen(produto: produtoOreo),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alerta de Restrição!'), findsOneWidget);
    expect(find.textContaining('Glúten'), findsWidgets);
    expect(find.text('Produto Seguro para Você!'), findsNothing);
  });

  test('Produto.possuiFichaCompleta valida presença obrigatória de nome, ingredientes e alergênicos', () {
    final produtoCompleto = Produto(
      codigo: '123',
      nome: 'Biscoito Integral',
      marca: 'Marca Exemplo',
      ingredientes: 'Farinha de trigo integral, água, sal.',
      nutricional: 'Nutri-Score: A',
      alergenicos: 'Contém glúten.',
      imagemUrl: '',
      notaDesrotulando: 8.5,
    );
    expect(produtoCompleto.possuiFichaCompleta, isTrue);

    final produtoSemIngredientes = Produto(
      codigo: '124',
      nome: 'Biscoito Sem Ingredientes',
      marca: 'Marca Exemplo',
      ingredientes: 'Ingredientes não informados em português.',
      nutricional: 'Nutri-Score: C',
      alergenicos: 'Glúten',
      imagemUrl: '',
      notaDesrotulando: 6.0,
    );
    expect(produtoSemIngredientes.possuiFichaCompleta, isFalse);

    final produtoSemAlergenicos = Produto(
      codigo: '125',
      nome: 'Biscoito Sem Alergênicos Informados',
      marca: 'Marca Exemplo',
      ingredientes: 'Farinha de trigo, açúcar, sal.',
      nutricional: 'Nutri-Score: C',
      alergenicos: 'Nenhum alergênico declarado',
      imagemUrl: '',
      notaDesrotulando: 6.0,
    );
    expect(produtoSemAlergenicos.possuiFichaCompleta, isFalse);

    // BÔNUS: Validação contra escaneamento imperfeito de OCR (ex: Batman Oreo da comunidade)
    final produtoLixoOcr = Produto(
      codigo: '7622300830151',
      nome: 'Biscoito Original Batman Oreo Pacote 90g',
      marca: 'Mondelez',
      ingredientes: 'ANUTRICIONAL: Porção de 30 g (3 biscoitos): Vator energetico 145 kcal... Zona Rural... curtiu ego',
      nutricional: 'Informação nutricional padrão',
      alergenicos: 'Glúten, Soja',
      imagemUrl: '',
      notaDesrotulando: 5.0,
    );
    expect(produtoLixoOcr.possuiFichaCompleta, isFalse);
    expect(Produto.ehLixoOcr(produtoLixoOcr.ingredientes), isTrue);
  });
}

