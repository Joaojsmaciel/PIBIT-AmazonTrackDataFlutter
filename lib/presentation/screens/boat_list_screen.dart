import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amazon_track_data/data/models/boat_model.dart';
import 'package:amazon_track_data/presentation/providers/boat_provider.dart';

class BoatListScreen extends ConsumerStatefulWidget {
  const BoatListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BoatListScreen> createState() => _BoatListScreenState();
}

class _BoatListScreenState extends ConsumerState<BoatListScreen> {
  bool _showCreateActions = false;

  void _toggleCreateActions() {
    setState(() => _showCreateActions = !_showCreateActions);
  }

  Future<void> _openRegistration(String path) async {
    setState(() => _showCreateActions = false);
    await context.push(path);
    if (mounted) {
      ref.invalidate(userBoatsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    onPressed: _toggleCreateActions,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userBoatsProvider),
            child: ListView.builder(
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
                  trailing: PopupMenuButton<String>(
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Deletar')),
                    ],
                    onSelected: (value) async {
                      if (value == 'edit') {
                        ref.read(selectedBoatProvider.notifier).state = boat;
                        context.go('/boat-registration');
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Deletar Embarcação'),
                            content: Text(
                                'Deseja remover "${boat.name}"? Esta ação não pode ser desfeita.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Deletar',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            await ref
                                .read(deleteBoatProvider(boat.id).future);
                            ref.invalidate(userBoatsProvider);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Erro ao deletar: $e')),
                              );
                            }
                          }
                        }
                      }
                    },
                  ),
                ),
              );
            },
          ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Erro ao carregar embarcações:\n$err',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(userBoatsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_showCreateActions) ...[
            FloatingActionButton.extended(
              heroTag: 'register_route',
              onPressed: () => _openRegistration('/route-registration'),
              icon: const Icon(Icons.route),
              label: const Text('Cadastrar rota'),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: 'register_boat',
              onPressed: () => _openRegistration('/boat-registration'),
              icon: const Icon(Icons.directions_boat),
              label: const Text('Cadastrar embarcação'),
            ),
            const SizedBox(height: 12),
          ],
          FloatingActionButton(
            heroTag: 'create_menu',
            onPressed: _toggleCreateActions,
            tooltip: _showCreateActions ? 'Fechar opções' : 'Cadastrar',
            child: AnimatedRotation(
              turns: _showCreateActions ? 0.125 : 0,
              duration: const Duration(milliseconds: 220),
              child: Icon(_showCreateActions ? Icons.close : Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
