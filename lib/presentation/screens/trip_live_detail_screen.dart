import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:amazon_track_data/presentation/providers/boat_provider.dart';
import 'package:amazon_track_data/presentation/providers/location_provider.dart';

class TripLiveDetailScreen extends ConsumerStatefulWidget {
  final String boatId;
  final String boatName;

  const TripLiveDetailScreen({
    super.key,
    required this.boatId,
    required this.boatName,
  });

  @override
  ConsumerState<TripLiveDetailScreen> createState() =>
      _TripLiveDetailScreenState();
}

class _TripLiveDetailScreenState
    extends ConsumerState<TripLiveDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeTripsAsync = ref.watch(activeBoatTripsProvider);
    final trailAsync = ref.watch(watchedBoatTrailProvider);

    return activeTripsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(widget.boatName)),
        body: Center(child: Text('Erro: $e')),
      ),
      data: (activeTrips) {
        final info = activeTrips[widget.boatId];

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.boatName,
                    style: const TextStyle(fontSize: 16)),
                if (info != null)
                  Text('${info.speedKmh} km/h',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8))),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.map), text: 'Mapa ao Vivo'),
                Tab(icon: Icon(Icons.list_alt), text: 'Progresso'),
              ],
            ),
          ),
          body: info == null
              ? _NoTripBanner(boatName: widget.boatName)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _LiveMapTab(
                      boatId: widget.boatId,
                      trail: trailAsync.valueOrNull ?? const [],
                      mapController: _mapController,
                      info: info,
                    ),
                    _ProgressTab(info: info),
                  ],
                ),
        );
      },
    );
  }
}

// ─── Sem viagem ───────────────────────────────────────────────────────────────

class _NoTripBanner extends StatelessWidget {
  final String boatName;
  const _NoTripBanner({required this.boatName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.anchor, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('$boatName não está em viagem no momento.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Aguarde o barqueiro iniciar o rastreamento.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── Aba Mapa ao Vivo ─────────────────────────────────────────────────────────

class _LiveMapTab extends ConsumerWidget {
  final String boatId;
  final List<LatLng> trail;
  final MapController mapController;
  final ActiveTripInfo info;

  const _LiveMapTab({
    required this.boatId,
    required this.trail,
    required this.mapController,
    required this.info,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estimatedArrival = info.estimatedArrival;
    final trackedUsers = ref.watch(trackedUsersProvider);
    final boatPos = trackedUsers.valueOrNull
        ?.where((u) => u.boatId == boatId)
        .fold<dynamic>(null, (prev, u) =>
            prev == null || u.timestamp > (prev as dynamic).timestamp
                ? u
                : prev);

    final center = boatPos != null
        ? LatLng(boatPos.latitude, boatPos.longitude)
        : (trail.isNotEmpty ? trail.last : const LatLng(-3.1, -60.0));

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.amazon_track_data',
            ),
            if (trail.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: trail,
                    strokeWidth: 4,
                    color: Colors.blue.shade700,
                  ),
                ],
              ),
            if (boatPos != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(boatPos.latitude, boatPos.longitude),
                    width: 48,
                    height: 48,
                    child: const Icon(
                      Icons.directions_boat,
                      color: Colors.blue,
                      size: 36,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                    ),
                  ),
                ],
              ),
          ],
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: FloatingActionButton.small(
            heroTag: 'trip_center',
            onPressed: () => mapController.move(center, 13),
            child: const Icon(Icons.my_location),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.speed, color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  Text('${info.speedKmh} km/h',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const Icon(Icons.schedule, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    estimatedArrival == null
                        ? 'ETA —'
                        : 'ETA ${DateFormat('HH:mm').format(estimatedArrival)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Aba Progresso ────────────────────────────────────────────────────────────

class _ProgressTab extends StatelessWidget {
  final ActiveTripInfo info;
  const _ProgressTab({required this.info});

  @override
  Widget build(BuildContext context) {
    final allStops = <String>[
      if (info.departurePoint.isNotEmpty) info.departurePoint,
      ...info.stops,
      if (info.arrivalPoint.isNotEmpty) info.arrivalPoint,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EtaOverview(info: info),
          const SizedBox(height: 16),
          _MetricsRow(info: info),
          const SizedBox(height: 24),
          const Text('Rota da Viagem',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (allStops.isEmpty)
            const Center(
                child: Text('Rota não disponível.',
                    style: TextStyle(color: Colors.grey)))
          else
            _RouteTimeline(stops: allStops),
          const SizedBox(height: 24),
          _LiveIndicator(),
        ],
      ),
    );
  }
}

class _EtaOverview extends StatelessWidget {
  final ActiveTripInfo info;
  const _EtaOverview({required this.info});

  @override
  Widget build(BuildContext context) {
    final arrival = info.estimatedArrival;
    final remaining = info.remainingDuration;
    final distance = info.distanceRemainingMeters;
    final progress = info.progress;

    return Card(
      elevation: 2,
      color: Colors.teal.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.teal.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2F1),
                  child: Icon(Icons.route, color: Colors.teal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimativa de chegada',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        arrival == null
                            ? 'Calculando ETA…'
                            : DateFormat('HH:mm').format(arrival),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (info.arrivalPoint.isNotEmpty)
                  Flexible(
                    child: Text(
                      info.arrivalPoint,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _EtaMetric(
                    icon: Icons.timelapse,
                    label: 'Tempo restante',
                    value: _formatDuration(remaining),
                  ),
                ),
                Expanded(
                  child: _EtaMetric(
                    icon: Icons.location_on_outlined,
                    label: 'Distância',
                    value: _formatDistance(distance),
                  ),
                ),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: Colors.teal.withOpacity(0.12),
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${(progress * 100).round()}% do tempo estimado',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EtaMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _EtaMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.teal),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatDuration(Duration? duration) {
  if (duration == null) return '—';
  if (duration == Duration.zero) return 'Chegando';
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return hours > 0 ? '${hours}h ${minutes}min' : '$minutes min';
}

String _formatDistance(double? meters) {
  if (meters == null) return '—';
  return meters >= 1000
      ? '${(meters / 1000).toStringAsFixed(1)} km'
      : '${meters.toStringAsFixed(0)} m';
}

class _MetricsRow extends StatelessWidget {
  final ActiveTripInfo info;
  const _MetricsRow({required this.info});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.speed,
            color: Colors.blue,
            label: 'Velocidade',
            value: '${info.speedKmh} km/h',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            icon: Icons.person,
            color: Colors.green,
            label: 'Barqueiro',
            value: info.captainName.split(' ').first,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _MetricCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }
}

class _RouteTimeline extends StatelessWidget {
  final List<String> stops;
  const _RouteTimeline({required this.stops});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(stops.length, (i) {
        final isFirst = i == 0;
        final isLast = i == stops.length - 1;
        final color = isFirst
            ? Colors.blue
            : isLast
                ? Colors.green
                : Colors.orange;
        final icon = isFirst
            ? Icons.radio_button_checked
            : isLast
                ? Icons.flag
                : Icons.circle;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Icon(icon, color: color, size: isFirst || isLast ? 20 : 14),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      color: Colors.grey.shade300,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 8),
                child: Text(
                  stops[i],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isFirst || isLast
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isFirst || isLast
                        ? Colors.black87
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _LiveIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'Dados atualizados em tempo real via DTN sync',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}
