import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amazon_track_data/data/models/trip_summary.dart';
import 'package:amazon_track_data/data/models/location_model.dart';
import 'service_provider.dart';

/// Carrega o histórico de viagens de um userId.
final userTripsProvider =
    FutureProvider.family<List<TripSummary>, String>((ref, userId) async {
  final locationRepo = ref.read(locationRepositoryProvider);
  return await locationRepo.getUserTrips(userId);
});

/// Carrega os pontos GPS de uma trip específica.
final tripPointsProvider = FutureProvider.family<
    List<LocationModel>,
    ({String userId, String tripId})>((ref, params) async {
  final locationRepo = ref.read(locationRepositoryProvider);
  return await locationRepo.getTripPoints(params.userId, params.tripId);
});
