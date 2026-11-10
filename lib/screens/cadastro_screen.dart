import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'busca_screen.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});
  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final Set<String> _restricoes = {};
  final opcoes = const ['Lactose', 'Glúten', 'Histamina'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      if (provider.nomeUsuario.isNotEmpty) {
        setState(() {
          _nome.text = provider.nomeUsuario;
          _restricoes.addAll(provider.restricoes);
        });
      }
    });
  }

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  void _continuar() {
    if (!_formKey.currentState!.validate()) return;
    if (_restricoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos uma restrição alimentar.')),
      );
      return;
    }

    Provider.of<AppProvider>(context, listen: false)
        .salvarCadastro(_nome.text.trim(), _restricoes.toList());

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BuscaScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Happy Bite',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        )

      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.spa_outlined, size: 62, color: Color(0xFF247A51)),
                const SizedBox(height: 18),
                Text('Comer bem começa aqui!', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Conte um pouco sobre você para explorar nosso catálogo seguro.'),
                const SizedBox(height: 30),
                const Text('Seu nome', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nome,
                  decoration: const InputDecoration(hintText: 'Digite seu nome', prefixIcon: Icon(Icons.person_outline)),
                  validator: (valor) => valor == null || valor.trim().isEmpty ? 'Informe seu nome para continuar.' : null,
                ),
                const SizedBox(height: 28),
                const Text('Quais são suas restrições?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 6),
                const Text('Selecione uma ou mais opções.'),
                const SizedBox(height: 12),
                ...opcoes.map((opcao) => Card(
                  child: CheckboxListTile(
                    title: Text('Intolerância à $opcao'),
                    value: _restricoes.contains(opcao),
                    onChanged: (marcado) => setState(() {
                      if (marcado == true) {
                        _restricoes.add(opcao);
                      } else {
                        _restricoes.remove(opcao);
                      }
                    }),
                  ),
                )),
                const SizedBox(height: 30),
                ElevatedButton(onPressed: _continuar, child: const Text('Continuar para alimentos →')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}