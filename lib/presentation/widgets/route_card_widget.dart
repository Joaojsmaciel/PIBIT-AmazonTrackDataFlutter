import 'package:flutter/material.dart';
import 'package:amazon_track_data/data/models/route_model.dart';

class RouteCardWidget extends StatelessWidget {
  final RouteModel route;
  final VoidCallback onSelect;
  final bool isSelected;

  const RouteCardWidget({
    Key? key,
    required this.route,
    required this.onSelect,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    route.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${route.origin.name} → ${route.destination.name}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Duração aproximada: ${route.estimatedDurationMinutes} min',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (route.isFrequent)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Chip(
                    label: const Text('Rota Frequente'),
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
