import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:amazon_track_data/data/models/boat_model.dart';
import 'package:amazon_track_data/data/models/scheduled_trip.dart';
import 'package:amazon_track_data/data/models/user_model.dart';
import 'package:amazon_track_data/presentation/providers/auth_provider.dart';
import 'package:amazon_track_data/presentation/providers/boat_provider.dart';
import 'package:amazon_track_data/presentation/providers/scheduled_trip_provider.dart';
import 'package:amazon_track_data/core/extensions/context_extensions.dart';

class TripCalendarScreen extends ConsumerStatefulWidget {
  final bool isBarqueiro;
  const TripCalendarScreen({super.key, required this.isBarqueiro});

  @override
  ConsumerState<TripCalendarScreen> createState() =>
      _TripCalendarScreenState();
}

class _TripCalendarScreenState extends ConsumerState<TripCalendarScreen> {
  String? _filterRoute;

  @override
  Widget build(BuildContext context) {
    if (widget.isBarqueiro) {
      return _BarqueiroCalendarView(this);
    }
    return _PassengerCalendarView(this);
  }
}

// ─── Vista Barqueiro ──────────────────────────────────────────────────────────

class _BarqueiroCalendarView extends ConsumerWidget {
  final _TripCalendarScreenState state;
  const _BarqueiroCalendarView(this.state);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(myScheduledTripsProvider);
    final boatsAsync = ref.watch(userBoatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Viagens Agendadas')),
      body: tripsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (trips) {
          if (trips.isEmpty) {
            return _EmptyCalendar(
              message: 'Nenhuma viagem agendada.',
              subtitle: 'Toque em + para cadastrar uma nova viagem.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myScheduledTripsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: trips.length,
              itemBuilder: (context, i) =>
                  _ScheduledTripCard(trip: trips[i], showCancel: true, ref: ref),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => boatsAsync.whenData((boats) {
          if (boats.isEmpty) {
            context.showErrorSnackBar(
                'Cadastre uma embarcação antes de agendar viagens.');
            return;
          }
          _showAddTripDialog(context, ref, boats);
        }),
        icon: const Icon(Icons.add),
        label: const Text('Nova Viagem'),
      ),
    );
  }

  void _showAddTripDialog(
      BuildContext context, WidgetRef ref, List<BoatModel> boats) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddTripForm(boats: boats),
    );
  }
}

// ─── Vista Passageiro ─────────────────────────────────────────────────────────

class _PassengerCalendarView extends ConsumerWidget {
  final _TripCalendarScreenState state;
  const _PassengerCalendarView(this.state);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(upcomingTripsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Próximas Viagens'),
        actions: [
          if (state._filterRoute != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Limpar filtro',
              onPressed: () => state.setState(() => state._filterRoute = null),
            ),
        ],
      ),
      body: Column(
        children: [
          tripsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (trips) {
              final routes = _extractRoutes(trips);
              if (routes.isEmpty) return const SizedBox.shrink();
              return _RouteFilterChips(
                routes: routes,
                selected: state._filterRoute,
                onSelected: (r) =>
                    state.setState(() => state._filterRoute = r),
              );
            },
          ),
          Expanded(
            child: tripsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (trips) {
                final filtered = state._filterRoute == null
                    ? trips
                    : trips
                        .where((t) =>
                            '${t.departurePoint} → ${t.arrivalPoint}' ==
                            state._filterRoute)
                        .toList();

                if (filtered.isEmpty) {
                  return _EmptyCalendar(
                    message: 'Nenhuma viagem disponível.',
                    subtitle: state._filterRoute != null
                        ? 'Tente remover o filtro de rota.'
                        : 'Verifique mais tarde.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(upcomingTripsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _ScheduledTripCard(
                        trip: filtered[i], showCancel: false, ref: ref),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<String> _extractRoutes(List<ScheduledTrip> trips) {
    final set = <String>{};
    for (final t in trips) {
      if (t.departurePoint.isNotEmpty && t.arrivalPoint.isNotEmpty) {
        set.add('${t.departurePoint} → ${t.arrivalPoint}');
      }
    }
    return set.toList();
  }
}

// ─── Filtro por rota ──────────────────────────────────────────────────────────

class _RouteFilterChips extends StatelessWidget {
  final List<String> routes;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _RouteFilterChips({
    required this.routes,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: routes
            .map((r) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(r, style: const TextStyle(fontSize: 12)),
                    selected: selected == r,
                    onSelected: (v) => onSelected(v ? r : null),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ─── Card de viagem agendada ──────────────────────────────────────────────────

class _ScheduledTripCard extends StatelessWidget {
  final ScheduledTrip trip;
  final bool showCancel;
  final WidgetRef ref;

  const _ScheduledTripCard({
    required this.trip,
    required this.showCancel,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy – HH:mm');
    final isPast = trip.departureDateMs <
        DateTime.now().millisecondsSinceEpoch;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event,
                  color: trip.isCancelled
                      ? Colors.red
                      : isPast
                          ? Colors.grey
                          : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateFmt.format(trip.departureDate),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                _TripStatusChip(trip: trip, isPast: isPast),
              ],
            ),
            const SizedBox(height: 10),
            _RouteRow(trip: trip),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.directions_boat,
                    size: 15, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(trip.boatName,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade700)),
                const SizedBox(width: 14),
                Icon(Icons.person,
                    size: 15, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(trip.ownerName,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade700)),
              ],
            ),
            if (trip.availableSeats != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.people,
                      size: 15, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text('${trip.availableSeats} vagas disponíveis',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade700)),
                ],
              ),
            ],
            if (trip.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                trip.notes,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic),
              ),
            ],
            if (showCancel && !trip.isCancelled && !isPast) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Cancelar Viagem'),
                        content: const Text(
                            'Deseja cancelar esta viagem agendada?'),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, false),
                              child: const Text('Não')),
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, true),
                              child: const Text('Cancelar',
                                  style:
                                      TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(
                          cancelScheduledTripProvider(trip.id).future);
                    }
                  },
                  icon: const Icon(Icons.cancel_outlined,
                      size: 16, color: Colors.red),
                  label: const Text('Cancelar',
                      style: TextStyle(color: Colors.red)),
                  style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TripStatusChip extends StatelessWidget {
  final ScheduledTrip trip;
  final bool isPast;
  const _TripStatusChip({required this.trip, required this.isPast});

  @override
  Widget build(BuildContext context) {
    final (label, color) = trip.isCancelled
        ? ('Cancelada', Colors.red)
        : isPast
            ? ('Realizada', Colors.grey)
            : ('Agendada', Colors.blue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final ScheduledTrip trip;
  const _RouteRow({required this.trip});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (trip.departurePoint.isNotEmpty) trip.departurePoint,
      ...trip.stops,
      if (trip.arrivalPoint.isNotEmpty) trip.arrivalPoint,
    ];
    if (parts.isEmpty) return const SizedBox.shrink();

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        for (int i = 0; i < parts.length; i++) ...[
          Text(parts[i],
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          if (i < parts.length - 1)
            Icon(Icons.arrow_forward,
                size: 14, color: Colors.grey.shade500),
        ],
      ],
    );
  }
}

// ─── Estado vazio ─────────────────────────────────────────────────────────────

class _EmptyCalendar extends StatelessWidget {
  final String message;
  final String subtitle;
  const _EmptyCalendar(
      {required this.message, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ─── Formulário: adicionar viagem ─────────────────────────────────────────────

class _AddTripForm extends ConsumerStatefulWidget {
  final List<BoatModel> boats;

  const _AddTripForm({required this.boats});

  @override
  ConsumerState<_AddTripForm> createState() => _AddTripFormState();
}

class _AddTripFormState extends ConsumerState<_AddTripForm> {
  final _formKey = GlobalKey<FormState>();
  BoatModel? _selectedBoat;
  final _departureCtrl = TextEditingController();
  final _arrivalCtrl = TextEditingController();
  final _stopsCtrl = TextEditingController();
  final _seatsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _departureDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.boats.isNotEmpty) _selectedBoat = widget.boats.first;
  }

  @override
  void dispose() {
    _departureCtrl.dispose();
    _arrivalCtrl.dispose();
    _stopsCtrl.dispose();
    _seatsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted) return;
    setState(() {
      _departureDate = time == null
          ? picked
          : DateTime(
              picked.year, picked.month, picked.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_departureDate == null) {
      context.showErrorSnackBar('Selecione data e horário de partida.');
      return;
    }
    if (_selectedBoat == null) {
      context.showErrorSnackBar('Selecione uma embarcação.');
      return;
    }

    setState(() => _saving = true);
    try {
      // Tenta cache primeiro; aguarda Firestore se necessário
      var currentUser = ref.read(userSessionProvider);
      currentUser ??= await ref.read(currentUserProvider.future);

      if (currentUser == null) {
        context.showErrorSnackBar('Usuário não autenticado. Faça login novamente.');
        return;
      }

      final stops = _stopsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await ref.read(createScheduledTripProvider(ScheduledTrip(
        id: '',
        boatId: _selectedBoat!.id,
        boatName: _selectedBoat!.name,
        ownerId: currentUser.uid,
        ownerName: currentUser.fullName,
        departurePoint: _departureCtrl.text.trim(),
        arrivalPoint: _arrivalCtrl.text.trim(),
        stops: stops,
        departureDateMs: _departureDate!.millisecondsSinceEpoch,
        availableSeats: int.tryParse(_seatsCtrl.text.trim()),
        notes: _notesCtrl.text.trim(),
        createdAt: 0,
      )).future);

      if (mounted) {
        Navigator.pop(context);
        context.showSuccessSnackBar('Viagem agendada com sucesso!');
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Erro ao agendar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy – HH:mm');

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nova Viagem Agendada',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<BoatModel>(
                value: _selectedBoat,
                decoration:
                    const InputDecoration(labelText: 'Embarcação'),
                items: widget.boats
                    .map((b) => DropdownMenuItem(
                        value: b, child: Text(b.name)))
                    .toList(),
                onChanged: (b) =>
                    setState(() => _selectedBoat = b),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _departureCtrl,
                decoration:
                    const InputDecoration(labelText: 'Ponto de Partida'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _arrivalCtrl,
                decoration:
                    const InputDecoration(labelText: 'Destino Final'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stopsCtrl,
                decoration: const InputDecoration(
                    labelText: 'Paradas intermediárias',
                    hintText: 'Ex: Parintins, Barreirinha (separadas por vírgula)'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  _departureDate == null
                      ? 'Selecionar data e horário'
                      : dateFmt.format(_departureDate!),
                ),
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _seatsCtrl,
                decoration:
                    const InputDecoration(labelText: 'Vagas disponíveis'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                    labelText: 'Observações (opcional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14)),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white))
                      : const Text('Agendar Viagem'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
