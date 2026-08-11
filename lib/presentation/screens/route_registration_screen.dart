import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:amazon_track_data/core/extensions/context_extensions.dart';
import 'package:amazon_track_data/data/models/route_model.dart';
import 'package:amazon_track_data/data/models/stop_model.dart';
import 'package:amazon_track_data/presentation/providers/auth_provider.dart';
import 'package:amazon_track_data/presentation/providers/route_provider.dart';

class RouteRegistrationScreen extends ConsumerStatefulWidget {
  const RouteRegistrationScreen({super.key});

  @override
  ConsumerState<RouteRegistrationScreen> createState() =>
      _RouteRegistrationScreenState();
}

class _RouteRegistrationScreenState
    extends ConsumerState<RouteRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _durationController = TextEditingController(text: '60');
  final _stopController = TextEditingController();
  final List<String> _stops = [];
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _durationController.dispose();
    _stopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar rota habitual')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.route, size: 72, color: Colors.blue),
              const SizedBox(height: 12),
              const Text(
                'Cadastre uma rota que você realiza com frequência. '
                'Ela ficará disponível ao iniciar uma viagem.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome da rota *',
                  hintText: 'Ex: Itacoatiara → Manaus',
                  prefixIcon: Icon(Icons.bookmark_outline),
                  border: OutlineInputBorder(),
                ),
                validator: _required('Informe o nome da rota'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _originController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Ponto de partida *',
                  prefixIcon: Icon(Icons.play_arrow, color: Colors.green),
                  border: OutlineInputBorder(),
                ),
                validator: _required('Informe o ponto de partida'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _destinationController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Ponto de chegada *',
                  prefixIcon: Icon(Icons.flag, color: Colors.red),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o ponto de chegada';
                  }
                  if (value.trim().toLowerCase() ==
                      _originController.text.trim().toLowerCase()) {
                    return 'Partida e chegada devem ser diferentes';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duração estimada (minutos) *',
                  prefixIcon: Icon(Icons.schedule),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final duration = int.tryParse(value ?? '');
                  return duration == null || duration <= 0
                      ? 'Informe uma duração válida'
                      : null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Paradas intermediárias',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _stopController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Ex: Comunidade São José',
                        prefixIcon: Icon(Icons.add_location_alt_outlined),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addStop(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addStop,
                    tooltip: 'Adicionar parada',
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              if (_stops.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _stops
                      .map(
                        (stop) => Chip(
                          label: Text(stop),
                          onDeleted: () =>
                              setState(() => _stops.remove(stop)),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Salvando…' : 'Salvar rota habitual'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  FormFieldValidator<String> _required(String message) {
    return (value) =>
        value == null || value.trim().isEmpty ? message : null;
  }

  void _addStop() {
    final stop = _stopController.text.trim();
    if (stop.isEmpty || _stops.contains(stop)) return;
    setState(() {
      _stops.add(stop);
      _stopController.clear();
    });
  }

  StopModel _buildStop(String name, StopType type) {
    return StopModel(
      id: const Uuid().v4(),
      name: name,
      city: name,
      latitude: 0,
      longitude: 0,
      radius: 500,
      type: type,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      context.showErrorSnackBar('Usuário não identificado.');
      return;
    }

    setState(() => _saving = true);
    try {
      final origin =
          _buildStop(_originController.text.trim(), StopType.porto);
      final destination =
          _buildStop(_destinationController.text.trim(), StopType.porto);
      final intermediateStops =
          _stops.map((stop) => _buildStop(stop, StopType.outro)).toList();

      final route = RouteModel(
        id: const Uuid().v4(),
        ownerId: userId,
        name: _nameController.text.trim(),
        origin: origin,
        destination: destination,
        stops: [origin, ...intermediateStops, destination],
        estimatedDurationMinutes: int.parse(_durationController.text),
        isFrequent: true,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await ref.read(createRouteProvider(route).future);
      if (mounted) {
        context.showSuccessSnackBar('Rota habitual cadastrada.');
        context.pop(true);
      }
    } catch (error) {
      if (mounted) {
        context.showErrorSnackBar('Erro ao cadastrar rota: $error');
        setState(() => _saving = false);
      }
    }
  }
}
