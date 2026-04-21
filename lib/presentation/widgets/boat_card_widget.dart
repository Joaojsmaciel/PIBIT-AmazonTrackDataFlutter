import 'package:flutter/material.dart';
import 'package:amazon_track_data/data/models/boat_model.dart';

class BoatCardWidget extends StatelessWidget {
  final BoatModel boat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BoatCardWidget({
    Key? key,
    required this.boat,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (boat.photoUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                boat.photoUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  boat.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tipo: ${boat.type}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (boat.capacity != null)
                  Text(
                    'Capacidade: ${boat.capacity} pessoas',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
                    ),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete),
                      label: const Text('Deletar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
