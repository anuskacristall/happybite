import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/produto.dart';
import '../providers/app_provider.dart';

// ============================================================================
// TELA 3: DETALHES DO PRODUTO E REGRAS DE SEGURANÇA (detalhes_screen.dart)
// ============================================================================
// REQUISITO 1: Tela 3 do fluxo.
// Exibe a ficha completa do alimento, nota nutricional e banner de alerta.
class DetalhesScreen extends StatelessWidget {
  final Produto produto;
  const DetalhesScreen({super.key, required this.produto});

  // BÔNUS: NORMALIZAÇÃO DE TEXTO SEM ACENTOS
  // Garante que comparações como 'Glúten' vs 'gluten' ou 'Proteína' vs 'proteina' funcionem 100%
  static String _normalizar(String texto) {
    if (texto.isEmpty) return '';
    String normalizado = texto.toLowerCase();
    const comAcento = 'àáâãäåèéêëìíîïòóôõöùúûüçñýÿ';
    const semAcento = 'aaaaaaeeeeiiiiooooouuuucnyy';
    for (int i = 0; i < comAcento.length; i++) {
      normalizado = normalizado.replaceAll(comAcento[i], semAcento[i]);
    }
    return normalizado;
  }

  // BÔNUS: DICIONÁRIO MULTILÍNGUE INTERNO
  // Traduz automaticamente ingredientes e alérgenos em inglês, francês e alemão para o português
  // FORMATAÇÃO E PONTUAÇÃO EM PORTUGUÊS (detalhes_screen.dart)
  // Formata maiúsculas, remove marcações markdown e padroniza tags de alérgenos da API para o português.
  String _formatarTextoPt(String texto) {
    if (texto.isEmpty || texto.toLowerCase() == 'unknown') return 'Não informado.';
    
    // Remove underscores markdown '_' (usados pela API Open Food Facts para destacar termos)
    String formatado = texto.replaceAll('_', '').toLowerCase();

    // Remove menções vazias como '(pode conter traços: ninguno)' ou '(pode conter traços: nenhum)'
    formatado = formatado.replaceAll(RegExp(r'\(pode conter traços:\s*(ninguno|none|nenhum|0)\)', caseSensitive: false), '').trim();
    formatado = formatado.replaceAll(RegExp(r'pode conter traços de:\s*(ninguno|none|nenhum|0)', caseSensitive: false), '').trim();

    // Padroniza apenas tags de alérgenos da API Open Food Facts (que vêm em inglês no padrão internacional)
    final tagsAlergenos = {
      'gluten': 'glúten',
      'soybeans': 'soja',
      'soya': 'soja',
      'soy': 'soja',
      'milk': 'leite',
      'peanuts': 'amendoim',
      'peanut': 'amendoim',
      'nuts': 'castanhas e nozes',
      'tree nuts': 'castanhas e nozes',
      'eggs': 'ovos',
      'egg': 'ovo',
      'wheat': 'trigo',
      'oats': 'aveia',
      'barley': 'cevada',
      'rye': 'centeio',
      'fish': 'peixe',
      'crustaceans': 'crustáceos',
      'mustard': 'mostarda',
      'sesame seeds': 'sementes de gergelim',
      'sesame': 'gergelim',
      'celery': 'aipo',
      'lupin': 'tremoço',
      'molluscs': 'moluscos',
      'leche': 'leite',
    };

    tagsAlergenos.forEach((tag, pt) {
      formatado = formatado.replaceAll(tag, pt);
    });

    // Regras gramaticais em PT-BR (Letra maiúscula após ponto ou início de frase)
    final sentences = formatado.split(RegExp(r'(?<=[.!?])\s+'));
    formatado = sentences.map((s) {
      if (s.isEmpty) return s;
      return s[0].toUpperCase() + s.substring(1);
    }).join(' ');

    formatado = formatado.replaceAllMapped(RegExp(r':\s+([a-z])'), (match) {
      return ': ${match.group(1)?.toUpperCase()}';
    });

    return formatado;
  }

  Color _corNota(double nota) {
    if (nota >= 7.0) return Colors.green.shade700;
    if (nota >= 5.0) return Colors.amber.shade800;
    return Colors.red.shade700;
  }

  Widget _info(String titulo, String conteudo) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 5),
            Text(conteudo, style: const TextStyle(fontSize: 15, height: 1.3)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    // REQUISITO 7: Lê as restrições cadastradas pelo usuário via Provider
    final provider = Provider.of<AppProvider>(context);
    final isFav = provider.isFavorito(produto);

    // REGRA DE NEGÓCIO PRINCIPAL: Cruzamento inteligente de restrições alimentares
    // Formatações visuais em PT-BR
    String ingredientesFormatados = _formatarTextoPt(produto.ingredientes);
    String alergenicosFormatados = produto.alergenicos.isEmpty ||
            produto.alergenicos.toLowerCase() == 'unknown' ||
            produto.alergenicos.toLowerCase() == 'nenhum alergênico declarado'
        ? 'Nenhum alergênico declarado pelo fabricante.'
        : _formatarTextoPt(produto.alergenicos);

    // Texto consolidado normalizado (sem acentos e em caixa baixa) para varredura sem falhas
    final textoBusca = _normalizar(
      '${produto.nome} ${produto.marca} ${produto.ingredientes} ${produto.alergenicos} $ingredientesFormatados $alergenicosFormatados',
    );

    List<String> restricoesEncontradas = [];

    for (var restricao in provider.restricoes) {
      final rNorm = _normalizar(restricao);
      bool encontrou = false;

      // 1. Verificação direta pelo termo normalizado (ex: 'Glúten' -> 'gluten', 'Soja' -> 'soja')
      if (rNorm.isNotEmpty && textoBusca.contains(rNorm)) {
        encontrou = true;
      }

      // 2. BUSCA POR SINÔNIMOS E DERIVADOS EM MÚLTIPLOS IDIOMAS:
      // Glúten / Trigo / Cereais proibidos para celíacos:
      if (rNorm.contains('gluten')) {
        const sinonimosGluten = [
          'gluten', 'trigo', 'wheat', 'ble', 'weizen', 'flour', 'farinha',
          'aveia', 'oat', 'centeio', 'rye', 'seigle', 'cevada', 'barley',
          'orge', 'malte', 'malt', 'espelta', 'kamut', 'semola', 'amido de trigo'
        ];
        if (sinonimosGluten.any((termo) => textoBusca.contains(termo))) {
          encontrou = true;
        }
      }

      // Lactose / Derivados de leite:
      if (rNorm.contains('lactose')) {
        const sinonimosLactose = [
          'lactose', 'leite', 'milk', 'lait', 'milch', 'latte', 'leche',
          'queijo', 'cheese', 'fromage', 'kase', 'manteiga', 'butter',
          'soro de leite', 'whey', 'nata', 'creme de leite', 'cream',
          'iogurte', 'yogurt', 'coalhada', 'requeijao'
        ];
        if (sinonimosLactose.any((termo) => textoBusca.contains(termo))) {
          encontrou = true;
        }
      }

      // Proteína do Leite (APLV):
      if (rNorm.contains('proteina') || rNorm.contains('aplv')) {
        const sinonimosAplv = [
          'caseina', 'casein', 'caseinato', 'lactalbumina', 'lactoglobulina',
          'leite', 'milk', 'lait', 'milch', 'soro de leite', 'whey',
          'derivados de leite', 'proteina de leite', 'aplv'
        ];
        if (sinonimosAplv.any((termo) => textoBusca.contains(termo))) {
          encontrou = true;
        }
      }

      // Soja e derivados:
      if (rNorm.contains('soja')) {
        const sinonimosSoja = [
          'soja', 'soya', 'soy', 'soybean', 'soybeans',
          'lecitina de soja', 'soy lecithin', 'sojalecithin', 'lecitina'
        ];
        if (sinonimosSoja.any((termo) => textoBusca.contains(termo))) {
          encontrou = true;
        }
      }

      // Oleaginosas / Amendoim:
      if (rNorm.contains('oleaginosa') || rNorm.contains('amendoim')) {
        const sinonimosNuts = [
          'amendoim', 'peanut', 'erdnuss', 'cacahuete', 'cacahuate',
          'castanha', 'caju', 'para', 'nozes', 'noz', 'nuts', 'walnut',
          'avela', 'hazelnut', 'haselnuss', 'amendoa', 'almond', 'mandel',
          'pistache', 'pistachio', 'macadamia', 'peca', 'pecan'
        ];
        if (sinonimosNuts.any((termo) => textoBusca.contains(termo))) {
          encontrou = true;
        }
      }

      // Histamina:
      if (rNorm.contains('histamina')) {
        const sinonimosHistamina = [
          'histamina', 'histamine', 'defumado', 'embutido',
          'fermentado', 'conserva', 'vinagre', 'maturado'
        ];
        if (sinonimosHistamina.any((termo) => textoBusca.contains(termo))) {
          encontrou = true;
        }
      }

      if (encontrou && !restricoesEncontradas.contains(restricao)) {
        restricoesEncontradas.add(restricao);
      }
    }

    // Se encontrou alguma restrição, define o banner como ALERTA (Vermelho); senão SEGURO (Verde)
    bool temAlerta = restricoesEncontradas.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Alimento'),
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
            constraints: const BoxConstraints(maxWidth: 680), // Responsividade
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: produto.imagemUrl.isNotEmpty
                        ? Image.network(
                            produto.imagemUrl,
                            height: 150,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.fastfood, size: 80, color: Colors.grey),
                          )
                        : const Icon(Icons.fastfood, size: 80, color: Colors.grey),
                  ),
            const SizedBox(height: 16),
            
            // SELO DE QUALIDADE NUTRICIONAL (Nota 0 a 10)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _corNota(produto.notaDesrotulando).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _corNota(produto.notaDesrotulando), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: _corNota(produto.notaDesrotulando), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Qualidade Nutricional: ${produto.notaDesrotulando.toStringAsFixed(1)} / 10',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _corNota(produto.notaDesrotulando),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              produto.nome,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Fabricante: ${produto.marca}', style: const TextStyle(color: Colors.grey, fontSize: 15)),
            const SizedBox(height: 18),

            // BANNER DE ALERTA DE RESTRIÇÕES (Compatível com Tema Claro e Escuro)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: temAlerta
                    ? (provider.isDarkMode ? Colors.red.shade900.withValues(alpha: 0.35) : Colors.red.shade50)
                    : (provider.isDarkMode ? Colors.green.shade900.withValues(alpha: 0.35) : Colors.green.shade50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: temAlerta
                      ? (provider.isDarkMode ? Colors.red.shade700 : Colors.red.shade300)
                      : (provider.isDarkMode ? Colors.green.shade700 : Colors.green.shade300),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    temAlerta ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    color: temAlerta
                        ? (provider.isDarkMode ? Colors.red.shade300 : Colors.red.shade700)
                        : (provider.isDarkMode ? Colors.green.shade300 : Colors.green.shade700),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          temAlerta ? 'Alerta de Restrição!' : 'Produto Seguro para Você!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: temAlerta
                                ? (provider.isDarkMode ? Colors.red.shade200 : Colors.red.shade800)
                                : (provider.isDarkMode ? Colors.green.shade200 : Colors.green.shade800),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          temAlerta
                              ? 'Contém itens restritos por você: ${restricoesEncontradas.join(', ')}.'
                              : 'Nenhuma das suas restrições foi identificada neste produto.',
                          style: TextStyle(
                            color: temAlerta
                                ? (provider.isDarkMode ? Colors.red.shade100 : Colors.red.shade900)
                                : (provider.isDarkMode ? Colors.green.shade100 : Colors.green.shade900),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 35),
            _info('Ingredientes', ingredientesFormatados),
            _info('Alergênicos', alergenicosFormatados),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                provider.alternarFavorito(produto);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isFav ? 'Removido dos favoritos.' : 'Adicionado aos favoritos!')),
                );
              },
              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
              label: Text(isFav ? 'Remover dos favoritos' : 'Adicionar aos favoritos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFav ? Colors.red.shade700 : const Color(0xFF247A51),
              ),
            ),
            const SizedBox(height: 12),
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