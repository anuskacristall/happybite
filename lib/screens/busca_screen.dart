import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'detalhes_screen.dart';
import 'favoritos_screen.dart';

// ============================================================================
// TELA 2: BUSCA E CATÁLOGO DE ALIMENTOS NA API (busca_screen.dart)
// ============================================================================
// REQUISITO 1: Tela 2 do aplicativo.
// Integra o campo de pesquisa com o Provider e renderiza os resultados da API.
class BuscaScreen extends StatefulWidget {
  const BuscaScreen({super.key});

  @override
  State<BuscaScreen> createState() => _BuscaScreenState();
}

class _BuscaScreenState extends State<BuscaScreen> {
  final _buscaController = TextEditingController();

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  // Dispara a busca remota no Provider
  void _realizarBusca() {
    final termo = _buscaController.text.trim();
    if (termo.isNotEmpty) {
      // listen: false porque estamos dentro de uma função de callback (não precisamos redesenhar aqui)
      Provider.of<AppProvider>(context, listen: false).buscarProdutos(termo);
    }
  }

  @override
  Widget build(BuildContext context) {
    // REQUISITO 7: Ouve as alterações do Provider (reconstrói a tela quando isLoading ou lista mudar)
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar alimentos (API)'),
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
          // REQUISITO 1: Navegação para a Tela 4 (Favoritos) via Navigator.push
          IconButton(
            tooltip: 'Favoritos',
            icon: const Icon(Icons.favorite, color: Colors.redAccent),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritosScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Olá, ${provider.nomeUsuario}! 👋', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Restrições: ${provider.restricoes.join(', ')}'),
            const SizedBox(height: 20),
            TextField(
              controller: _buscaController,
              decoration: const InputDecoration(
                hintText: 'Ex.: Oreo, chocolate, leite...',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => _realizarBusca(),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _realizarBusca,
              child: const Text('Buscar na API Open Food Facts'),
            ),
            const SizedBox(height: 22),
            // ÁREA DE CONTEÚDO DINÂMICO: Trata Loading, Erro e Sucesso
            Expanded(
              // REQUISITO 3: ESTADO DE LOADING VISÍVEL NA UI
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  // REQUISITO 3: TRATAMENTO DE ERRO VISÍVEL NA UI (com retry e fallback)
                  : provider.erro != null
                      ? Center(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.info_outline, size: 54, color: Colors.orangeAccent),
                                  const SizedBox(height: 12),
                                  Text(
                                    provider.erro!,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _realizarBusca,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Tentar novamente'),
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    onPressed: () => provider.carregarProdutoDemonstracao(),
                                    icon: const Icon(Icons.fastfood),
                                    label: const Text('Carregar exemplo offline (Demonstração)'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : provider.produtosBusca.isEmpty
                          ? const Center(
                              child: Text(
                                'Digite o nome de um alimento (ex.: Oreo, leite, pão) e clique em buscar.',
                                textAlign: TextAlign.center,
                              ),
                            )
                          // REQUISITO 5: LISTAGEM DINÂMICA COM ListView.builder
                          : ListView.builder(
                              itemCount: provider.produtosBusca.length,
                              itemBuilder: (context, i) {
                                final produto = provider.produtosBusca[i];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    leading: produto.imagemUrl.isNotEmpty
                                        ? Image.network(
                                            produto.imagemUrl,
                                            width: 45,
                                            height: 45,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.fastfood),
                                          )
                                        : const Icon(Icons.fastfood),
                                    title: Text(produto.nome),
                                    subtitle: Text(produto.marca),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => DetalhesScreen(produto: produto)),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    ),
    ),
    );
  }
}