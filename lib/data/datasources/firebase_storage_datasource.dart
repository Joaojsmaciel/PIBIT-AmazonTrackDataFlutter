import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:amazon_track_data/core/errors/failures.dart';

class FirebaseStorageDatasource {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadBoatImage({
    required File imageFile,
    required String boatId,
  }) async {
    try {
      final ref = _storage.ref().child('boat_images/$boatId.jpg');
      final uploadTask = ref.putFile(imageFile);
      
      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw StorageFailure(
        message: e.message ?? 'Erro ao fazer upload da imagem',
        code: e.code,
      );
    } catch (e) {
      throw StorageFailure(
        message: 'Erro desconhecido ao fazer upload da imagem',
      );
    }
  }

  Future<void> deleteBoatImage(String boatId) async {
    try {
      final ref = _storage.ref().child('boat_images/$boatId.jpg');
      await ref.delete();
    } on FirebaseException catch (e) {
      throw StorageFailure(
        message: e.message ?? 'Erro ao deletar imagem',
        code: e.code,
      );
    } catch (e) {
      throw StorageFailure(
        message: 'Erro desconhecido ao deletar imagem',
      );
    }
  }
}
