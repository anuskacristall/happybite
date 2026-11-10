import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'detalhes_screen.dart';

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final favoritos = provider.favoritos;

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Favoritos')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Alimentos salvos no dispositivo ❤️', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            Expanded(
              child: favoritos.isEmpty
                  ? const Center(child: Text('Você ainda não possui alimentos favoritos.'))
                  : ListView.builder(
                      itemCount: favoritos.length,
                      itemBuilder: (context, i) {
                        final item = favoritos[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: item.imagemUrl.isNotEmpty
                                ? Image.network(
                                    item.imagemUrl,
                                    width: 40,
                                    height: 40,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.fastfood),
                                  )
                                : const Icon(Icons.fastfood),
                            title: Text(item.nome),
                            subtitle: Text(item.marca),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => DetalhesScreen(produto: item)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
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