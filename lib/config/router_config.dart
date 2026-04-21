import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:amazon_track_data/presentation/screens/splash_screen.dart';
import 'package:amazon_track_data/presentation/screens/login_screen.dart';
import 'package:amazon_track_data/presentation/screens/signup_screen.dart';
import 'package:amazon_track_data/presentation/screens/map_screen.dart';
import 'package:amazon_track_data/presentation/screens/boat_registration_screen.dart';
import 'package:amazon_track_data/presentation/screens/boat_list_screen.dart';
import 'package:amazon_track_data/presentation/screens/route_selection_screen.dart';
import 'package:amazon_track_data/presentation/screens/trip_detail_screen.dart';
import 'package:amazon_track_data/presentation/screens/profile_screen.dart';
import 'package:amazon_track_data/presentation/screens/passenger_home_screen.dart';
import 'package:amazon_track_data/data/models/trip_summary.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: '/boat-registration',
        builder: (context, state) => const BoatRegistrationScreen(),
      ),
      GoRoute(
        path: '/boat-list',
        builder: (context, state) => const BoatListScreen(),
      ),
      GoRoute(
        path: '/route-selection',
        builder: (context, state) => const RouteSelectionScreen(),
      ),
      GoRoute(
        path: '/routes',
        builder: (context, state) => const RouteSelectionScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/trip-detail',
        builder: (context, state) {
          final summary = state.extra as TripSummary;
          return TripDetailScreen(summary: summary);
        },
      ),
      GoRoute(
        path: '/passenger-home',
        builder: (context, state) => const PassengerHomeScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Erro')),
      body: Center(
        child: Text('Rota não encontrada: ${state.uri}'),
      ),
    ),
  );
}
