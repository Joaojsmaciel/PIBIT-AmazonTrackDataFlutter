import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amazon_track_data/data/models/boat_model.dart';
import 'package:amazon_track_data/presentation/providers/boat_provider.dart';
import 'package:amazon_track_data/presentation/providers/geofence_provider.dart';
import 'package:amazon_track_data/core/extensions/context_extensions.dart';
import 'boat_chat_screen.dart';
import 'trip_live_detail_screen.dart';

class BoatDetailScreen extends ConsumerWidget {
  final BoatModel boat;
  final ActiveTripInfo? activeTripInfo;

  const BoatDetailScreen({
    super.key,
    required this.boat,
    this.activeTripInfo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchedBoatId = ref.watch(watchedBoatIdProvider);
    final isWatching = watchedBoatId == boat.id;
    final isActive = activeTripInfo != null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                boat.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
              background: _BoatHero(photoUrl: boat.photoUrl),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusBanner(isActive: isActive, info: activeTripInfo),
                  const SizedBox(height: 20),
                  _SectionTitle('Informações da Embarcação'),
                  const SizedBox(height: 12),
                  _InfoCard(children: [
                    _InfoRow(
                      icon: Icons.directions_boat,
                      label: 'Tipo',
                      value: boat.type,
                    ),
                    _InfoRow(
                      icon: Icons.person,
                      label: 'Barqueiro',
                      value: boat.ownerName,
                    ),
                    if (boat.capacity != null && boat.capacity! > 0)
                      _InfoRow(
                        icon: Icons.people,
                        label: 'Capacidade',
                        value: '${boat.capacity} passageiros',
                      ),
                    if (activeTripInfo != null) ...[
                      _InfoRow(
                        icon: Icons.speed,
                        label: 'Velocidade atual',
                        value: '${activeTripInfo!.speedKmh} km/h',
                      ),
                    ],
                  ]),
                  if (isActive && activeTripInfo != null) ...[
                    const SizedBox(height: 20),
                    _SectionTitle('Viagem Atual'),
                    const SizedBox(height: 12),
                    _CurrentTripCard(info: activeTripInfo!),
                  ],
                  if (boat.routeCities.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionTitle('Rotas Habituais'),
                    const SizedBox(height: 12),
                    _RouteCitiesCard(cities: boat.routeCities),
                  ],
                  const SizedBox(height: 24),
                  _ActionButtons(
                    boat: boat,
                    isActive: isActive,
                    isWatching: isWatching,
                    activeTripInfo: activeTripInfo,
                    onToggleWatch: () async {
                      if (isWatching) {
                        await ref
                            .read(watchedBoatIdProvider.notifier)
                            .setWatchedBoat(null);
                        if (context.mounted) {
                          context.showSuccessSnackBar(
                              'Deixou de acompanhar ${boat.name}');
                        }
                      } else {
                        await ref
                            .read(watchedBoatIdProvider.notifier)
                            .setWatchedBoat(boat.id);
                        if (context.mounted) {
                          context.showSuccessSnackBar(
                              'Acompanhando ${boat.name}');
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero / Foto ─────────────────────────────────────────────────────────────

class _BoatHero extends StatelessWidget {
  final String? photoUrl;
  const _BoatHero({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return Image.network(
        photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade800, Colors.blue.shade400],
        ),
      ),
      child: const Center(
        child: Icon(Icons.directions_boat, size: 80, color: Colors.white54),
      ),
    );
  }
}

// ─── Banner de status ─────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final bool isActive;
  final ActiveTripInfo? info;
  const _StatusBanner({required this.isActive, required this.info});

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = isActive
        ? (Colors.green, Icons.sailing, 'Em viagem')
        : (Colors.grey.shade600, Icons.anchor, 'Disponível / Atracado');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ─── Viagem ativa ─────────────────────────────────────────────────────────────

class _CurrentTripCard extends StatelessWidget {
  final ActiveTripInfo info;
  const _CurrentTripCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (info.departurePoint.isNotEmpty) info.departurePoint,
      ...info.stops,
      if (info.arrivalPoint.isNotEmpty) info.arrivalPoint,
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (parts.length >= 2) ...[
              Row(
                children: [
                  const Icon(Icons.place, color: Colors.blue, size: 18),
                  const SizedBox(width: 6),
                  Text('Partida: ${parts.first}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              if (parts.length > 2) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: parts
                        .sublist(1, parts.length - 1)
                        .map((s) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(s,
                                      style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  const Icon(Icons.flag, color: Colors.green, size: 18),
                  const SizedBox(width: 6),
                  Text('Destino: ${parts.last}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text('Barqueiro: ${info.captainName}',
                    style: const TextStyle(fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Rotas habituais ──────────────────────────────────────────────────────────

class _RouteCitiesCard extends StatelessWidget {
  final List<String> cities;
  const _RouteCitiesCard({required this.cities});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: cities
          .map((c) => Chip(
                label: Text(c, style: const TextStyle(fontSize: 13)),
                backgroundColor: Colors.blue.withOpacity(0.08),
                side: BorderSide(color: Colors.blue.withOpacity(0.3)),
              ))
          .toList(),
    );
  }
}

// ─── Botões de ação ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final BoatModel boat;
  final bool isActive;
  final bool isWatching;
  final ActiveTripInfo? activeTripInfo;
  final VoidCallback onToggleWatch;

  const _ActionButtons({
    required this.boat,
    required this.isActive,
    required this.isWatching,
    required this.activeTripInfo,
    required this.onToggleWatch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isActive) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TripLiveDetailScreen(
                    boatId: boat.id,
                    boatName: boat.name,
                  ),
                ),
              ),
              icon: const Icon(Icons.navigation),
              label: const Text('Ver Viagem em Tempo Real'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BoatChatScreen(
                      boatName: boat.name,
                      ownerName: boat.ownerName,
                      ownerId: boat.ownerId,
                    ),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Mensagem'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onToggleWatch,
                icon: Icon(
                  isWatching
                      ? Icons.notifications_off_outlined
                      : Icons.notifications_active_outlined,
                ),
                label: Text(isWatching ? 'Parar' : 'Acompanhar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isWatching ? Colors.red.shade600 : Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Helpers visuais ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
