import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:amazon_track_data/data/models/tracked_user_model.dart';
import 'package:amazon_track_data/data/models/user_model.dart';
import 'package:amazon_track_data/config/theme.dart';

class MapWidget extends StatelessWidget {
  final MapController mapController;
  final LatLng center;
  final AsyncValue<List<TrackedUserModel>>? trackedUsers;
  final LatLng? userLocation;
  final UserType? currentUserType;

  const MapWidget({
    Key? key,
    required this.mapController,
    required this.center,
    this.trackedUsers,
    this.userLocation,
    this.currentUserType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  if (user.userType == 'mototaxi') {
                    markerColor = AppTheme.mototaxiColor;
                  } else if (user.userType == 'barqueiro') {
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
