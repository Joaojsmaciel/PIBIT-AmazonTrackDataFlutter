import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:amazon_track_data/data/models/trip_summary.dart';
import 'package:amazon_track_data/data/models/boat_model.dart';
import 'package:amazon_track_data/presentation/providers/auth_provider.dart';
import 'package:amazon_track_data/presentation/providers/trip_provider.dart';
import 'package:amazon_track_data/presentation/providers/boat_provider.dart';

class RouteSelectionScreen extends ConsumerStatefulWidget {
  const RouteSelectionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RouteSelectionScreen> createState() =>
      _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends ConsumerState<RouteSelectionScreen> {
  BoatModel? _selectedBoat;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userSessionProvider);
    final userId = currentUser?.uid ?? ref.watch(currentUserIdProvider);
    final boatsAsync = ref.watch(userBoatsProvider);

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Histórico de Viagens')),
        body: const Center(child: Text('Usuário não identificado.')),
      );
    }

    final tripsAsync = ref.watch(userTripsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Viagens'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filtro por embarcação ──────────────────────────────────
          boatsAsync.when(
            data: (boats) {
              if (boats.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: DropdownButtonFormField<BoatModel?>(
                  value: _selectedBoat,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por embarcação',
                    prefixIcon: Icon(Icons.directions_boat),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<BoatModel?>(
                      value: null,
                      child: Text('Todas as embarcações'),
                    ),
                    ...boats.map((b) => DropdownMenuItem<BoatModel?>(
                          value: b,
                          child: Text(b.name),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedBoat = v),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // ── Lista de viagens ───────────────────────────────────────
          Expanded(
            child: tripsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text('Erro ao carregar viagens: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.invalidate(userTripsProvider(userId)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
              data: (trips) {
                final filtered = _selectedBoat == null
                    ? trips
                    : trips
                        .where((t) =>
                            t.boatId.isEmpty ||
                            t.boatId == _selectedBoat!.id)
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.route,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _selectedBoat == null
                              ? 'Nenhuma viagem registrada ainda.'
                              : 'Nenhuma viagem para esta embarcação.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Inicie um rastreamento no mapa para registrar viagens.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(userTripsProvider(userId)),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) => _TripCard(
                      trip: filtered[index],
                      onTap: () => context.push(
                        '/trip-detail',
                        extra: filtered[index],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripSummary trip;
  final VoidCallback onTap;

  const _TripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('HH:mm');
    final dur = trip.duration;
    final durStr = dur.inHours > 0
        ? '${dur.inHours}h ${dur.inMinutes.remainder(60)}min'
        : '${dur.inMinutes}min ${dur.inSeconds.remainder(60)}s';

    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    dateFmt.format(trip.startDate),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              // Rota textual (partida → chegada) se disponível
              if (trip.departurePoint.isNotEmpty ||
                  trip.arrivalPoint.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.play_arrow,
                        size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        trip.departurePoint.isNotEmpty
                            ? trip.departurePoint
                            : '—',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward,
                          size: 12, color: Colors.grey),
                    ),
                    const Icon(Icons.flag, size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        trip.arrivalPoint.isNotEmpty
                            ? trip.arrivalPoint
                            : '—',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  _TimeBadge(
                      color: Colors.green,
                      icon: Icons.play_arrow,
                      label: timeFmt.format(trip.startDate)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward,
                        size: 16, color: Colors.grey),
                  ),
                  _TimeBadge(
                      color: Colors.red,
                      icon: Icons.stop,
                      label: timeFmt.format(trip.endDate)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Stat(
                      icon: Icons.timer,
                      label: 'Duração',
                      value: durStr),
                  _Stat(
                      icon: Icons.speed,
                      label: 'Vel. média',
                      value:
                          '${trip.avgSpeedKmh.toStringAsFixed(1)} km/h'),
                  _Stat(
                      icon: Icons.straighten,
                      label: 'Distância',
                      value: trip.totalDistanceKm >= 1
                          ? '${trip.totalDistanceKm.toStringAsFixed(2)} km'
                          : '${trip.totalDistanceMeters.toStringAsFixed(0)} m'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _TimeBadge(
      {required this.color, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, size: 10, color: Colors.white),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Stat(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon,
            size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold)),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
