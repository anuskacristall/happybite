// ============================================================================
// CAMADA MODEL: MODELO DE DADOS DO PRODUTO (produto.dart)
// ============================================================================
// Define a estrutura de dados de um alimento no aplicativo.
// Os atributos são "final" porque um produto pesquisado é imutável após ser criado.
class Produto {
  final String codigo;              // Código de barras (EAN/GTIN)
  final String nome;                // Nome comercial do produto
  final String marca;               // Fabricante / Marca
  final String ingredientes;        // Lista de ingredientes cadastrados
  final String nutricional;         // Classificação ou resumo nutricional
  final String alergenicos;         // Alérgenos declarados (trigo, leite, soja, etc.)
  final String imagemUrl;           // URL pública da imagem da embalagem
  final double notaDesrotulando;    // BÔNUS: Nota de saudabilidade de 0 a 10 inspirada no app Desrotulando

  Produto({
    required this.codigo,
    required this.nome,
    required this.marca,
    required this.ingredientes,
    required this.nutricional,
    required this.alergenicos,
    required this.imagemUrl,
    required this.notaDesrotulando,
  });

  // REQUISITO 2: DESSERIALIZAÇÃO (Transforma o JSON vindo da API em Objeto Dart)
  // O construtor factory recebe um Map<String, dynamic> e mapeia os campos da API Open Food Facts.
  factory Produto.fromJson(Map<String, dynamic> json) {
    // A API retorna o Nutri-Score europeu em letras de 'A' (mais saudável) a 'E' (ultraprocessado)
    String nutriscore = json['nutriscore_grade']?.toString().toUpperCase() ?? '';
    
    // REGRA DE NEGÓCIO: Converte a classificação A-E em nota contínua de 0 a 10
    double notaCalculada = 5.0; // Nota neutra padrão caso o produto não tenha Nutri-Score informado
    if (nutriscore == 'A') {
      notaCalculada = 9.2; // Excelente qualidade nutricional
    } else if (nutriscore == 'B') {
      notaCalculada = 7.8; // Boa qualidade
    } else if (nutriscore == 'C') {
      notaCalculada = 6.0; // Média / atenção moderada
    } else if (nutriscore == 'D') {
      notaCalculada = 4.2; // Baixa qualidade nutricional
    } else if (nutriscore == 'E') {
      notaCalculada = 2.5; // Alimento ultraprocessado (Ex.: biscoitos recheados)
    }

    // Extrai alérgenos declarados com tratamento rigoroso de nulos, vazios e tags
    String alergenicosExtraidos = '';
    final rawAllergens = json['allergens']?.toString().trim();
    if (rawAllergens != null && rawAllergens.isNotEmpty && rawAllergens.toLowerCase() != 'unknown') {
      alergenicosExtraidos = rawAllergens;
    } else if (json['allergens_tags'] is List && (json['allergens_tags'] as List).isNotEmpty) {
      alergenicosExtraidos = (json['allergens_tags'] as List)
          .map((t) => t.toString().replaceAll(RegExp(r'^[a-z]{2}:'), ''))
          .join(', ');
    }

    // Adiciona traços de contaminação cruzada (traces), ex: "pode conter leite"
    final rawTraces = json['traces']?.toString().trim();
    String tracosExtraidos = '';
    if (rawTraces != null && rawTraces.isNotEmpty && rawTraces.toLowerCase() != 'unknown') {
      tracosExtraidos = rawTraces;
    } else if (json['traces_tags'] is List && (json['traces_tags'] as List).isNotEmpty) {
      tracosExtraidos = (json['traces_tags'] as List)
          .map((t) => t.toString().replaceAll(RegExp(r'^[a-z]{2}:'), ''))
          .join(', ');
    }

    // Filtra traços falsos ou negativos da API (como 'ninguno', 'none', 'nenhum')
    const falsosTracos = ['ninguno', 'none', 'nenhum', '0', 'unknown', 'nao contem', 'não contém', 'no'];
    if (falsosTracos.contains(tracosExtraidos.toLowerCase().trim())) {
      tracosExtraidos = '';
    }

    if (tracosExtraidos.isNotEmpty) {
      alergenicosExtraidos = alergenicosExtraidos.isNotEmpty
          ? '$alergenicosExtraidos (Pode conter traços: $tracosExtraidos)'
          : 'Pode conter traços de: $tracosExtraidos';
    }

    // Extrai ingredientes priorizando português nativo e remove marcações markdown '_' da API
    String ingredientesPt = json['ingredients_text_pt']?.toString().trim() ?? '';
    String ingredientesGeral = json['ingredients_text']?.toString().trim() ?? '';
    String ingredientesFinais = ingredientesPt.isNotEmpty ? ingredientesPt : ingredientesGeral;
    ingredientesFinais = ingredientesFinais.replaceAll('_', '').trim();

    // Se a API não preencheu o campo de alérgenos, mas eles foram informados no texto dos ingredientes (padrão Anvisa)
    if (alergenicosExtraidos.isEmpty && ingredientesFinais.isNotEmpty) {
      final ingLower = ingredientesFinais.toLowerCase();
      if (ingLower.contains('alérgicos') ||
          ingLower.contains('alergicos') ||
          ingLower.contains('contém glúten') ||
          ingLower.contains('contem gluten') ||
          ingLower.contains('contém leite') ||
          ingLower.contains('contem leite') ||
          ingLower.contains('contém derivados') ||
          ingLower.contains('contem derivados')) {
        int idx = ingLower.indexOf('alérg');
        if (idx == -1) idx = ingLower.indexOf('alerg');
        if (idx == -1) idx = ingLower.indexOf('contém');
        if (idx == -1) idx = ingLower.indexOf('contem');
        if (idx != -1) {
          alergenicosExtraidos = ingredientesFinais.substring(idx).trim();
        }
      }
    }

    if (alergenicosExtraidos.isEmpty) {
      alergenicosExtraidos = 'Nenhum alergênico declarado';
    }

    // Extrai nome priorizando português
    String nomePt = json['product_name_pt']?.toString().trim() ?? '';
    String nomeGeral = json['product_name']?.toString().trim() ?? '';
    String nomeFinal = nomePt.isNotEmpty ? nomePt : (nomeGeral.isNotEmpty ? nomeGeral : 'Nome não informado');

    // Instancia o objeto tratando valores nulos com o operador "??" (Null Safety)
    return Produto(
      codigo: json['code']?.toString() ?? '',
      nome: nomeFinal,
      marca: json['brands'] ?? 'Marca não informada',
      ingredientes: ingredientesFinais.isNotEmpty ? ingredientesFinais : 'Ingredientes não informados em português.',
      nutricional: nutriscore.isNotEmpty 
          ? 'Nutri-Score: $nutriscore' 
          : 'Informação nutricional padrão',
      alergenicos: alergenicosExtraidos,
      imagemUrl: json['image_front_url'] ?? '',
      notaDesrotulando: notaCalculada,
    );
  }

  // REGRA DE QUALIDADE: Verifica se o produto possui todos os dados necessários (Nome, Ingredientes e Alérgenos)
  bool get possuiFichaCompleta {
    final nomeValido = nome.trim().isNotEmpty && nome != 'Nome não informado';
    final ingValido = ingredientes.trim().isNotEmpty &&
        !ingredientes.toLowerCase().contains('não informado') &&
        !ingredientes.toLowerCase().contains('nao informado');
    final allgValido = alergenicos.trim().isNotEmpty &&
        !alergenicos.toLowerCase().contains('nenhum alergênico declarado') &&
        !alergenicos.toLowerCase().contains('unknown');
    return nomeValido && ingValido && allgValido;
  }

  // REQUISITO 6: SERIALIZAÇÃO (Transforma o Objeto Dart de volta para Map / JSON)
  // Necessário para que o SharedPreferences possa salvar o produto nos Favoritos via jsonEncode.
  Map<String, dynamic> toJson() => {
    'code': codigo,
    'product_name': nome,
    'brands': marca,
    'ingredients_text_pt': ingredientes,
    'nutriscore_grade': nutricional,
    'allergens': alergenicos,
    'image_front_url': imagemUrl,
    'nota_desrotulando': notaDesrotulando,
  };
}