import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:amazon_track_data/data/models/trip_summary.dart';
import 'package:amazon_track_data/presentation/providers/auth_provider.dart';
import 'package:amazon_track_data/presentation/providers/trip_provider.dart';

class PassengerTripHistoryScreen extends ConsumerWidget {
  const PassengerTripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userIdAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Viagens')),
      body: userIdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Usuário não encontrado.'));
          }
          return _TripHistoryList(userId: user.uid);
        },
      ),
    );
  }
}

class _TripHistoryList extends ConsumerWidget {
  final String userId;
  const _TripHistoryList({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(userTripsProvider(userId));

    return tripsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Erro ao carregar histórico:\n$e',
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(userTripsProvider(userId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
      data: (trips) {
        if (trips.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhuma viagem registrada ainda.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'As viagens que você acompanhar\naparecerão aqui.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final sorted = [...trips]
          ..sort((a, b) => b.startTimestamp.compareTo(a.startTimestamp));

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(userTripsProvider(userId)),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sorted.length,
            itemBuilder: (context, i) => _TripHistoryCard(
              trip: sorted[i],
              onTap: () => context.push('/trip-detail', extra: sorted[i]),
            ),
          ),
        );
      },
    );
  }
}

class _TripHistoryCard extends StatelessWidget {
  final TripSummary trip;
  final VoidCallback onTap;

  const _TripHistoryCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('HH:mm');
    final duration = trip.duration;
    final durationStr = duration.inHours > 0
        ? '${duration.inHours}h ${duration.inMinutes.remainder(60)}min'
        : '${duration.inMinutes}min';

    final routeParts = <String>[
      if (trip.departurePoint.isNotEmpty) trip.departurePoint,
      ...trip.stops,
      if (trip.arrivalPoint.isNotEmpty) trip.arrivalPoint,
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.sailing,
                        color: Colors.blue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFmt.format(trip.startDate),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          '${timeFmt.format(trip.startDate)} → ${timeFmt.format(trip.endDate)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      durationStr,
                      style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
              if (routeParts.length >= 2) ...[
                const SizedBox(height: 10),
                _RouteChain(parts: routeParts),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StatChip(
                    icon: Icons.speed,
                    label:
                        '${trip.avgSpeedKmh.toStringAsFixed(1)} km/h',
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.straighten,
                    label:
                        '${trip.totalDistanceKm.toStringAsFixed(1)} km',
                    color: Colors.purple,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.location_on,
                    label: '${trip.pointCount} pts',
                    color: Colors.teal,
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right,
                      color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteChain extends StatelessWidget {
  final List<String> parts;
  const _RouteChain({required this.parts});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 2,
      children: [
        for (int i = 0; i < parts.length; i++) ...[
          Text(
            parts[i],
            style: TextStyle(
              fontSize: 13,
              fontWeight: i == 0 || i == parts.length - 1
                  ? FontWeight.w600
                  : FontWeight.normal,
              color: i == 0 || i == parts.length - 1
                  ? Colors.black87
                  : Colors.grey.shade600,
            ),
          ),
          if (i < parts.length - 1)
            Icon(Icons.arrow_forward,
                size: 13, color: Colors.grey.shade400),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }
}
