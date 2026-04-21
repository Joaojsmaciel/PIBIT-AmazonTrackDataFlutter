import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

final mapCenterProvider = StateProvider<LatLng>((ref) {
  return const LatLng(-3.1190, -60.0217); // Manaus como centro padrão
});

final mapZoomProvider = StateProvider<double>((ref) => 13.0);

final isMapLoadingProvider = StateProvider<bool>((ref) => false);

final showUserLocationCenterFabProvider = StateProvider<bool>((ref) => false);
