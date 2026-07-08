import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:amazon_track_data/core/services/geofence_service.dart';
import 'package:amazon_track_data/data/models/port_model.dart';
import 'package:amazon_track_data/data/models/tracked_user_model.dart';
import 'package:amazon_track_data/data/models/user_model.dart';
import 'package:amazon_track_data/config/theme.dart';

class MapWidget extends StatelessWidget {
  final MapController mapController;
  final LatLng center;
  final AsyncValue<List<TrackedUserModel>>? trackedUsers;
  final LatLng? userLocation;
  final UserType? currentUserType;

  /// Lista de portos a serem desenhados no mapa como zonas de geofence.
  final List<PortModel> ports;

  /// Evento de geofence mais recente — exibe painel de info quando preenchido.
  final GeofenceEvent? nearestPortEvent;

  /// Trilha GPS ponto a ponto da viagem em curso do próprio usuário (barqueiro).
  final List<LatLng> liveTrail;

  /// Trilha GPS ponto a ponto da embarcação sendo acompanhada (passageiro).
  final List<LatLng> boatTrail;

  const MapWidget({
    Key? key,
    required this.mapController,
    required this.center,
    this.trackedUsers,
    this.userLocation,
    this.currentUserType,
    this.ports = const [],
    this.nearestPortEvent,
    this.liveTrail = const [],
    this.boatTrail = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildMap(context),
        if (nearestPortEvent != null)
          Positioned(
            bottom: 16,
            left: 12,
            right: 12,
            child: _GeofenceInfoPanel(event: nearestPortEvent!),
          ),
      ],
    );
  }

  Widget _buildMap(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 13,
        maxZoom: 18,
        minZoom: 3,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.amazon_track_data.app',
        ),
        // --- Trilha ponto a ponto do barqueiro em viagem ---
        if (liveTrail.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: liveTrail,
                strokeWidth: 4.0,
                color: Colors.blue.withValues(alpha: 0.8),
              ),
            ],
          ),
        // --- Trilha ponto a ponto da embarcação acompanhada (passageiro) ---
        if (boatTrail.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: boatTrail,
                strokeWidth: 4.0,
                color: Colors.orange.withValues(alpha: 0.8),
              ),
            ],
          ),
        // --- Zonas de geofence dos portos ---
        if (ports.isNotEmpty) _buildGeofenceCircles(),
        // --- Labels dos portos ---
        if (ports.isNotEmpty) _buildPortLabels(),
        if (userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: userLocation!,
                child: Icon(
                  currentUserType == UserType.barqueiro
                      ? Icons.directions_boat
                      : Icons.location_on,
                  color: AppTheme.primaryColor,
                  size: 40,
                ),
              ),
            ],
          ),
        if (trackedUsers != null)
          trackedUsers!.when(
            data: (users) {
              return MarkerLayer(
                markers: users.map((user) {
                  Color markerColor = AppTheme.passengerColor;

                  if (user.userType == 'barqueiro') {
                    markerColor = AppTheme.boatmanColor;
                  }

                  return Marker(
                    point: LatLng(user.latitude, user.longitude),
                    child: GestureDetector(
                      onTap: () {
                        final speedKmh = (user.speed * 3.6).toStringAsFixed(1);
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            title: Row(
                              children: [
                                Icon(
                                  user.userType == 'barqueiro'
                                      ? Icons.directions_boat
                                      : Icons.location_on,
                                  color: markerColor,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    user.userName,
                                    style: const TextStyle(fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                _InfoRow(
                                  icon: Icons.speed,
                                  label: 'Velocidade',
                                  value: '$speedKmh km/h',
                                ),
                                const SizedBox(height: 6),
                                _InfoRow(
                                  icon: Icons.navigation,
                                  label: 'Em viagem',
                                  value: 'Sim',
                                  valueColor: Colors.green,
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Fechar'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Icon(
                        user.userType == 'barqueiro'
                            ? Icons.directions_boat
                            : Icons.location_on,
                        color: markerColor,
                        size: 35,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (err, stack) => const SizedBox.shrink(),
          ),
      ],
    );
  }

  /// Desenha os círculos de zona de aproximação (azul) e atracação (verde)
  /// para cada porto cadastrado.
  Widget _buildGeofenceCircles() {
    final circles = <CircleMarker>[];
    for (final porto in ports) {
      final point = LatLng(porto.latitude, porto.longitude);
      // Zona de aproximação — círculo externo
      circles.add(CircleMarker(
        point: point,
        radius: porto.raioAproximacao,
        useRadiusInMeter: true,
        color: Colors.blue.withAlpha(25),
        borderColor: Colors.blue.withAlpha(160),
        borderStrokeWidth: 1.5,
      ));
      // Zona de atracação — círculo interno
      circles.add(CircleMarker(
        point: point,
        radius: porto.raioAtracacao,
        useRadiusInMeter: true,
        color: Colors.green.withAlpha(50),
        borderColor: Colors.green.withAlpha(200),
        borderStrokeWidth: 2.0,
      ));
    }
    return CircleLayer(circles: circles);
  }

  /// Desenha um marcador com o nome de cada porto.
  Widget _buildPortLabels() {
    return MarkerLayer(
      markers: ports.map((porto) {
        return Marker(
          point: LatLng(porto.latitude, porto.longitude),
          width: 120,
          height: 36,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.anchor, color: Colors.blueGrey, size: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(220),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  porto.nome.replaceFirst('Porto de ', ''),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Painel exibido na parte inferior do mapa quando a embarcação está próxima
/// de um porto, mostrando distância e ETA.
class _GeofenceInfoPanel extends StatelessWidget {
  final GeofenceEvent event;
  const _GeofenceInfoPanel({required this.event});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    switch (event.status) {
      case GeofenceStatus.atracado:
        statusColor = Colors.green;
        statusIcon = Icons.anchor;
        break;
      case GeofenceStatus.aproximando:
        statusColor = Colors.orange;
        statusIcon = Icons.directions_boat;
        break;
      case GeofenceStatus.foraDaZona:
        statusColor = Colors.grey;
        statusIcon = Icons.location_off;
    }

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    event.porto.nome,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    event.status.label,
                    style: TextStyle(fontSize: 11, color: statusColor),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.distanciaFormatada,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  'ETA: ${event.etaFormatado}',
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
