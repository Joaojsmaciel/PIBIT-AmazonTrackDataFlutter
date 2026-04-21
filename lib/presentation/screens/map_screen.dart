import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';

import 'package:amazon_track_data/presentation/providers/location_provider.dart';
import 'package:amazon_track_data/presentation/providers/map_provider.dart';
import 'package:amazon_track_data/presentation/providers/auth_provider.dart';
import 'package:amazon_track_data/presentation/widgets/map_widget.dart';
import 'package:amazon_track_data/presentation/dialogs/boat_selection_dialog.dart';
import 'package:amazon_track_data/core/extensions/context_extensions.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late MapController mapController;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Popula o cache somente se ainda estiver vazio (login sem passar pela
      // LoginScreen, ex: splash direto para map).
      if (ref.read(userSessionProvider) != null) return;
      ref.read(currentUserProvider).whenData((user) {
        if (user != null) ref.read(userSessionProvider.notifier).state = user;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ao abrir a tela, centra no usuário
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Refresh para garantir que temos a localização mais recente
        Future.microtask(() => ref.refresh(userLocationProvider));
      }
    });
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackedUsers = ref.watch(trackedUsersProvider);
    final userLocationAsync = ref.watch(userLocationProvider);
    final mapCenter = ref.watch(mapCenterProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final isTracking = ref.watch(isTrackingProvider);

    // Popula o cache apenas quando o currentUserProvider terminar de carregar
    // e o cache ainda estiver vazio (evita sobrescrever com dados antigos).
    ref.listen(currentUserProvider, (previous, next) {
      next.whenData((user) {
        if (user != null && ref.read(userSessionProvider) == null) {
          ref.read(userSessionProvider.notifier).state = user;
        }
      });
    });

    // Listen para mudanças de localização
    ref.listen(userLocationProvider, (previous, next) {
      next.whenData((location) {
        if (location != null) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              mapController.move(location, 15);
            }
          });
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa em Tempo Real'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _handleLogout(context, ref),
          ),
        ],
      ),
      body: userLocationAsync.when(
        data: (userLocation) => MapWidget(
          mapController: mapController,
          center: mapCenter,
          trackedUsers: trackedUsers,
          userLocation: userLocation,
          currentUserType: currentUserAsync.valueOrNull?.userType,
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('Erro ao carregar localização: $error'),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 15, right: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'center_location',
              onPressed: () {
                userLocationAsync.whenData((location) {
                  if (location != null) {
                    mapController.move(location, 15);
                  }
                });
              },
              child: const Icon(Icons.my_location),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'start_route',
              backgroundColor: isTracking ? Colors.red : null,
              onPressed: () {
                if (isTracking) {
                  _stopTracking(context, ref);
                } else {
                  showDialog(
                    context: context,
                    builder: (_) => const BoatSelectionDialog(),
                  );
                }
              },
              label: Text(isTracking ? 'Parar' : 'Iniciar'),
              icon: Icon(isTracking ? Icons.stop : Icons.navigation),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_boat),
            label: 'Embarcações',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: 'Rotas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              // Já na tela de mapa
              break;
            case 1:
              context.push('/boat-list');
              break;
            case 2:
              context.push('/routes');
              break;
            case 3:
              context.push('/profile');
              break;
          }
        },
      ),
    );
  }

  void _stopTracking(BuildContext context, WidgetRef ref) {
    ref.read(isTrackingProvider.notifier).state = false;
    ref.read(currentTripIdProvider.notifier).state = null;
    ref.read(selectedBoatForTrackingProvider.notifier).state = null;
    context.showSuccessSnackBar('Rastreamento encerrado.');
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desconectar'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref.read(signOutProvider.future);
                // Limpa o cache do usuário para que o próximo login não
                // mostre dados do usuário anterior.
                ref.read(userSessionProvider.notifier).state = null;
                ref.invalidate(currentUserProvider);
                await Future.delayed(const Duration(milliseconds: 500));
                
                if (context.mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (context.mounted) {
                  context.showErrorSnackBar('Erro ao desconectar: $e');
                }
              }
            },
            child: const Text('Desconectar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
