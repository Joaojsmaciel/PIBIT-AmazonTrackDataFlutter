import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:amazon_track_data/data/models/trip_summary.dart';
import 'package:amazon_track_data/presentation/providers/trip_provider.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final TripSummary summary;

  const TripDetailScreen({Key? key, required this.summary}) : super(key: key);

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  List<LatLng> _allPoints = [];
  // Índice do ponto "atual" do marcador animado (embarcação percorrendo a rota)
  int _travelerIndex = 0;
  bool _animationStarted = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this);
    _animController.addListener(() {
      final n = (_animController.value * (_allPoints.length - 1))
          .round()
          .clamp(0, _allPoints.isEmpty ? 0 : _allPoints.length - 1);
      if (mounted) setState(() => _travelerIndex = n);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _startAnimation(List<LatLng> points) {
    _allPoints = points;
    _travelerIndex = 0;
    final durationMs = (points.length * 30).clamp(2000, 12000);
    _animController.duration = Duration(milliseconds: durationMs);
    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('HH:mm:ss');

    final pointsAsync = ref.watch(
      tripPointsProvider((userId: s.userId, tripId: s.tripId)),
    );

    // Duração formatada
    final dur = s.duration;
    final durStr = dur.inHours > 0
        ? '${dur.inHours}h ${dur.inMinutes.remainder(60)}min'
        : '${dur.inMinutes}min ${dur.inSeconds.remainder(60)}s';

    return Scaffold(
      appBar: AppBar(
        title: Text('Viagem — ${dateFmt.format(s.startDate)}'),
      ),
      body: Stack(
        children: [
          // ── Mapa ────────────────────────────────────────────────────
          pointsAsync.when(
            loading: () => FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(s.startLat, s.startLng),
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.amazon_track_data.app',
                ),
              ],
            ),
            error: (e, _) => Center(
              child: Text('Erro ao carregar pontos: $e'),
            ),
            data: (points) {
              if (points.isEmpty) {
                return const Center(
                    child: Text('Nenhum ponto GPS encontrado.'));
              }

              final latlngs =
                  points.map((p) => LatLng(p.latitude, p.longitude)).toList();

              // Dispara animação do marcador percorrendo a rota na primeira carga
              if (!_animationStarted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_animationStarted) {
                    setState(() => _animationStarted = true);
                    _startAnimation(latlngs);
                  }
                });
              }

              final bounds = LatLngBounds.fromPoints(latlngs);
              // Ponto atual do marcador animado (embarcação percorrendo a rota)
              final travelerPoint = _allPoints.isNotEmpty
                  ? _allPoints[_travelerIndex]
                  : latlngs.first;
              final animComplete = _allPoints.isNotEmpty &&
                  _travelerIndex >= _allPoints.length - 1;

              return FlutterMap(
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(48),
                  ),
                  maxZoom: 18,
                  minZoom: 3,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.amazon_track_data.app',
                  ),
                  // ── Rota completa: do ponto de partida por cada ponto
                  //    capturado até o ponto de chegada ──────────────────
                  if (latlngs.length >= 2)
                    PolylineLayer(
                      polylines: [
                        // Trecho já percorrido (azul sólido)
                        if (_animationStarted && _travelerIndex >= 1)
                          Polyline(
                            points: _allPoints.sublist(0, _travelerIndex + 1),
                            strokeWidth: 4,
                            color: Colors.blue,
                          ),
                        // Trecho restante (azul claro / tracejado)
                        if (_animationStarted &&
                            _travelerIndex < latlngs.length - 1)
                          Polyline(
                            points: _allPoints.sublist(_travelerIndex),
                            strokeWidth: 3,
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        // Antes da animação iniciar: exibe rota completa
                        if (!_animationStarted)
                          Polyline(
                            points: latlngs,
                            strokeWidth: 4,
                            color: Colors.blue,
                          ),
                      ],
                    ),
                  // Marcadores: início (verde), fim (vermelho) e embarcação animada
                  MarkerLayer(
                    markers: [
                      // Ponto de partida
                      Marker(
                        point: latlngs.first,
                        child: const _RouteMarker(
                          color: Colors.green,
                          icon: Icons.play_arrow,
                          label: 'Partida',
                        ),
                      ),
                      // Ponto de chegada (sempre visível)
                      Marker(
                        point: latlngs.last,
                        child: const _RouteMarker(
                          color: Colors.red,
                          icon: Icons.flag,
                          label: 'Chegada',
                        ),
                      ),
                      // Marcador animado da embarcação percorrendo a rota
                      if (_animationStarted && !animComplete)
                        Marker(
                          point: travelerPoint,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.directions_boat,
                              size: 16,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),

          // ── Painel de estatísticas (bottom) ─────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rota: partida → paradas → chegada
                        if (s.departurePoint.isNotEmpty ||
                            s.arrivalPoint.isNotEmpty) ...[
                          _RouteRow(summary: s),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                        ],
                        // Horário início → fim
                        Row(
                          children: [
                            _InfoChip(
                              color: Colors.green,
                              icon: Icons.play_arrow,
                              text: timeFmt.format(s.startDate),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.arrow_forward,
                                  size: 16, color: Colors.grey),
                            ),
                            _InfoChip(
                              color: Colors.red,
                              icon: Icons.flag,
                              text: timeFmt.format(s.endDate),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Grid de stats
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            _StatTile(
                              icon: Icons.timer,
                              label: 'Duração',
                              value: durStr,
                              color: Colors.blue,
                            ),
                            _StatTile(
                              icon: Icons.speed,
                              label: 'Vel. média',
                              value:
                                  '${s.avgSpeedKmh.toStringAsFixed(1)} km/h',
                              color: Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            _StatTile(
                              icon: Icons.straighten,
                              label: 'Distância',
                              value: s.totalDistanceKm >= 1
                                  ? '${s.totalDistanceKm.toStringAsFixed(2)} km'
                                  : '${s.totalDistanceMeters.toStringAsFixed(0)} m',
                              color: Colors.green,
                            ),
                            _StatTile(
                              icon: Icons.location_on,
                              label: 'Pontos GPS',
                              value: '${s.pointCount}',
                              color: Colors.purple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Loading overlay ─────────────────────────────────────────
          if (pointsAsync.isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final TripSummary summary;
  const _RouteRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Partida
        Row(
          children: [
            const Icon(Icons.play_arrow, color: Colors.green, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                summary.departurePoint.isNotEmpty
                    ? summary.departurePoint
                    : '—',
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        // Paradas
        ...summary.stops.map((stop) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.more_vert, color: Colors.grey, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(stop,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ),
                ],
              ),
            )),
        // Chegada
        if (summary.arrivalPoint.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.flag, color: Colors.red, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    summary.arrivalPoint,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RouteMarker extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _RouteMarker(
      {required this.color, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _InfoChip(
      {required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
