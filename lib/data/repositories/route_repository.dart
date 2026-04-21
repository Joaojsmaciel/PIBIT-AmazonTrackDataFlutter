import 'package:amazon_track_data/data/datasources/firestore_datasource.dart';
import 'package:amazon_track_data/data/models/route_model.dart';
import 'package:amazon_track_data/data/models/stop_model.dart';

class RouteRepository {
  final FirestoreDatasource _firestoreDatasource;

  RouteRepository({
    required FirestoreDatasource firestoreDatasource,
  }) : _firestoreDatasource = firestoreDatasource;

  Future<void> createRoute(RouteModel route) async {
    try {
      await _firestoreDatasource.createRoute(route);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<RouteModel>> getAllRoutes() async {
    try {
      return await _firestoreDatasource.getAllRoutes();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<StopModel>> getAllStops() async {
    try {
      return await _firestoreDatasource.getAllStops();
    } catch (e) {
      rethrow;
    }
  }
}
