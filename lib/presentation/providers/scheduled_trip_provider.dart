import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amazon_track_data/core/constants/firestore_paths.dart';
import 'package:amazon_track_data/data/models/scheduled_trip.dart';
import 'auth_provider.dart';

final _firestore = FirebaseFirestore.instance;

/// Todas as viagens agendadas futuras (para passageiros).
/// Filtra apenas por data no Firestore para evitar índice composto.
/// O filtro de cancelamento é feito no cliente.
final upcomingTripsProvider =
    FutureProvider<List<ScheduledTrip>>((ref) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  final snap = await _firestore
      .collection(FirestorePaths.scheduledTripsCollection)
      .where('departureDateMs', isGreaterThan: now)
      .orderBy('departureDateMs')
      .get();
  return snap.docs
      .map((d) => ScheduledTrip.fromMap(d.id, d.data()))
      .where((t) => !t.isCancelled)
      .toList();
});

/// Viagens agendadas do barqueiro atual.
/// Ordena no cliente para evitar índice composto (ownerId + departureDateMs).
final myScheduledTripsProvider =
    FutureProvider<List<ScheduledTrip>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final snap = await _firestore
      .collection(FirestorePaths.scheduledTripsCollection)
      .where('ownerId', isEqualTo: userId)
      .get();
  final trips = snap.docs
      .map((d) => ScheduledTrip.fromMap(d.id, d.data()))
      .toList();
  trips.sort((a, b) => a.departureDateMs.compareTo(b.departureDateMs));
  return trips;
});

/// Cria uma nova viagem agendada.
final createScheduledTripProvider =
    FutureProvider.family<void, ScheduledTrip>((ref, trip) async {
  final doc = _firestore
      .collection(FirestorePaths.scheduledTripsCollection)
      .doc();
  await doc.set(ScheduledTrip(
    id: doc.id,
    boatId: trip.boatId,
    boatName: trip.boatName,
    ownerId: trip.ownerId,
    ownerName: trip.ownerName,
    departurePoint: trip.departurePoint,
    arrivalPoint: trip.arrivalPoint,
    stops: trip.stops,
    departureDateMs: trip.departureDateMs,
    estimatedArrivalMs: trip.estimatedArrivalMs,
    availableSeats: trip.availableSeats,
    notes: trip.notes,
    createdAt: DateTime.now().millisecondsSinceEpoch,
  ).toMap());
  ref.invalidate(myScheduledTripsProvider);
  ref.invalidate(upcomingTripsProvider);
});

/// Cancela uma viagem agendada.
final cancelScheduledTripProvider =
    FutureProvider.family<void, String>((ref, tripId) async {
  await _firestore
      .collection(FirestorePaths.scheduledTripsCollection)
      .doc(tripId)
      .update({'isCancelled': true});
  ref.invalidate(myScheduledTripsProvider);
  ref.invalidate(upcomingTripsProvider);
});
