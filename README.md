# Happy Bite

Aplicativo mobile desenvolvido em Flutter focado em segurança alimentar, leitura simplificada de rótulos e detecção de intolerâncias alimentares (como glúten, lactose e histamina).

---

## 1. Identificação
- **Nome do Aplicativo:** Happy Bite
- **Squad:** Squad Happy Bite
- **Instituição:** Faculdade Cotemig
- **Integrantes:**
  - **Anuska Cristal Martinho Quintela Campos Oliveira** | Matrícula: 72401265 | Contato: 72401265@aluno.faculdadecotemig.br
  - **Luiz Carlos de Souza Lemos** | Matrícula: 72401109 | Contato: 72401109@aluno.faculdadecotemig.br
  - **Thiago Samuel Gomes** | Matrícula: 72401419 | Contato: 72401419@aluno.faculdadecotemig.br
- **Repositório Git:** https://github.com/anuskacristall/happybite.git

---

## 2. Sobre o Projeto
O **Happy Bite** é uma ferramenta desenvolvida para pessoas com intolerâncias e restrições alimentares (especialmente glúten, lactose e histamina). Ao cadastrar seu perfil com suas restrições alimentares, o usuário pode pesquisar em tempo real qualquer alimento através da base de dados pública do *Open Food Facts*. O aplicativo percorre um fluxo completo composto por 4 telas: inicia na tela de **Cadastro/Perfil**, segue para a tela de **Busca/Catálogo**, avança para a tela de **Detalhes** (onde ocorre o cruzamento automatizado de ingredientes com alertas visuais coloridos e nota de saudabilidade de 0 a 10) e permite gerenciar itens na tela de **Favoritos**. O fluxo foi projetado para ser intuitivo, seguro, resiliente e acessível para qualquer pessoa no momento da compra no supermercado.

---

## 3. Requisitos Atendidos
Tabela de mapeamento dos 8 requisitos obrigatórios exigidos no Guia da A3:

| # | Requisito Obrigatório | Onde está implementado no código | Detalhes da Implementação |
|---|---|---|---|
| **1** | **Pelo menos 4 telas com `Navigator.push` e `pop`** | `lib/screens/cadastro_screen.dart`<br>`lib/screens/busca_screen.dart`<br>`lib/screens/detalhes_screen.dart`<br>`lib/screens/favoritos_screen.dart` | O app possui 4 telas completas interconectadas via `Navigator.push` (rotas dinâmicas) e `Navigator.pop` (retorno em botões dedicados e AppBar). |
| **2** | **API REST com `http` e `async/await`** | `lib/providers/app_provider.dart` (`buscarProdutos()`) | Consulta assíncrona GET na API do Open Food Facts com `async/await`, `jsonDecode` e tipagem dinâmica dos alimentos. |
| **3** | **Loading e erro visíveis na UI** | `lib/screens/busca_screen.dart` (linhas 72–115)<br>`lib/providers/app_provider.dart` | `CircularProgressIndicator` durante requisições, tratamento de erro com mensagem explicativa em caso de falha de conexão ou busca vazia, botão de tentar novamente e modo demonstração offline. |
| **4** | **Formulário com `Form` e `validator`** | `lib/screens/cadastro_screen.dart` (linhas 55–85) | `GlobalKey<FormState>`, `Form` e `TextFormField` com `validator` para conferência de preenchimento obrigatório e validação de restrições alimentares. |
| **5** | **Lista dinâmica com `ListView.builder`** | `lib/screens/busca_screen.dart`<br>`lib/screens/favoritos_screen.dart` | Renderização performática dos resultados da busca e dos itens salvos como favoritos utilizando `ListView.builder`. |
| **6** | **`SharedPreferences` persiste ao reabrir o app** | `lib/providers/app_provider.dart`<br>`lib/screens/cadastro_screen.dart` | Persistência do nome do usuário, das restrições selecionadas e da lista de produtos favoritos serializados em JSON. Carregados na inicialização e restaurados automaticamente. |
| **7** | **Provider: telas, HTTP e prefs separados** | `lib/models/produto.dart`<br>`lib/providers/app_provider.dart`<br>`lib/screens/` | Arquitetura limpa: models com parse JSON, Provider centralizando regras de negócio/HTTP/SharedPreferences, e telas isoladas apenas como camada de visualização. |
| **8** | **App abre e percorre o fluxo sem crashar** | Projeto completo e `test/widget_test.dart` | Resiliência de ponta a ponta: testes unitários passando (`flutter test`), `errorBuilder` em imagens da web, blocos `try/catch/finally` e contingência de fallback. |

---

## 4. API e Dados Remotos
- **Tipo de API:** API pública (sem necessidade de token ou chave de autenticação privada).
- **URL Base:** `https://world.openfoodfacts.org`
- **Endpoint Principal:** `/cgi/search.pl`
  - Exemplo de requisição: `https://world.openfoodfacts.org/cgi/search.pl?search_terms=oreo&search_simple=1&action=process&json=1`
- **Formato de Dados:** JSON (objeto com array `products`).
- **Campos Mapeados:** `code`, `product_name`, `brands`, `ingredients_text_pt`, `nutriscore_grade`, `allergens`, `image_front_url`.

---

## 5. Como Rodar o Projeto
### Pré-requisitos:
- Flutter SDK versão `>= 3.13.0` (homologado no Flutter `3.47.x` / Dart `3.13.x`).
- Plataformas suportadas: Android, iOS, Web (Google Chrome) e Desktop (Windows/macOS/Linux).

### Comandos de Execução:
1. Clone o repositório ou descompacte o arquivo do projeto:
   ```bash
   git clone https://github.com/anuskacristall/happybite.git
   cd happybite
   ```
2. Instale as dependências:
   ```bash
   flutter pub get
   ```
3. Execute a verificação de código e testes:
   ```bash
   dart analyze
   flutter test
   ```
4. Execute o aplicativo (exemplo no Google Chrome ou no dispositivo conectado):
   ```bash
   flutter run -d chrome
   ```
   *Ou no Android / Emulador:*
   ```bash
   flutter run
   ```

---

## 6. Backend Local
**Não aplicável.**
Conforme as instruções oficiais do Guia da A3 (página 2), como o projeto consome exclusivamente a **API pública** do *Open Food Facts*, a criação de um backend local não é necessária e a seção correspondente foi dispensada.

---

## 7. Estrutura do Código
Organização modular e desacoplada em camadas:
```text
lib/
├── main.dart                  # Ponto de entrada, configuração do tema Material 3 e MultiProvider
├── models/
│   └── produto.dart           # Modelo de dados, fromJson, toJson e algoritmo de nota Desrotulando
├── providers/
│   └── app_provider.dart      # ChangeNotifier: estado global, SharedPreferences e requisições HTTP
└── screens/
    ├── cadastro_screen.dart   # Tela 1: Formulário com Form, validator e preferências do usuário
    ├── busca_screen.dart      # Tela 2: Campo de busca, integração REST, loading e ListView.builder
    ├── detalhes_screen.dart   # Tela 3: Cruzamento de restrições, banner dinâmico e tradução
    └── favoritos_screen.dart  # Tela 4: Listagem dos alimentos favoritados salvos localmente
```

---

## 8. Observações
- **Limitações:**
  - A API pública do *Open Food Facts* é colaborativa mundialmente; alguns produtos cadastrados na Europa não possuem tradução completa dos ingredientes para o português.
  - Requer conexão com a internet para realizar novas buscas no banco de dados remoto da API.
- **Bônus e Funcionalidades Extras Implementadas:**
  - **Selo de Qualidade Nutricional (0 a 10):** Algoritmo que converte o *Nutri-Score* internacional (letras A a E) em uma nota contínua de saudabilidade inspirada no aplicativo *Desrotulando*.
  - **Dicionário Multilíngue de Ingredientes:** Mapeamento interno com mais de 30 termos técnicos em inglês, francês e alemão convertidos automaticamente para o português com formatação gramatical adequada.
  - **Cruzamento Inteligente de Sinônimos:** Reconhecimento avançado de derivados (por exemplo: detecção de farinha de trigo, centeio, cevada e aveia quando a restrição marcada é Glúten).
  - **Modo Demonstração (Fallback Resiliente):** Botão de contingência para apresentação caso haja queda de rede na sala de aula.
- **O que ficou para próximas versões:**
  - Leitor de código de barras físico utilizando a câmera do smartphone (`mobile_scanner`).
  - Filtro por valores nutricionais (baixo teor de sódio ou gorduras).