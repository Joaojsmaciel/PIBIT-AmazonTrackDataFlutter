import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:amazon_track_data/presentation/providers/geofence_provider.dart';
import 'package:amazon_track_data/presentation/providers/location_provider.dart';
import 'package:amazon_track_data/presentation/providers/map_provider.dart';
import 'package:amazon_track_data/presentation/providers/auth_provider.dart';
import 'package:amazon_track_data/presentation/providers/chat_provider.dart';
import 'package:amazon_track_data/presentation/widgets/map_widget.dart';
import 'package:amazon_track_data/presentation/dialogs/boat_selection_dialog.dart';
import 'package:amazon_track_data/presentation/screens/barqueiro_inbox_screen.dart';
import 'package:amazon_track_data/presentation/screens/trip_calendar_screen.dart';
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
    final restoredTracking = ref.watch(restoreActiveTrackingProvider);
    ref.watch(backgroundLocationBridgeProvider);
    final ports = ref.watch(portosProvider);
    final latestGeofenceEvent = ref.watch(latestGeofenceEventProvider);
    final offlinePending = ref.watch(offlinePendingCountProvider);

    // Popula o cache apenas quando o currentUserProvider terminar de carregar
    // e o cache ainda estiver vazio (evita sobrescrever com dados antigos).
    ref.listen(currentUserProvider, (previous, next) {
      next.whenData((user) {
        if (user != null && ref.read(userSessionProvider) == null) {
          ref.read(userSessionProvider.notifier).state = user;
        }
      });
    });

    // Atualiza o evento de geofence mais recente
    ref.listen(geofenceEventsProvider, (_, next) {
      next.whenData((event) {
        ref.read(latestGeofenceEventProvider.notifier).state = event;
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
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Calendário de Viagens',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TripCalendarScreen(isBarqueiro: true),
              ),
            ),
          ),
          // Indicador de pontos offline pendentes
          offlinePending.when(
            data: (count) => count > 0
                ? Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Tooltip(
                      message: '$count ponto(s) pendentes de sync',
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.cloud_off, size: 22),
                          Positioned(
                            top: 6,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                  minWidth: 14, minHeight: 14),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 9),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: restoredTracking.isLoading
                ? null
                : () => _handleLogout(context, ref),
          ),
        ],
      ),
      // O mapa é exibido imediatamente; o marcador do usuário aparece
      // assim que o GPS retornar posição (sem bloquear a tela).
      body: MapWidget(
        mapController: mapController,
        center: mapCenter,
        trackedUsers: trackedUsers,
        userLocation: userLocationAsync.valueOrNull,
        currentUserType: currentUserAsync.valueOrNull?.userType,
        ports: ports,
        nearestPortEvent: latestGeofenceEvent,
        liveTrail: ref.watch(liveTrailProvider),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 15, right: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Botão: ver todos os portos (zoom sobre o Amazonas)
            FloatingActionButton(
              heroTag: 'view_ports',
              mini: true,
              tooltip: 'Ver portos',
              onPressed: () => mapController.move(
                const LatLng(-3.5, -62.0),
                6.0, // zoom suficiente para ver toda a calha do rio
              ),
              child: const Icon(Icons.anchor),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'center_location',
              tooltip: 'Minha localização',
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
              onPressed: restoredTracking.isLoading ? null : () {
                if (isTracking) {
                  _stopTracking(context, ref);
                } else {
                  showDialog(
                    context: context,
                    builder: (_) => const BoatSelectionDialog(),
                  );
                }
              },
              label: Text(
                restoredTracking.isLoading
                    ? 'Restaurando'
                    : isTracking
                        ? 'Parar'
                        : 'Iniciar',
              ),
              icon: restoredTracking.isLoading
                  ? const Icon(Icons.sync)
                  : Icon(isTracking ? Icons.stop : Icons.navigation),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Mapa',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.directions_boat),
            label: 'Embarcações',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: 'Rotas',
          ),
          BottomNavigationBarItem(
            icon: _InboxBadge(),
            label: 'Mensagens',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              context.push('/boat-list');
              break;
            case 2:
              context.push('/routes');
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const BarqueiroInboxScreen()),
              );
              break;
            case 4:
              context.push('/profile');
              break;
          }
        },
      ),
    );
  }

  Future<void> _stopTracking(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(stopTrackingWithResetProvider.future);
      ref.read(latestGeofenceEventProvider.notifier).state = null;
      ref.invalidate(restoreActiveTrackingProvider);
      if (context.mounted) {
        context.showSuccessSnackBar('Rastreamento encerrado.');
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar('Não foi possível encerrar: $e');
      }
    }
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    if (ref.read(isTrackingProvider)) {
      context.showErrorSnackBar(
        'Encerre a viagem antes de desconectar.',
      );
      return;
    }

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

/// Ícone da tab "Mensagens" com badge indicando se há conversas.
class _InboxBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxAsync = ref.watch(barqueiroChatInboxProvider);
    final count = inboxAsync.valueOrNull?.length ?? 0;

    if (count == 0) return const Icon(Icons.chat_bubble_outline);

    return Badge(
      label: Text('$count'),
      child: const Icon(Icons.chat_bubble_outline),
    );
  }
}
