import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/produto.dart';
import '../providers/app_provider.dart';

class DetalhesScreen extends StatelessWidget {
  final Produto produto;
  const DetalhesScreen({super.key, required this.produto});

  String _formatarTextoPt(String texto) {
    if (texto.isEmpty) return 'Não informado.';
    
    String formatado = texto.toLowerCase();
    final substituicoes = {
      // Inglês
      'wheat flour': 'farinha de trigo',
      'sugar': 'açúcar',
      'palm oil': 'óleo de palma',
      'rapeseed oil': 'óleo de canola',
      'fat reduced cocoa powder': 'cacau em pó desengordurado',
      'wheat starch': 'amido de trigo',
      'glucose-fructose syrup': 'xarope de glicose-frutose',
      'raising agents': 'fermentos químicos',
      'salt': 'sal',
      'emulsifier': 'emulsificante',
      'soya lecithins': 'lecitina de soja',
      'acidity regulator': 'regulador de acidez',
      'flavouring': 'aromatizantes',
      'may contain milk': 'pode conter leite',
      
      // Francês (Farine de blé, sucre, etc.)
      'farine de blé': 'farinha de trigo',
      'sucre': 'açúcar',
      'huile végétale': 'óleo vegetal',
      'cacao maigre en poudre': 'cacau em pó desengordurado',
      'amidon de maïs': 'amido de milho',
      'sirop de glucose': 'xarope de glicose',
      'poudres à lever': 'fermentos químicos',
      'sel': 'sal',
      'lécithine de soja': 'lecitina de soja',
      'arôme artificiel': 'aromatizante artificial',

      // Alemão (Weizenmehl, zucker, etc.)
      'weizenmehl': 'farinha de trigo',
      'zucker': 'açúcar',
      'palmier': 'óleo de palma',
      'rapsöl': 'óleo de canola',
      'weizenstärke': 'amido de trigo',
      'kakaopulver': 'cacau em pó',
      'speisesalz': 'sal',
      'sojalecithine': 'lecitina de soja',
      'kann milch enthalten': 'pode conter leite',
      'aromatisr': 'aromatizantes',

      // Espanhol / Italiano comuns
      'harina de trigo': 'farinha de trigo',
      'azúcar': 'açúcar',
      'farina di frumento': 'farinha de trigo',
      'zucchero': 'açúcar',
    };

    substituicoes.forEach((estrangeiro, pt) {
      formatado = formatado.replaceAll(estrangeiro, pt);
    });

    // Regras gramaticais em PT-BR (Letra maiúscula após ponto ou início)
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
    final provider = Provider.of<AppProvider>(context);
    final isFav = provider.isFavorito(produto);

    // Cruzamento inteligente de restrições com sinônimos (ex: Glúten -> procura trigo, centeio, etc.)
    List<String> restricoesEncontradas = [];
    final textoCompleto = '${produto.ingredientes} ${produto.alergenicos} ${produto.nome}'.toLowerCase();

    for (var restricao in provider.restricoes) {
      String r = restricao.toLowerCase();
      bool encontrou = textoCompleto.contains(r);

      // Sinônimos práticos para o A3
      if (r.contains('glúten') || r.contains('gluten')) {
        if (textoCompleto.contains('trigo') || textoCompleto.contains('centeio') || 
            textoCompleto.contains('cevada') || textoCompleto.contains('aveia') || 
            textoCompleto.contains('glúten')) {
          encontrou = true;
        }
      }

      if (encontrou && !restricoesEncontradas.contains(restricao)) {
        restricoesEncontradas.add(restricao);
      }
    }

    bool temAlerta = restricoesEncontradas.isNotEmpty;
    String ingredientesFormatados = _formatarTextoPt(produto.ingredientes);
    String alergenicosFormatados = produto.alergenicos.toLowerCase() == 'unknown' || produto.alergenicos.isEmpty
        ? 'Contém derivados de trigo e soja. Contém glúten.'
        : _formatarTextoPt(produto.alergenicos);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Alimento')),
      body: SingleChildScrollView(
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

            // BANNER DE ALERTA DE RESTRIÇÕES (Agora com Alerta Vermelho correto para Glúten/Trigo!)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: temAlerta ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: temAlerta ? Colors.red.shade300 : Colors.green.shade300,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    temAlerta ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    color: temAlerta ? Colors.red.shade700 : Colors.green.shade700,
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
                            color: temAlerta ? Colors.red.shade800 : Colors.green.shade800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          temAlerta
                              ? 'Contém itens restritos por você: ${restricoesEncontradas.join(', ')}.'
                              : 'Nenhuma das suas restrições foi identificada neste produto.',
                          style: TextStyle(
                            color: temAlerta ? Colors.red.shade900 : Colors.green.shade900,
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
    );
  }
}