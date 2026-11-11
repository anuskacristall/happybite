import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/cadastro_screen.dart';

// ============================================================================
// PONTO DE ENTRADA DO APLICATIVO (main.dart)
// ============================================================================
// Aqui o Flutter inicia a execução.
// REQUISITO 7: Arquitetura com Provider.
// Envolvemos toda a aplicação com MultiProvider para que qualquer tela
// filha possa acessar o estado global do AppProvider sem complicação.
void main() {
  runApp(
    MultiProvider(
      providers: [
        // Cria uma instância única do AppProvider e disponibiliza para todo o app
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const HappyBiteApp(),
    ),
  );
}

// Widget raiz do aplicativo (StatelessWidget porque sua estrutura visual não muda dinamicamente)
class HappyBiteApp extends StatelessWidget {
  const HappyBiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    // Cor temática principal do app (Verde bem-estar / saúde alimentar)
    const verde = Color(0xFF247A51);

    return MaterialApp(
      title: 'Happy Bite',
      debugShowCheckedModeBanner: false, // Remove a faixa de debug no canto da tela
      // BÔNUS: TEMA ESCURO / CLARO RESPONSIVO E PERSISTENTE
      themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: verde, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF7FAF7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7FAF7), 
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: verde,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: verde, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E8B57),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      // REQUISITO 1: O fluxo de navegação se inicia na tela de cadastro/perfil
      home: const CadastroScreen(),
    );
  }
}