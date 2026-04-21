import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amazon_track_data/data/models/route_model.dart';
import 'package:amazon_track_data/data/models/stop_model.dart';
import 'service_provider.dart';

final allRoutesProvider = FutureProvider<List<RouteModel>>((ref) async {
  final routeRepo = ref.watch(routeRepositoryProvider);
  return await routeRepo.getAllRoutes();
});

// Alias para compatibilidade
final routesProvider = allRoutesProvider;

final allStopsProvider = FutureProvider<List<StopModel>>((ref) async {
  final routeRepo = ref.watch(routeRepositoryProvider);
  return await routeRepo.getAllStops();
});

final createRouteProvider = FutureProvider.family<void, RouteModel>((ref, route) async {
  final routeRepo = ref.watch(routeRepositoryProvider);
  await routeRepo.createRoute(route);
  ref.invalidate(allRoutesProvider);
});

final selectedRouteProvider = StateProvider<RouteModel?>((ref) => null);

final customRouteProvider = StateProvider<RouteModel?>((ref) => null);
