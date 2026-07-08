import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amazon_track_data/data/models/user_model.dart';
import 'auth_provider.dart';
import 'service_provider.dart';

final userProvider = FutureProvider<UserModel?>((ref) async {
  final userRepo = ref.watch(userRepositoryProvider);
  // Usa currentUserIdProvider definido em auth_provider.dart (fonte única)
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return null;
  return await userRepo.getUser(userId);
});

final updateUserProvider =
    FutureProvider.family<void, UserModel>((ref, user) async {
  final userRepo = ref.watch(userRepositoryProvider);
  return await userRepo.updateUser(user);
});
