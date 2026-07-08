import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';

import 'firebase_options.dart';
import 'config/router_config.dart';
import 'config/theme.dart';
import 'core/services/background_tracking_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/offline_sync_service.dart';
import 'data/datasources/firestore_datasource.dart';
import 'data/datasources/local_database.dart';
import 'data/models/location_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Solicita permissão de notificações (obrigatório Android 13+ / API 33+).
  // Sem isso, NENHUMA notificação aparece, incluindo a notificação persistente
  // de rastreamento GPS e os alertas de porto.
  await Permission.notification.request();

  // Notificações locais (geofence + rastreamento persistente)
  await NotificationService().initialize();

  // Configura o ForegroundService de rastreamento em background
  // (deve ocorrer antes do runApp — apenas configura, não inicia o serviço)
  await BackgroundTrackingService.initialize();

  // Sincronização offline-first via SharedPreferences (fila de curto prazo)
  final firestoreDatasource = FirestoreDatasource();
  await OfflineSyncService().initialize(
    onSync: (point) async {
      try {
        await firestoreDatasource.saveLocation(LocationModel(
          userId: point.userId,
          tripId: point.tripId,
          boatId: point.boatId,
          latitude: point.latitude,
          longitude: point.longitude,
          speed: point.velocidade,
          accuracy: 0,
          timestamp: point.timestamp.millisecondsSinceEpoch,
          userType: '',
          userName: '',
        ));
        return true;
      } catch (_) {
        return false;
      }
    },
  );

  // Limpeza automática de pontos GPS locais com mais de 7 dias.
  // Só remove pontos já sincronizados, nunca dados pendentes.
  try {
    final localDb = LocalDatabaseService();
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    await localDb.deleteOlderThan(cutoff);
  } catch (e) {
    // Não interrompe a inicialização se a limpeza falhar
    debugPrint('[main] aviso: falha na limpeza de pontos antigos: $e');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Amazon Track Data',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
