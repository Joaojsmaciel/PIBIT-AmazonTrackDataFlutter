import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amazon_track_data/data/models/user_model.dart';
import 'package:amazon_track_data/presentation/providers/auth_provider.dart';
import 'package:amazon_track_data/presentation/providers/service_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((isAuthenticated) {
        if (isAuthenticated) {
          Future.microtask(() async {
            final authRepo = ref.read(authRepositoryProvider);
            final user = await authRepo.getCurrentUser();
            if (!context.mounted) return;
            if (user?.userType == UserType.passageiro) {
              context.go('/passenger-home');
            } else {
              context.go('/map');
            }
          });
        } else {
          context.go('/login');
        }
      });
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                'Amazon Track Data',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 48),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
