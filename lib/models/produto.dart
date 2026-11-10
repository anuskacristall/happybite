class Produto {
  final String codigo;
  final String nome;
  final String marca;
  final String ingredientes;
  final String nutricional;
  final String alergenicos;
  final String imagemUrl;
  final double notaDesrotulando; // Nota de 0 a 10 estilo Desrotulando!

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

  factory Produto.fromJson(Map<String, dynamic> json) {
    String nutriscore = json['nutriscore_grade']?.toString().toUpperCase() ?? '';
    
    // Converte o Nutri-Score europeu (A-E) em uma nota de 0 a 10 estilo Desrotulando
    double notaCalculada = 5.0; // Padrão neutro
    if (nutriscore == 'A') {
      notaCalculada = 9.2;
    } else if (nutriscore == 'B') {
      notaCalculada = 7.8;
    } else if (nutriscore == 'C') {
      notaCalculada = 6.0;
    } else if (nutriscore == 'D') {
      notaCalculada = 4.2;
    } else if (nutriscore == 'E') {
      notaCalculada = 2.5; // Ex: Oreo / ultraprocessados
    }

    return Produto(
      codigo: json['code']?.toString() ?? '',
      nome: json['product_name'] ?? json['product_name_pt'] ?? 'Nome não informado',
      marca: json['brands'] ?? 'Marca não informada',
      ingredientes: json['ingredients_text_pt'] ?? json['ingredients_text'] ?? 'Ingredientes não informados em português.',
      nutricional: nutriscore.isNotEmpty 
          ? 'Nutri-Score: $nutriscore' 
          : 'Informação nutricional padrão',
      alergenicos: json['allergens'] ?? json['allergens_tags']?.toString() ?? 'Nenhum alergênico declarado',
      imagemUrl: json['image_front_url'] ?? '',
      notaDesrotulando: notaCalculada,
    );
  }

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