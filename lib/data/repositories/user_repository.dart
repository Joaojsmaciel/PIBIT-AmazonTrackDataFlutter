import 'package:amazon_track_data/data/datasources/firestore_datasource.dart';
import 'package:amazon_track_data/data/models/user_model.dart';

class UserRepository {
  final FirestoreDatasource _firestoreDatasource;

  UserRepository({
    required FirestoreDatasource firestoreDatasource,
  }) : _firestoreDatasource = firestoreDatasource;

  Future<UserModel?> getUser(String uid) async {
    try {
      return await _firestoreDatasource.getUser(uid);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestoreDatasource.updateUser(user);
    } catch (e) {
      rethrow;
    }
  }
}
