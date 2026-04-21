import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amazon_track_data/presentation/providers/boat_provider.dart';

class BoatListScreen extends ConsumerWidget {
  const BoatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boats = ref.watch(userBoatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Embarcações'),
      ),
      body: boats.when(
        data: (boatList) {
          if (boatList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_boat_filled,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('Nenhuma embarcação cadastrada'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/boat-registration'),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Embarcação'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: boatList.length,
            itemBuilder: (context, index) {
              final boat = boatList[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: boat.photoUrl != null
                      ? Image.network(
                          boat.photoUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.directions_boat,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  title: Text(boat.name),
                  subtitle: Text('${boat.type} - Capacidade: ${boat.capacity ?? 'N/A'}'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Editar'),
                        onTap: () => context.go('/boat-registration'),
                      ),
                      PopupMenuItem(
                        child: const Text('Deletar'),
                        onTap: () {
                          ref.read(deleteBoatProvider(boat.id));
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/boat-registration'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
