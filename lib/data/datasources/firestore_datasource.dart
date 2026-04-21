import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:amazon_track_data/core/constants/firestore_paths.dart';
import 'package:amazon_track_data/core/errors/failures.dart';
import 'package:amazon_track_data/data/models/user_model.dart';
import 'package:amazon_track_data/data/models/boat_model.dart';
import 'package:amazon_track_data/data/models/route_model.dart';
import 'package:amazon_track_data/data/models/stop_model.dart';
import 'package:amazon_track_data/data/models/location_model.dart';

class FirestoreDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Usuários
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(FirestorePaths.usersCollection)
          .doc(user.uid)
          .set(user.toMap());
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
        message: e.message ?? 'Erro ao criar usuário',
        code: e.code,
      );
    } catch (e) {
      throw FirestoreFailure(
        message: 'Erro desconhecido ao criar usuário',
      );
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore
          .collection(FirestorePaths.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      
      // Se o documento não existe, tentar criar um documento padrão
      // Isso pode acontecer se o login foi feito sem complete o cadastro
      return null;
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
        message: e.message ?? 'Erro ao buscar usuário',
        code: e.code,
      );
    } catch (e) {
      throw FirestoreFailure(
        message: 'Erro desconhecido ao buscar usuário',
      );
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(FirestorePaths.usersCollection)
          .doc(user.uid)
          .update(user.toMap());
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
        message: e.message ?? 'Erro ao atualizar usuário',
        code: e.code,
      );
    } catch (e) {
      throw FirestoreFailure(
        message: 'Erro desconhecido ao atualizar usuário',
      );
    }
  }

  // Barcos
  Future<void> createBoat(BoatModel boat) async {
    try {
      await _firestore
          .collection(FirestorePaths.boatsCollection)
          .doc(boat.id)
          .set(boat.toMap());
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
        message: e.message ?? 'Erro ao criar barco',
        code: e.code,
      );
    } catch (e) {
      throw FirestoreFailure(
        message: 'Erro desconhecido ao criar barco',
      );
    }
  }

  Future<BoatModel?> getBoat(String boatId) async {
    try {
      final doc = await _firestore
          .collection(FirestorePaths.boatsCollection)
          .doc(boatId)
          .get();

      if (doc.exists) {
        return BoatModel.fromMap(doc.data()!);
      }
      return null;
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
        message: e.message ?? 'Erro ao buscar barco',
        code: e.code,
      );
    } catch (e) {
      throw FirestoreFailure(
        message: 'Erro desconhecido ao buscar barco',
      );
    }
  }

  Future<List<BoatModel>> getUserBoats(String userId) async {
    try {
      final query = await _firestore
          .collection(FirestorePaths.boatsCollection)
          .where('ownerId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return query.docs.map((doc) => BoatModel.fromMap(doc.data())).toList();
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
        message: e.message ?? 'Erro ao buscar barcos',
        code: e.code,
      );
    } catch (e) {
      throw FirestoreFailure(
        message: 'Erro desconhecido ao buscar barcos',
      );
    }
  }

  Future<void> updateBoat(BoatModel boat) async {
    try {
      await _firestore
          .collection(FirestorePaths.boatsCollection)
          .doc(boat.id)
          .update(boat.toMap());
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
        message: e.message ?? 'Erro ao atualizar barco',
        code: e.code,
      );
    } catch (e) {
      throw FirestoreFailure(
        message: 'Erro desconhecido ao atualizar barco',
      );
    }
  }

  Future<void> deleteBoat(String boatId) async {
    try {
      await _firestore
          .collection(FirestorePaths.boatsCollection)
          .doc(boatId)
          .update({'isActive': false});
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
        message: e.message ?? 'Erro ao deletar barco',
        code: e.code,
      );
    } catch (e) {
      throw FirestoreFailure(
        message: 'Erro desconhecido ao deletar barco',
      );
    }
  }

  Future<List<BoatModel>> getAllBoats() async {
    try {
      final query = await _firestore
          .collection(FirestorePaths.boatsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      return query.docs.map((doc) => BoatModel.fromMap(doc.data())).toList();
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
        message: e.message ?? 'Erro ao buscar embarcações',
        code: e.code,
      );
    } catch (e) {
      throw FirestoreFailure(
        message: 'Erro desconhecido ao buscar embarcações',
      );
    }
  }

  // Rotas
  Future<void> createRoute(RouteModel route) async {
    try {
      await _firestore
          .collection(FirestorePaths.routesCollection)
          .doc(route.id)
          .set(route.toMap());
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
        message: e.message ?? 'Erro ao criar rota',
        code: e.code,
      );
    } catch (e) {
      throw FirestoreFailure(
        message: 'Erro desconhecido ao criar rota',
      );
    }
  }

  Future<List<RouteModel>> getAllRoutes() async {
    try {
      final query = await _firestore
          .collection(FirestorePaths.routesCollection)
          .where('isActive', isEqualTo: true)
          .get();

      return query.docs.map((doc) => RouteModel.fromMap(doc.data())).toList();
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
        message: e.message ?? 'Erro ao buscar rotas',
        code: e.code,
      );
    } catch (e) {
      throw FirestoreFailure(
        message: 'Erro desconhecido ao buscar rotas',
      );
    }
  }

  // Paradas
  Future<List<StopModel>> getAllStops() async {
    try {
      final query = await _firestore
          .collection(FirestorePaths.stopsCollection)
          .get();

      return query.docs.map((doc) => StopModel.fromMap(doc.data())).toList();
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
        message: e.message ?? 'Erro ao buscar paradas',
        code: e.code,
      );
    } catch (e) {
      throw FirestoreFailure(
        message: 'Erro desconhecido ao buscar paradas',
      );
    }
  }

  // Localizações
  Future<void> saveLocation(LocationModel location) async {
    try {
      final path = FirestorePaths.locationTracksPath(location.userId);
      await _firestore.collection(path).doc(location.timestamp.toString()).set(
            location.toMap(),
            SetOptions(merge: true),
          );
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
        message: e.message ?? 'Erro ao salvar localização',
        code: e.code,
      );
    } catch (e) {
      throw FirestoreFailure(
        message: 'Erro desconhecido ao salvar localização',
      );
    }
  }

  Stream<List<LocationModel>> getRecentTrackedUsers(Duration windowDuration) {
    try {
      final cutoffTime = DateTime.now().millisecondsSinceEpoch - windowDuration.inMilliseconds;

      return _firestore.collectionGroup(FirestorePaths.tracksSubcollection)
          .where('timestamp', isGreaterThan: cutoffTime)
          .snapshots()
          .map((snapshot) {
        final locations = <LocationModel>[];
        for (var doc in snapshot.docs) {
          try {
            locations.add(LocationModel.fromMap(doc.data()));
          } catch (e) {
            // Ignora documentos malformados
          }
        }
        return locations;
      });
    } catch (e) {
      throw FirestoreFailure(
        message: 'Erro ao buscar usuários rastreados',
      );
    }
  }

  /// Retorna todos os pontos de uma trip específica de um usuário,
  /// ordenados por timestamp crescente.
  Future<List<LocationModel>> getUserTripPoints(String userId, String tripId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.locationTracksPath(userId))
          .where('tripId', isEqualTo: tripId)
          .get();
      final points = snapshot.docs
          .map((doc) => LocationModel.fromMap(doc.data()))
          .toList();
      points.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return points;
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
        message: e.message ?? 'Erro ao buscar pontos da viagem',
        code: e.code,
      );
    } catch (e) {
      throw FirestoreFailure(message: 'Erro desconhecido ao buscar pontos da viagem');
    }
  }

  /// Retorna todos os pontos de localização de um usuário,
  /// ordenados por timestamp crescente. Usado para montar o histórico de viagens.
  Future<List<LocationModel>> getAllUserLocations(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.locationTracksPath(userId))
          .orderBy('timestamp')
          .get();
      return snapshot.docs.map((doc) => LocationModel.fromMap(doc.data())).toList();
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
        message: e.message ?? 'Erro ao buscar histórico de localizações',
        code: e.code,
      );
    } catch (e) {
      throw FirestoreFailure(message: 'Erro desconhecido ao buscar histórico');
    }
  }

  /// Salva os metadados de uma viagem (partida, paradas, chegada).
  Future<void> saveTripMeta({
    required String tripId,
    required String userId,
    required String boatId,
    required String departurePoint,
    required String arrivalPoint,
    required List<String> stops,
  }) async {
    try {
      await _firestore
          .collection(FirestorePaths.tripMetaPath(userId))
          .doc(tripId)
          .set({
        'tripId': tripId,
        'userId': userId,
        'boatId': boatId,
        'departurePoint': departurePoint,
        'arrivalPoint': arrivalPoint,
        'stops': stops,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
        message: e.message ?? 'Erro ao salvar metadados da viagem',
        code: e.code,
      );
    } catch (e) {
      throw FirestoreFailure(message: 'Erro ao salvar metadados da viagem');
    }
  }

  /// Retorna todos os metadados de viagens de um usuário, indexados por tripId.
  Future<Map<String, Map<String, dynamic>>> getTripMetaForUser(
      String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.tripMetaPath(userId))
          .get();
      return {for (final doc in snapshot.docs) doc.id: doc.data()};
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
        message: e.message ?? 'Erro ao buscar metadados de viagens',
        code: e.code,
      );
    } catch (e) {
      throw FirestoreFailure(message: 'Erro ao buscar metadados de viagens');
    }
  }
}
