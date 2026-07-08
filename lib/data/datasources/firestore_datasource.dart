import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:amazon_track_data/core/constants/firestore_paths.dart';
import 'package:amazon_track_data/core/errors/failures.dart';
import 'package:amazon_track_data/data/models/user_model.dart';
import 'package:amazon_track_data/data/models/boat_model.dart';
import 'package:amazon_track_data/data/models/route_model.dart';
import 'package:amazon_track_data/data/models/stop_model.dart';
import 'package:amazon_track_data/data/models/location_model.dart';
import 'package:amazon_track_data/data/models/tracked_user_model.dart';
import 'package:amazon_track_data/data/models/chat_message.dart';
import 'package:amazon_track_data/data/models/chat_conversation.dart';

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
      debugPrint('[getUserBoats] Buscando barcos do userId: $userId');
      final query = await _firestore
          .collection(FirestorePaths.boatsCollection)
          .where('ownerId', isEqualTo: userId)
          .get();

      debugPrint('[getUserBoats] Documentos encontrados: ${query.docs.length}');
      for (final doc in query.docs) {
        debugPrint('[getUserBoats] Doc ${doc.id}: ownerId=${doc.data()['ownerId']}, isActive=${doc.data()['isActive']}');
      }

      return query.docs
          .map((doc) => BoatModel.fromMap(doc.data()))
          .where((b) => b.isActive)
          .toList();
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
          .get();

      return query.docs
          .map((doc) => BoatModel.fromMap(doc.data()))
          .where((b) => b.isActive)
          .toList();
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

  // ---------------------------------------------------------------------------
  // Live Positions — coleção plana sem índice composto
  // ---------------------------------------------------------------------------

  /// Grava/atualiza a posição ao vivo do barqueiro em rastreamento ativo.
  /// Chamado a cada ponto GPS coletado (foreground e background service).
  Future<void> updateLivePosition(LocationModel location) async {
    try {
      await _firestore
          .collection(FirestorePaths.livePositionsCollection)
          .doc(location.userId)
          .set({
        ...location.toMap(),
        'active': true,
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
        message: e.message ?? 'Erro ao atualizar posição ao vivo',
        code: e.code,
      );
    }
  }

  /// Marca a posição ao vivo do barqueiro como inativa (viagem encerrada).
  Future<void> setLivePositionInactive(String userId) async {
    try {
      await _firestore
          .collection(FirestorePaths.livePositionsCollection)
          .doc(userId)
          .set({'active': false}, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
        message: e.message ?? 'Erro ao desativar posição ao vivo',
        code: e.code,
      );
    }
  }

  /// Stream de todas as posições ao vivo ativas.
  /// Sem collectionGroup, sem índice composto — coleção plana.
  Stream<List<TrackedUserModel>> getLivePositionsStream() {
    return _firestore
        .collection(FirestorePaths.livePositionsCollection)
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TrackedUserModel.fromMap(doc.data()))
            .toList());
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

  /// Stream de pontos GPS de uma trip em tempo real (usado para trilha ao vivo).
  Stream<List<LocationModel>> getUserTripPointsStream(String userId, String tripId) {
    return _firestore
        .collection(FirestorePaths.locationTracksPath(userId))
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .map((snap) {
          final pts = snap.docs
              .map((doc) => LocationModel.fromMap(doc.data()))
              .toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return pts;
        });
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

  // ── Chat ──────────────────────────────────────────────────────────────────

  /// Stream de mensagens de um chat em tempo real, ordenadas por timestamp.
  Stream<List<ChatMessage>> watchChatMessages(String chatId) {
    return _firestore
        .collection(FirestorePaths.chatsCollection)
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatMessage.fromMap(d.data())).toList());
  }

  /// Envia uma mensagem para o chat e atualiza o metadata da conversa.
  Future<void> sendChatMessage(ChatMessage message) async {
    try {
      final batch = _firestore.batch();

      // Mensagem
      final msgRef = _firestore
          .collection(FirestorePaths.chatsCollection)
          .doc(message.chatId)
          .collection('messages')
          .doc(message.id);
      batch.set(msgRef, message.toMap());

      // Metadata da conversa (document pai) — permite inbox do barqueiro
      final parts = message.chatId.split('_');
      final chatRef = _firestore
          .collection(FirestorePaths.chatsCollection)
          .doc(message.chatId);
      batch.set(
        chatRef,
        {
          'participants': parts.length == 2 ? parts : [message.senderId],
          'participantNames': {message.senderId: message.senderName},
          'lastMessage': message.text,
          'lastSenderId': message.senderId,
          'lastSenderName': message.senderName,
          'lastTimestamp': message.timestamp,
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
        message: e.message ?? 'Erro ao enviar mensagem',
        code: e.code,
      );
    } catch (e) {
      throw FirestoreFailure(message: 'Erro ao enviar mensagem');
    }
  }

  /// Stream de todas as conversas em que [uid] é participante.
  /// Ordenadas pela última mensagem (mais recente primeiro).
  Stream<List<ChatConversation>> watchBarqueiroChatInbox(String uid) {
    return _firestore
        .collection(FirestorePaths.chatsCollection)
        .where('participants', arrayContains: uid)
        .orderBy('lastTimestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatConversation.fromMap(d.id, d.data()))
            .toList());
  }
}
