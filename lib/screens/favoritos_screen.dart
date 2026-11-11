import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'detalhes_screen.dart';

// ============================================================================
// TELA 4: FAVORITOS SALVOS LOCALMENTE (favoritos_screen.dart)
// ============================================================================
// REQUISITO 1: Tela 4 do aplicativo (completa o requisito de no mínimo 4 telas).
// REQUISITO 6: Demonstração prática da persistência com SharedPreferences.
class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // REQUISITO 7: Conecta ao Provider para ler a lista de favoritos
    final provider = Provider.of<AppProvider>(context);
    final favoritos = provider.favoritos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Favoritos'),
        actions: [
          // BÔNUS: Botão de Tema Sol (Claro) / Lua (Escuro)
          IconButton(
            tooltip: provider.isDarkMode ? 'Tema Claro' : 'Tema Escuro',
            icon: Icon(
              provider.isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              color: provider.isDarkMode ? Colors.amber : const Color(0xFF247A51),
            ),
            onPressed: () => provider.alternarTema(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720), // Responsividade
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alimentos salvos no dispositivo ❤️', 
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    // Tratamento de lista vazia
                    child: favoritos.isEmpty
                        ? const Center(child: Text('Você ainda não possui alimentos favoritos.'))
                        // REQUISITO 5: LISTAGEM DINÂMICA COM ListView.builder
                        : ListView.builder(
                            itemCount: favoritos.length,
                            itemBuilder: (context, i) {
                              final item = favoritos[i];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: item.imagemUrl.isNotEmpty
                                      ? Image.network(
                                          item.imagemUrl,
                                          width: 40,
                                          height: 40,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.fastfood),
                                        )
                                      : const Icon(Icons.fastfood),
                                  title: Text(item.nome),
                                  subtitle: Text(item.marca),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => DetalhesScreen(produto: item)),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Voltar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}