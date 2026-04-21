import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amazon_track_data/presentation/providers/location_provider.dart';

class TrackingButtonWidget extends ConsumerWidget {
  final VoidCallback onStartTracking;
  final VoidCallback onStopTracking;

  const TrackingButtonWidget({
    Key? key,
    required this.onStartTracking,
    required this.onStopTracking,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTracking = ref.watch(isTrackingProvider);

    return FloatingActionButton.extended(
      onPressed: isTracking ? onStopTracking : onStartTracking,
      backgroundColor: isTracking ? Colors.red : Colors.green,
      icon: Icon(isTracking ? Icons.stop : Icons.play_arrow),
      label: Text(
        isTracking ? 'Parar Rastreamento' : 'Iniciar Rastreamento',
      ),
    );
  }
}
