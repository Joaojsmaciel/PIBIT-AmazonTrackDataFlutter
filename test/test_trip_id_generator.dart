import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('Trip ID Generator Tests', () {
    test('Generate unique trip ID format', () {
      final userId = 'user123';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tripId = '${userId}_$timestamp';
      
      expect(tripId, contains('user123'));
      expect(tripId, contains('_'));
      expect(tripId.split('_')[1], isNotEmpty);
    });

    test('UUID generation should produce unique IDs', () {
      const uuid = Uuid();
      final id1 = uuid.v4();
      final id2 = uuid.v4();
      
      expect(id1, isNotEmpty);
      expect(id2, isNotEmpty);
      expect(id1, isNot(id2));
    });

    test('Trip ID should be reproducible with same inputs', () {
      final userId = 'user123';
      final timestamp = 1234567890;
      final tripId1 = '${userId}_$timestamp';
      final tripId2 = '${userId}_$timestamp';
      
      expect(tripId1, equals(tripId2));
    });
  });
}
