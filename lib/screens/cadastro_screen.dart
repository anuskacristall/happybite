import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'busca_screen.dart';

// ============================================================================
// TELA 1: CADASTRO / PERFIL DO USUÁRIO (cadastro_screen.dart)
// ============================================================================
// REQUISITO 1: Tela inicial de um fluxo com 4 telas.
// StatefulWidget porque gerencia estados internos mutáveis (texto digitado e checkboxes).
class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});
  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  // REQUISITO 4: Chave global para identificar e validar o formulário
  final _formKey = GlobalKey<FormState>();
  
  // Controlador para o campo de texto do nome
  final _nome = TextEditingController();
  
  // Conjunto (Set) que armazena as restrições selecionadas sem duplicidade
  final Set<String> _restricoes = {};
  
  // Lista expandida de restrições e intolerâncias alimentares
  final opcoes = const [
    'Glúten',
    'Lactose',
    'Proteína do Leite (APLV)',
    'Histamina',
    'Soja',
    'Oleaginosas / Amendoim',
  ];

  // BÔNUS: Controle da animação que revela as opções de restrições (sem efeito fade)
  bool _mostrarRestricoes = false;

  // REQUISITO 6: RESTAURAÇÃO DE DADOS (Ao abrir o app ou dar Hot Restart)
  @override
  void initState() {
    super.initState();
    // Executa logo após a renderização inicial do widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      // Se já houver nome salvo no SharedPreferences, pré-preenche e já exibe tudo
      if (provider.nomeUsuario.isNotEmpty) {
        setState(() {
          _nome.text = provider.nomeUsuario;
          _restricoes.addAll(provider.restricoes);
          _mostrarRestricoes = true;
        });
      }
    });
  }

  // Boa prática: descarta o controller da memória quando o widget for destruído
  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  // Avança do campo de nome para a seleção de restrições com validação
  void _avancarParaRestricoes() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _mostrarRestricoes = true;
    });
  }

  // MÉTODO DE AÇÃO: Validação final e Navegação
  void _continuar() {
    // REQUISITO 4: Dispara o "validator" do TextFormField. Se for inválido, interrompe o fluxo.
    if (!_formKey.currentState!.validate()) return;
    
    // Regra de negócio: exige a seleção de ao menos uma restrição
    if (_restricoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos uma restrição alimentar.')),
      );
      return;
    }

    // REQUISITO 6 e 7: Salva o perfil no Provider (que grava no SharedPreferences)
    Provider.of<AppProvider>(context, listen: false)
        .salvarCadastro(_nome.text.trim(), _restricoes.toList());

    // REQUISITO 1: Navegação para a Tela 2 (BuscaScreen) usando Navigator.push
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BuscaScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        actions: [
          // BÔNUS: Botão de Tema Sol (Claro) / Lua (Escuro)
          IconButton(
            tooltip: provider.isDarkMode ? 'Ativar Modo Claro' : 'Ativar Modo Escuro',
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
            constraints: const BoxConstraints(maxWidth: 520), // Garante responsividade em telas maiores
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // LOGO CENTRALIZADA (substituindo ícone e slogans anteriores)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 170,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // CAMPO DE NOME DO USUÁRIO
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Como podemos te chamar?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: provider.isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nome,
                      decoration: const InputDecoration(
                        hintText: 'Digite seu nome',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      // REQUISITO 4: VALIDAÇÃO RIGOROSA (+3 caracteres e sem símbolos especiais)
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return 'Informe seu nome para continuar.';
                        }
                        final texto = valor.trim();
                        if (texto.length < 3) {
                          return 'O nome deve ter no mínimo 3 caracteres.';
                        }
                        // Expressão regular: apenas letras maiúsculas/minúsculas, acentos e espaços
                        final regexValido = RegExp(r"^[a-zA-ZÀ-ÿ\s]+$");
                        if (!regexValido.hasMatch(texto)) {
                          return 'Digite apenas letras (sem números ou símbolos como @, #, \$, %, &).';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _avancarParaRestricoes(),
                    ),
                    const SizedBox(height: 18),

                    // BÔNUS: ANIMAÇÃO DE DESLIZAMENTO E EXPANSÃO DAS RESTRIÇÕES (Sem efeito Fade)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      child: _mostrarRestricoes
                          ? AnimatedSlide(
                              offset: Offset.zero,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 10),
                                  Text(
                                    'Quais são suas restrições alimentares?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: provider.isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Marque uma ou mais opções para ativarmos os alertas:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: provider.isDarkMode ? Colors.white54 : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...opcoes.map((opcao) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: CheckboxListTile(
                                      title: Text(
                                        opcao,
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      value: _restricoes.contains(opcao),
                                      activeColor: const Color(0xFF247A51),
                                      onChanged: (marcado) => setState(() {
                                        if (marcado == true) {
                                          _restricoes.add(opcao);
                                        } else {
                                          _restricoes.remove(opcao);
                                        }
                                      }),
                                    ),
                                  )),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    // BOTÃO DE AÇÃO DINÂMICO
                    ElevatedButton(
                      onPressed: _mostrarRestricoes ? _continuar : _avancarParaRestricoes,
                      child: Text(
                        _mostrarRestricoes 
                            ? 'Continuar para alimentos →' 
                            : 'Avançar para restrições ↓',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}