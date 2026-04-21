import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:amazon_track_data/data/models/route_model.dart';
import 'package:amazon_track_data/data/models/stop_model.dart';

class CustomRouteDialog extends StatefulWidget {
  final Function(RouteModel) onRouteCreated;
  final List<StopModel> availableStops;

  const CustomRouteDialog({
    Key? key,
    required this.onRouteCreated,
    required this.availableStops,
  }) : super(key: key);

  @override
  State<CustomRouteDialog> createState() => _CustomRouteDialogState();
}

class _CustomRouteDialogState extends State<CustomRouteDialog> {
  late TextEditingController routeNameController;
  StopModel? originStop;
  StopModel? destinationStop;
  late TextEditingController durationController;

  @override
  void initState() {
    super.initState();
    routeNameController = TextEditingController();
    durationController = TextEditingController(text: '60');
  }

  @override
  void dispose() {
    routeNameController.dispose();
    durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Criar Rota Customizada'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: routeNameController,
              decoration: const InputDecoration(
                hintText: 'Nome da Rota',
                prefixIcon: Icon(Icons.directions),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButton<StopModel>(
              value: originStop,
              isExpanded: true,
              hint: const Text('Origem'),
              items: widget.availableStops.map((stop) {
                return DropdownMenuItem(
                  value: stop,
                  child: Text(stop.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => originStop = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButton<StopModel>(
              value: destinationStop,
              isExpanded: true,
              hint: const Text('Destino'),
              items: widget.availableStops.map((stop) {
                return DropdownMenuItem(
                  value: stop,
                  child: Text(stop.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => destinationStop = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: durationController,
              decoration: const InputDecoration(
                hintText: 'Duração estimada (minutos)',
                prefixIcon: Icon(Icons.schedule),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: originStop != null && destinationStop != null
              ? () {
                  final route = RouteModel(
                    id: const Uuid().v4(),
                    name: routeNameController.text,
                    origin: originStop!,
                    destination: destinationStop!,
                    stops: [originStop!, destinationStop!],
                    estimatedDurationMinutes: int.tryParse(durationController.text) ?? 60,
                    isFrequent: false,
                    createdAt: DateTime.now().millisecondsSinceEpoch,
                  );
                  widget.onRouteCreated(route);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Criar Rota'),
        ),
      ],
    );
  }
}
