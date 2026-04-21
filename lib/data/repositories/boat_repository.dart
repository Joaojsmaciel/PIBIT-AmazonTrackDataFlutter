import 'dart:io';
import 'package:amazon_track_data/data/datasources/firestore_datasource.dart';
import 'package:amazon_track_data/data/datasources/firebase_storage_datasource.dart';
import 'package:amazon_track_data/data/models/boat_model.dart';

class BoatRepository {
  final FirestoreDatasource _firestoreDatasource;
  final FirebaseStorageDatasource _storageDatasource;

  BoatRepository({
    required FirestoreDatasource firestoreDatasource,
    required FirebaseStorageDatasource storageDatasource,
  })  : _firestoreDatasource = firestoreDatasource,
        _storageDatasource = storageDatasource;

  Future<void> createBoat(
    BoatModel boat, {
    File? imageFile,
  }) async {
    try {
      BoatModel boatToSave = boat;

      if (imageFile != null) {
        final imageUrl = await _storageDatasource.uploadBoatImage(
          imageFile: imageFile,
          boatId: boat.id,
        );
        boatToSave = boat.copyWith(photoUrl: imageUrl);
      }

      await _firestoreDatasource.createBoat(boatToSave);
    } catch (e) {
      rethrow;
    }
  }

  Future<BoatModel?> getBoat(String boatId) async {
    try {
      return await _firestoreDatasource.getBoat(boatId);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BoatModel>> getUserBoats(String userId) async {
    try {
      return await _firestoreDatasource.getUserBoats(userId);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BoatModel>> getAllBoats() async {
    try {
      return await _firestoreDatasource.getAllBoats();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBoat(
    BoatModel boat, {
    File? imageFile,
  }) async {
    try {
      BoatModel boatToSave = boat;

      if (imageFile != null) {
        final imageUrl = await _storageDatasource.uploadBoatImage(
          imageFile: imageFile,
          boatId: boat.id,
        );
        boatToSave = boat.copyWith(photoUrl: imageUrl);
      }

      await _firestoreDatasource.updateBoat(boatToSave);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBoat(String boatId) async {
    try {
      await _firestoreDatasource.deleteBoat(boatId);
      await _storageDatasource.deleteBoatImage(boatId);
    } catch (e) {
      rethrow;
    }
  }
}
