import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amazon_track_data/data/models/boat_model.dart';
import 'package:amazon_track_data/data/models/route_model.dart';
import 'package:amazon_track_data/data/models/trip_start_params.dart';
import 'package:amazon_track_data/presentation/providers/boat_provider.dart';
import 'package:amazon_track_data/presentation/providers/location_provider.dart';
import 'package:amazon_track_data/presentation/providers/route_provider.dart';
import 'package:amazon_track_data/core/extensions/context_extensions.dart';

class BoatSelectionDialog extends ConsumerStatefulWidget {
  const BoatSelectionDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<BoatSelectionDialog> createState() =>
      _BoatSelectionDialogState();
}

class _BoatSelectionDialogState extends ConsumerState<BoatSelectionDialog> {
  int _step = 0;
  BoatModel? _selectedBoat;
  RouteModel? _selectedRoute;
  bool _useSavedRoute = true;
  final _departureCtrl = TextEditingController();
  final _arrivalCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '60');
  final _stopCtrl = TextEditingController();
  final _stops = <String>[];
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _departureCtrl.dispose();
    _arrivalCtrl.dispose();
    _durationCtrl.dispose();
    _stopCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: _step == 0 ? _buildBoatStep() : _buildRouteStep(),
      ),
    );
  }

  // ── Passo 1: selecionar embarcação ──────────────────────────────────
  Widget _buildBoatStep() {
    final userBoatsAsync = ref.watch(userBoatsProvider);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Passo 1 de 2',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          const Text('Selecione a embarcação',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          userBoatsAsync.when(
            data: (boats) {
              if (boats.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Nenhuma embarcação cadastrada.'),
                );
              }
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: boats.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final boat = boats[i];
                    return ListTile(
                      leading: const Icon(Icons.directions_boat),
                      title: Text(boat.name),
                      subtitle: Text(boat.type),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => setState(() {
                        _selectedBoat = boat;
                        _step = 1;
                      }),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
                height: 80, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('Erro: $e'),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Passo 2: detalhes da rota ────────────────────────────────────────
  Widget _buildRouteStep() {
    final routesAsync = ref.watch(allRoutesProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com botão voltar
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _step = 0),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Passo 2 de 2',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        _selectedBoat?.name ?? '',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Rota habitual'),
                  avatar: const Icon(Icons.bookmark_outline, size: 18),
                  selected: _useSavedRoute,
                  onSelected: (_) => setState(() => _useSavedRoute = true),
                ),
                ChoiceChip(
                  label: const Text('Rota personalizada'),
                  avatar: const Icon(Icons.edit_road, size: 18),
                  selected: !_useSavedRoute,
                  onSelected: (_) => setState(() {
                    _useSavedRoute = false;
                    _selectedRoute = null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_useSavedRoute)
              routesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Erro ao carregar rotas: $error'),
                    TextButton(
                      onPressed: () => ref.invalidate(allRoutesProvider),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
                data: (routes) {
                  if (routes.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nenhuma rota habitual cadastrada. Use uma rota '
                          'personalizada ou cadastre pelo botão + em '
                          'Embarcações.',
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              setState(() => _useSavedRoute = false),
                          icon: const Icon(Icons.edit_road),
                          label: const Text('Criar rota personalizada'),
                        ),
                      ],
                    );
                  }

                  final sorted = [...routes]
                    ..sort((a, b) {
                      if (a.isFrequent == b.isFrequent) {
                        return a.name.compareTo(b.name);
                      }
                      return a.isFrequent ? -1 : 1;
                    });

                  return DropdownButtonFormField<RouteModel>(
                    value: _selectedRoute,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Escolha a rota *',
                      prefixIcon: Icon(Icons.route),
                      border: OutlineInputBorder(),
                    ),
                    items: sorted
                        .map(
                          (route) => DropdownMenuItem(
                            value: route,
                            child: Text(
                              '${route.isFrequent ? '★ ' : ''}'
                              '${route.name}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (route) =>
                        setState(() => _selectedRoute = route),
                    validator: (route) =>
                        route == null ? 'Selecione uma rota' : null,
                  );
                },
              ),

            if (!_useSavedRoute) ...[
              TextFormField(
                controller: _departureCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ponto de partida *',
                  prefixIcon: Icon(Icons.play_arrow, color: Colors.green),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe o ponto de partida'
                    : null,
              ),
              const SizedBox(height: 8),
              if (_stops.isNotEmpty) ...[
                const Text('Paradas:',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _stops.asMap().entries.map((e) {
                    return Chip(
                      label: Text(e.value,
                          style: const TextStyle(fontSize: 12)),
                      onDeleted: () => setState(() => _stops.removeAt(e.key)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: _showAddStopDialog,
                icon: const Icon(Icons.add_location_alt, size: 18),
                label: const Text('Adicionar parada'),
                style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _arrivalCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ponto de chegada *',
                  prefixIcon: Icon(Icons.flag, color: Colors.red),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe o ponto de chegada'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationCtrl,
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
            ],
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startTracking,
                icon: const Icon(Icons.navigation),
                label: const Text('Iniciar rastreamento'),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStopDialog() {
    _stopCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar parada'),
        content: TextField(
          controller: _stopCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Nome da parada',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _confirmAddStop(ctx),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => _confirmAddStop(ctx),
              child: const Text('Adicionar')),
        ],
      ),
    );
  }

  void _confirmAddStop(BuildContext ctx) {
    final txt = _stopCtrl.text.trim();
    if (txt.isNotEmpty) setState(() => _stops.add(txt));
    Navigator.pop(ctx);
  }

  void _startTracking() {
    if (!_formKey.currentState!.validate()) return;
    final boat = _selectedBoat!;
    final route = _useSavedRoute ? _selectedRoute : null;
    final routeStops = route == null
        ? List<String>.from(_stops)
        : route.stops
            .where((stop) =>
                stop.id != route.origin.id &&
                stop.id != route.destination.id)
            .map((stop) => _stopLabel(stop.name, stop.city))
            .where((name) => name.isNotEmpty)
            .toList();
    Navigator.pop(context);

    final params = TripStartParams(
      boatId: boat.id,
      departurePoint: route == null
          ? _departureCtrl.text.trim()
          : _stopLabel(route.origin.name, route.origin.city),
      arrivalPoint: route == null
          ? _arrivalCtrl.text.trim()
          : _stopLabel(route.destination.name, route.destination.city),
      stops: routeStops,
      estimatedDurationMinutes: route == null
          ? int.parse(_durationCtrl.text)
          : route.estimatedDurationMinutes,
      originLatitude:
          route == null || !_hasCoordinates(route.origin.latitude, route.origin.longitude)
              ? null
              : route.origin.latitude,
      originLongitude:
          route == null || !_hasCoordinates(route.origin.latitude, route.origin.longitude)
              ? null
              : route.origin.longitude,
      destinationLatitude: route == null ||
              !_hasCoordinates(
                  route.destination.latitude, route.destination.longitude)
          ? null
          : route.destination.latitude,
      destinationLongitude: route == null ||
              !_hasCoordinates(
                  route.destination.latitude, route.destination.longitude)
          ? null
          : route.destination.longitude,
    );

    ref.invalidate(startTrackingProvider(params));

    try {
      ref.read(startTrackingProvider(params).future).then((_) {
        if (context.mounted) {
          context.showSuccessSnackBar(
              'Rastreamento iniciado: ${params.departurePoint} → ${params.arrivalPoint}');
        }
      }).catchError((error) {
        if (context.mounted) {
          context.showErrorSnackBar('Erro ao iniciar rastreamento: $error');
        }
      });
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar('Erro ao iniciar rastreamento: $e');
      }
    }
  }

  String _stopLabel(String name, String city) {
    return name.trim().isNotEmpty ? name.trim() : city.trim();
  }

  bool _hasCoordinates(double latitude, double longitude) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        (latitude != 0 || longitude != 0);
  }
}
