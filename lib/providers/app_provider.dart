import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/produto.dart';

// ============================================================================
// CAMADA PROVIDER: GERENCIAMENTO DE ESTADO E REGRAS DE NEGÓCIO (app_provider.dart)
// ============================================================================
// Herda de ChangeNotifier. É o "cérebro" da aplicação.
// REQUISITO 7: Separação limpa de responsabilidades (telas, HTTP e prefs separados).
class AppProvider extends ChangeNotifier {
  // ATRIBUTOS PRIVADOS (Encapsulamento):
  // Nenhuma tela pode alterar essas variáveis diretamente, garantindo a integridade dos dados.
  String _nomeUsuario = '';
  List<String> _restricoes = [];
  List<Produto> _favoritos = [];
  
  List<Produto> _produtosBusca = [];
  bool _isLoading = false;
  String? _erro;

  // BÔNUS: TEMA ESCURO / CLARO PERSISTENTE
  bool _isDarkMode = false;

  // GETTERS PÚBLICOS: As telas usam esses métodos apenas para LER as informações.
  String get nomeUsuario => _nomeUsuario;
  List<String> get restricoes => _restricoes;
  List<Produto> get favoritos => _favoritos;
  List<Produto> get produtosBusca => _produtosBusca;
  bool get isLoading => _isLoading;
  String? get erro => _erro;
  bool get isDarkMode => _isDarkMode;

  // Construtor: ao instanciar o Provider, busca os dados salvos no SharedPreferences
  AppProvider() {
    _carregarDadosLocais();
  }

  // REQUISITO 6: PERSISTÊNCIA LOCAL (Carrega os dados ao abrir o aplicativo)
  Future<void> _carregarDadosLocais() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Recupera o tema escolhido pelo usuário
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;

    // Recupera o nome salvo (ou vazio se for a primeira vez)
    _nomeUsuario = prefs.getString('nome_usuario') ?? '';
    
    // Recupera a lista de restrições selecionadas
    final restricoesSalvas = prefs.getStringList('restricoes');
    if (restricoesSalvas != null) {
      _restricoes = restricoesSalvas;
    }

    // Recupera os favoritos serializados em JSON e recria a lista de objetos Produto
    final favoritosJson = prefs.getStringList('favoritos') ?? [];
    _favoritos = favoritosJson.map((item) => Produto.fromJson(jsonDecode(item))).toList();
    
    // Notifica os widgets que os dados foram carregados da memória local
    notifyListeners();
  }

  // BÔNUS: Alterna entre Tema Claro e Escuro e persiste no SharedPreferences
  Future<void> alternarTema() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    notifyListeners();
  }

  // REQUISITO 4 e 6: Grava o perfil do usuário no SharedPreferences
  Future<void> salvarCadastro(String nome, List<String> restricoes) async {
    _nomeUsuario = nome;
    _restricoes = restricoes;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nome_usuario', nome);
    await prefs.setStringList('restricoes', restricoes);
    
    notifyListeners(); // Notifica a interface para atualizar saudações e restrições
  }

  // Função utilitária para normalização sem acentos
  String _normalizarTexto(String texto) {
    var comAcento = 'àáâãäåèéêëìíîïòóôõöùúûüçñ';
    var semAcento = 'aaaaaaeeeeiiiiooooouuuucn';
    String resultado = texto.toLowerCase();
    for (int i = 0; i < comAcento.length; i++) {
      resultado = resultado.replaceAll(comAcento[i], semAcento[i]);
    }
    return resultado;
  }

  // BÔNUS: Detecta se o alimento é comercializado em países de língua portuguesa ou possui rótulo em português
  // BÔNUS: Validação universal de idioma - aceita apenas português e descarta qualquer alimento estrangeiro
  bool _ehEmPortugues(Map<String, dynamic> json, Produto produto) {
    final lang = json['lang']?.toString().toLowerCase().trim() ?? '';
    final hasPtIng = json['ingredients_text_pt']?.toString().trim().isNotEmpty ?? false;
    final countries = json['countries']?.toString().toLowerCase() ?? '';
    final countriesTags = json['countries_tags']?.toString().toLowerCase() ?? '';

    // 1. Se o idioma for explicitamente estrangeiro (de, en, fr, nl, es, it, etc.),
    // SÓ aceita se houver o campo específico de ingredientes em português (ingredients_text_pt)!
    if (lang.isNotEmpty && lang != 'pt') {
      if (!hasPtIng) return false;
    }

    // 2. Varredura rigorosa de termos de outros idiomas nos ingredientes (Alemão, Inglês, Francês, Espanhol, Holandês)
    final ingLower = produto.ingredientes.toLowerCase();
    const palavrasEstrangeiras = [
      // Alemão
      'getreidemehle', 'zutaten', 'enthält', 'spuren', 'mehl', 'zucker', 'fettarmes', 'milch', 'aromen', 'salz',
      // Inglês
      'ingredients', 'contains', 'flour', 'wheat', 'skimmed', 'cocoa powder', 'palm oil',
      // Francês
      'ingrédients', 'farine', 'sucre', 'huile', 'lait',
      // Espanhol
      'ingredientes:', 'leche', 'harina', 'grasa', 'aceite',
      // Holandês
      'ingrediënten', 'tarwemeel'
    ];
    for (var palavra in palavrasEstrangeiras) {
      if (ingLower.contains(palavra)) {
        return false; // Alimento estrangeiro detectado: descarta sumariamente!
      }
    }

    // 3. Se tem ingredientes cadastrados em português ou o idioma for 'pt', aceita
    if (hasPtIng || lang == 'pt') return true;

    // 4. Se o produto é comprovadamente comercializado no Brasil
    if (countries.contains('brasil') || countries.contains('brazil') || countriesTags.contains('brazil')) {
      return true;
    }

    return false;
  }

  // REQUISITO 2 e 3: CONSUMO DE API REST COM HTTP, ASYNC/AWAIT, LOADING E TRATAMENTO DE ERROS
  Future<void> buscarProdutos(String termo) async {
    if (termo.trim().isEmpty) return;

    // 1. Inicia o estado de Loading e limpa erros anteriores
    _isLoading = true;
    _erro = null;
    _produtosBusca = [];
    notifyListeners(); // A tela reage mostrando o CircularProgressIndicator

    try {
      // 1. Busca prioritariamente na base brasileira oficial do Open Food Facts (br.openfoodfacts.org)
      // Isso garante alimentos comercializados no Brasil, com rótulos da Anvisa 100% em português
      var url = Uri.parse(
        'https://br.openfoodfacts.org/cgi/search.pl?search_terms=$termo&search_simple=1&action=process&json=1',
      );
      
      // Chamada HTTP assíncrona com User-Agent para evitar bloqueios de rede
      var response = await http.get(
        url,
        headers: {'User-Agent': 'HappyBiteApp - Cotemig Academic Project'},
      );

      // Fallback: se a base brasileira retornar erro de conexão, consulta o endpoint mundial
      if (response.statusCode != 200) {
        url = Uri.parse(
          'https://world.openfoodfacts.org/cgi/search.pl?search_terms=$termo&search_simple=1&action=process&json=1',
        );
        response = await http.get(
          url,
          headers: {'User-Agent': 'HappyBiteApp - Cotemig Academic Project'},
        );
      }

      // Status 200 = Sucesso na requisição
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List productsList = data['products'] ?? [];
        
        // FILTRAGEM RIGOROSA DE QUALIDADE (Client-side Data Sanitization):
        // 1. Remove duplicatas pelo código de barras
        // 2. Exige Ficha Completa: Nome válido + Lista de Ingredientes + Alérgenos/Traços identificados
        // 3. Exige Idioma em Português (Brasil / Portugal ou rótulo em português)
        final Set<String> codigosVistos = {};
        final List<Produto> listaTratada = [];

        for (var itemJson in productsList) {
          final produto = Produto.fromJson(itemJson);
          if (!codigosVistos.contains(produto.codigo) &&
              produto.possuiFichaCompleta &&
              _ehEmPortugues(itemJson, produto)) {
            codigosVistos.add(produto.codigo);
            listaTratada.add(produto);
          }
        }

        // RELEVÂNCIA INTELIGENTE DE BUSCA:
        // Prioriza alimentos cujo NOME contenha o termo pesquisado (ex.: pesquisou "leite",
        // exibe prioritariamente "Leite Meio-Gordo", "Leite UHT", "Leite Ninho",
        // descartando itens acidentais como iogurtes, pastas de lentilha ou chocolates).
        final termoNormalizado = _normalizarTexto(termo);
        final List<Produto> relevantesPorNome = [];
        final List<Produto> outrosRelevantes = [];

        for (var p in listaTratada) {
          final nomeNorm = _normalizarTexto(p.nome);
          final marcaNorm = _normalizarTexto(p.marca);
          if (nomeNorm.contains(termoNormalizado) || marcaNorm.contains(termoNormalizado)) {
            relevantesPorNome.add(p);
          } else {
            outrosRelevantes.add(p);
          }
        }

        _produtosBusca = relevantesPorNome.isNotEmpty ? relevantesPorNome : listaTratada;

        // Se a busca não retornou nenhum produto, define mensagem clara para o usuário
        if (_produtosBusca.isEmpty) {
          _erro = 'Nenhum alimento em português com ingredientes e alérgenos declarados foi encontrado para "$termo". Tente pesquisar por termos comuns como pão, bolo, biscoito, chocolate ou oreo.';
        }
      } else {
        _erro = 'A API externa retornou status ${response.statusCode}. Não foi possível carregar os dados.';
      }
    } catch (e) {
      // Tratamento de exceção de rede (ex: falta de internet, timeout ou bloqueio de CORS)
      _erro = 'Erro de conexão com o Open Food Facts. Verifique a internet ou utilize o modo demonstração.';
    } finally {
      // O bloco "finally" SEMPRE é executado: garante que o loading pare
      _isLoading = false;
      notifyListeners(); // Notifica a UI para renderizar a lista ou a mensagem de erro
    }
  }

  // BÔNUS / CONTINGÊNCIA: Carrega produto offline caso haja queda de rede na apresentação
  void carregarProdutoDemonstracao() {
    _produtosBusca = [
      Produto(
        codigo: '7622210449283',
        nome: 'Mini Oreo Recheado (Exemplo de Demonstração)',
        marca: 'Nabisco / Mondelēz',
        ingredientes: 'Farinha de trigo enriquecida, açúcar, gordura vegetal, cacau em pó, açúcar invertido, sal, fermentos químicos.',
        nutricional: 'Nutri-Score: E',
        alergenicos: 'Contém derivados de trigo e soja. Pode conter leite.',
        imagemUrl: 'https://images.openfoodfacts.org/images/products/762/221/044/9283/front_pt.7.400.jpg',
        notaDesrotulando: 2.5, // Nota estilo Desrotulando (0 a 10)
      ),
    ];
    _erro = null;
    notifyListeners();
  }

  // Verifica se um produto específico já está na lista de favoritos
  bool isFavorito(Produto produto) {
    return _favoritos.any((p) => p.codigo == produto.codigo);
  }

  // REQUISITO 6: Alterna o status de favorito e persiste no SharedPreferences
  Future<void> alternarFavorito(Produto produto) async {
    if (isFavorito(produto)) {
      _favoritos.removeWhere((p) => p.codigo == produto.codigo);
    } else {
      _favoritos.add(produto);
    }
    
    // Grava a lista atualizada no SharedPreferences em formato de lista de strings JSON
    final prefs = await SharedPreferences.getInstance();
    final favoritosJson = _favoritos.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList('favoritos', favoritosJson);
    
    notifyListeners(); // Atualiza os botões de coração em tempo real na tela
  }
}