import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/produto.dart';

class AppProvider extends ChangeNotifier {
  String _nomeUsuario = '';
  List<String> _restricoes = [];
  List<Produto> _favoritos = [];
  
  List<Produto> _produtosBusca = [];
  bool _isLoading = false;
  String? _erro;

  String get nomeUsuario => _nomeUsuario;
  List<String> get restricoes => _restricoes;
  List<Produto> get favoritos => _favoritos;
  List<Produto> get produtosBusca => _produtosBusca;
  bool get isLoading => _isLoading;
  String? get erro => _erro;

  AppProvider() {
    _carregarDadosLocais();
  }

  Future<void> _carregarDadosLocais() async {
    final prefs = await SharedPreferences.getInstance();
    _nomeUsuario = prefs.getString('nome_usuario') ?? '';
    
    final restricoesSalvas = prefs.getStringList('restricoes');
    if (restricoesSalvas != null) {
      _restricoes = restricoesSalvas;
    }

    final favoritosJson = prefs.getStringList('favoritos') ?? [];
    _favoritos = favoritosJson.map((item) => Produto.fromJson(jsonDecode(item))).toList();
    
    notifyListeners();
  }

  Future<void> salvarCadastro(String nome, List<String> restricoes) async {
    _nomeUsuario = nome;
    _restricoes = restricoes;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nome_usuario', nome);
    await prefs.setStringList('restricoes', restricoes);
    notifyListeners();
  }

  Future<void> buscarProdutos(String termo) async {
    if (termo.trim().isEmpty) return;

    _isLoading = true;
    _erro = null;
    _produtosBusca = [];
    notifyListeners();

    try {
      final url = Uri.parse(
        'https://world.openfoodfacts.org/cgi/search.pl?search_terms=$termo&search_simple=1&action=process&json=1',
      );
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List productsList = data['products'] ?? [];
        
        _produtosBusca = productsList
            .map((json) => Produto.fromJson(json))
            .where((p) => p.nome != 'Nome não informado')
            .toList();

        if (_produtosBusca.isEmpty) {
          _erro = 'Nenhum alimento encontrado para "$termo". Verifique a ortografia ou tente outro termo.';
        }
      } else {
        _erro = 'A API externa retornou status ${response.statusCode}. Não foi possível carregar os dados.';
      }
    } catch (e) {
      _erro = 'Erro de conexão com o Open Food Facts. Verifique a internet ou utilize o modo demonstração.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método de contingência (Fallback) para demonstração ou modo offline na A3
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

  bool isFavorito(Produto produto) {
    return _favoritos.any((p) => p.codigo == produto.codigo);
  }

  Future<void> alternarFavorito(Produto produto) async {
    if (isFavorito(produto)) {
      _favoritos.removeWhere((p) => p.codigo == produto.codigo);
    } else {
      _favoritos.add(produto);
    }
    
    final prefs = await SharedPreferences.getInstance();
    final favoritosJson = _favoritos.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList('favoritos', favoritosJson);
    notifyListeners();
  }
}