import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amazon_track_data/data/datasources/firebase_auth_datasource.dart';
import 'package:amazon_track_data/data/datasources/firestore_datasource.dart';
import 'package:amazon_track_data/data/datasources/firebase_storage_datasource.dart';
import 'package:amazon_track_data/data/datasources/geolocator_datasource.dart';
import 'package:amazon_track_data/data/datasources/local_database.dart';
import 'package:amazon_track_data/data/repositories/auth_repository.dart';
import 'package:amazon_track_data/data/repositories/user_repository.dart';
import 'package:amazon_track_data/data/repositories/boat_repository.dart';
import 'package:amazon_track_data/data/repositories/location_repository.dart';
import 'package:amazon_track_data/data/repositories/route_repository.dart';

// Datasources
final firebaseAuthDatasourceProvider = Provider((ref) => FirebaseAuthDatasource());
final firestoreDatasourceProvider = Provider((ref) => FirestoreDatasource());
final firebaseStorageDatasourceProvider = Provider((ref) => FirebaseStorageDatasource());
final geolocatorDatasourceProvider = Provider((ref) => GeolocatorDatasource());
final localDatabaseProvider = Provider((ref) => LocalDatabaseService());

// Repositories
final authRepositoryProvider = Provider((ref) {
  return AuthRepository(
    authDatasource: ref.watch(firebaseAuthDatasourceProvider),
    firestoreDatasource: ref.watch(firestoreDatasourceProvider),
  );
});

final userRepositoryProvider = Provider((ref) {
  return UserRepository(
    firestoreDatasource: ref.watch(firestoreDatasourceProvider),
  );
});

final boatRepositoryProvider = Provider((ref) {
  return BoatRepository(
    firestoreDatasource: ref.watch(firestoreDatasourceProvider),
    storageDatasource: ref.watch(firebaseStorageDatasourceProvider),
  );
});

final locationRepositoryProvider = Provider((ref) {
  return LocationRepository(
    firestoreDatasource: ref.watch(firestoreDatasourceProvider),
    geolocatorDatasource: ref.watch(geolocatorDatasourceProvider),
    localDatabaseService: ref.watch(localDatabaseProvider),
  );
});

final routeRepositoryProvider = Provider((ref) {
  return RouteRepository(
    firestoreDatasource: ref.watch(firestoreDatasourceProvider),
  );
});
