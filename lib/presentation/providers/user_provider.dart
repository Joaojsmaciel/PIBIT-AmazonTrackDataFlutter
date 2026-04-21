import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amazon_track_data/data/models/user_model.dart';
import 'service_provider.dart';

final userProvider = FutureProvider<UserModel?>((ref) async {
  final userRepo = ref.watch(userRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  
  if (userId == null) return null;
  return await userRepo.getUser(userId);
});

final updateUserProvider = FutureProvider.family<void, UserModel>((ref, user) async {
  final userRepo = ref.watch(userRepositoryProvider);
  return await userRepo.updateUser(user);
});


final currentUserIdProvider = Provider<String?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getCurrentUserId();
});
