import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:amazon_track_data/data/models/boat_model.dart';
import 'package:amazon_track_data/data/models/user_model.dart';
import 'package:amazon_track_data/core/extensions/context_extensions.dart';
import 'package:amazon_track_data/core/validators/validators.dart';
import 'package:amazon_track_data/presentation/providers/auth_provider.dart';
import 'package:amazon_track_data/presentation/providers/boat_provider.dart';
import 'package:amazon_track_data/presentation/providers/location_provider.dart';
import 'package:amazon_track_data/presentation/providers/map_provider.dart';
import 'package:amazon_track_data/presentation/widgets/map_widget.dart';

class PassengerHomeScreen extends ConsumerStatefulWidget {
  const PassengerHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PassengerHomeScreen> createState() =>
      _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends ConsumerState<PassengerHomeScreen> {
  int _currentIndex = 0;
  late MapController _mapController;

  static const _titles = ['Mapa', 'Embarcações', 'Perfil'];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(userSessionProvider) != null) return;
      ref.read(currentUserProvider).whenData((user) {
        if (user != null) ref.read(userSessionProvider.notifier).state = user;
      });
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userLocationProvider, (previous, next) {
      if (_currentIndex != 0) return;
      next.whenData((location) {
        if (location != null) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _mapController.move(location, 15);
          });
        }
      });
    });

    ref.listen(currentUserProvider, (previous, next) {
      next.whenData((user) {
        if (user != null && ref.read(userSessionProvider) == null) {
          ref.read(userSessionProvider.notifier).state = user;
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Atualizar',
              onPressed: () {
                ref.invalidate(userLocationProvider);
                ref.invalidate(trackedUsersProvider);
              },
            ),
          if (_currentIndex == 1)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Atualizar',
              onPressed: () {
                ref.invalidate(allBoatsProvider);
                ref.invalidate(activeBoatTripsProvider);
              },
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _MapTab(mapController: _mapController),
          const _BoatsTab(),
          const _ProfileTab(),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              heroTag: 'passenger_center',
              onPressed: () {
                ref.read(userLocationProvider).whenData((location) {
                  if (location != null) _mapController.move(location, 15);
                });
              },
              child: const Icon(Icons.my_location),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_boat),
            label: 'Embarcações',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ─── Aba 0: Mapa ──────────────────────────────────────────────────────────────

class _MapTab extends ConsumerWidget {
  final MapController mapController;
  const _MapTab({required this.mapController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackedUsers = ref.watch(trackedUsersProvider);
    final userLocationAsync = ref.watch(userLocationProvider);
    final mapCenter = ref.watch(mapCenterProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    return userLocationAsync.when(
      data: (userLocation) => MapWidget(
        mapController: mapController,
        center: mapCenter,
        trackedUsers: trackedUsers,
        userLocation: userLocation,
        currentUserType: currentUserAsync.valueOrNull?.userType,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('Erro ao carregar localização: $error',
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Aba 1: Embarcações ───────────────────────────────────────────────────────

class _BoatsTab extends ConsumerWidget {
  const _BoatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boatsAsync = ref.watch(allBoatsProvider);
    final activeTripsAsync = ref.watch(activeBoatTripsProvider);

    return boatsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Erro ao carregar embarcações:\n$e',
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(allBoatsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
      data: (boats) {
        if (boats.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_boat, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhuma embarcação cadastrada.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final activeTrips = activeTripsAsync.valueOrNull ?? {};

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: boats.length,
          itemBuilder: (context, index) {
            final boat = boats[index];
            final activeTripInfo = activeTrips[boat.id];
            return _BoatCard(boat: boat, activeTripInfo: activeTripInfo);
          },
        );
      },
    );
  }
}

class _BoatCard extends StatelessWidget {
  final BoatModel boat;
  final ActiveTripInfo? activeTripInfo;

  const _BoatCard({required this.boat, required this.activeTripInfo});

  @override
  Widget build(BuildContext context) {
    final isActive = activeTripInfo != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isActive ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? const BorderSide(color: Colors.green, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _BoatAvatar(photoUrl: boat.photoUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        boat.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${boat.type}  •  ${boat.ownerName}',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[600]),
                      ),
                      if (boat.capacity != null && boat.capacity! > 0)
                        Text(
                          '${boat.capacity} passageiros',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500]),
                        ),
                    ],
                  ),
                ),
                _StatusBadge(isActive: isActive),
              ],
            ),
            if (boat.routeCities.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: boat.routeCities
                    .map((city) => Chip(
                          label: Text(city,
                              style: const TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          backgroundColor:
                              Colors.blue.withOpacity(0.08),
                          side: BorderSide(
                              color: Colors.blue.withOpacity(0.3)),
                        ))
                    .toList(),
              ),
            ],
            if (isActive) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              _ActiveTripDetails(info: activeTripInfo!),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.15)
            : Colors.grey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.green : Colors.grey,
        ),
      ),
      child: Text(
        isActive ? 'Em viagem' : 'Disponível',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.green[700] : Colors.grey[600],
        ),
      ),
    );
  }
}

class _BoatAvatar extends StatelessWidget {
  final String? photoUrl;
  const _BoatAvatar({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          photoUrl!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.directions_boat, color: Colors.blue, size: 30),
    );
  }
}

class _ActiveTripDetails extends StatelessWidget {
  final ActiveTripInfo info;
  const _ActiveTripDetails({required this.info});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (info.departurePoint.isNotEmpty || info.arrivalPoint.isNotEmpty)
          _RouteRow(
            departure: info.departurePoint,
            stops: info.stops,
            arrival: info.arrivalPoint,
          ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.person, size: 15, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text('Barqueiro: ${info.captainName}',
                style: TextStyle(fontSize: 13, color: Colors.grey[700])),
            const SizedBox(width: 16),
            Icon(Icons.speed, size: 15, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text('${info.speedKmh} km/h',
                style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          ],
        ),
      ],
    );
  }
}

class _RouteRow extends StatelessWidget {
  final String departure;
  final List<String> stops;
  final String arrival;

  const _RouteRow(
      {required this.departure,
      required this.stops,
      required this.arrival});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (departure.isNotEmpty) departure,
      ...stops,
      if (arrival.isNotEmpty) arrival,
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 2,
      children: [
        for (int i = 0; i < parts.length; i++) ...[
          Text(parts[i],
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          if (i < parts.length - 1)
            Icon(Icons.arrow_forward, size: 14, color: Colors.grey[500]),
        ],
      ],
    );
  }
}

// ─── Aba 2: Perfil ────────────────────────────────────────────────────────────

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cachedUser = ref.watch(userSessionProvider);
    final userAsync = cachedUser != null
        ? AsyncValue<UserModel?>.data(cachedUser)
        : ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Usuário não encontrado'));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0] : '?',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoField(
                          label: 'Nome Completo', value: user.fullName),
                      const SizedBox(height: 16),
                      _InfoField(label: 'Email', value: user.email),
                      const SizedBox(height: 16),
                      _InfoField(
                        label: 'CPF',
                        value: user.cpf.length == 11
                            ? Validators.formatCPF(user.cpf)
                            : user.cpf.isEmpty
                                ? 'Não informado'
                                : user.cpf,
                      ),
                      const SizedBox(height: 16),
                      _InfoField(
                        label: 'Tipo de Usuário',
                        value: user.userType.name,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _handleLogout(context, ref),
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Desconectar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
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
                ref.read(userSessionProvider.notifier).state = null;
                ref.invalidate(currentUserProvider);
                await Future.delayed(const Duration(milliseconds: 500));
                if (context.mounted) context.go('/login');
              } catch (e) {
                if (context.mounted) {
                  context.showErrorSnackBar('Erro ao desconectar: $e');
                }
              }
            },
            child: const Text('Desconectar',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  const _InfoField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

