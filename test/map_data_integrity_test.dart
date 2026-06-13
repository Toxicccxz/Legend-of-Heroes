import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'room map coordinates are unique per zone and exits match directions',
    () async {
      final rooms = await _loadRooms();
      final roomsById = {for (final room in rooms) room['id'] as String: room};
      final coordinatesByZone = <String, Set<String>>{};

      for (final room in rooms) {
        final zoneId = room['zoneId'] as String;
        final coordinate = '${room['mapX']},${room['mapY']}';
        final zoneCoordinates = coordinatesByZone.putIfAbsent(zoneId, () => {});
        expect(
          zoneCoordinates.add(coordinate),
          isTrue,
          reason: 'Duplicate map coordinate $coordinate in zone $zoneId.',
        );
      }

      for (final room in rooms) {
        final exits =
            (room['exits'] as Map<String, dynamic>).cast<String, String>();
        for (final exit in exits.entries) {
          final target = roomsById[exit.value];
          expect(
            target,
            isNotNull,
            reason: 'Missing target room ${exit.value}.',
          );
          if (target == null || target['zoneId'] != room['zoneId']) {
            continue;
          }

          final dx = (target['mapX'] as int) - (room['mapX'] as int);
          final dy = (target['mapY'] as int) - (room['mapY'] as int);
          expect(
            (dx, dy),
            _expectedDelta(exit.key),
            reason:
                '${room['id']} ${exit.key} should point to adjacent ${exit.value}.',
          );
        }
      }
    },
  );
}

Future<List<Map<String, dynamic>>> _loadRooms() async {
  final rawJson = await rootBundle.loadString('assets/data/rooms.json');
  return (jsonDecode(rawJson) as List<dynamic>).cast<Map<String, dynamic>>();
}

(int, int) _expectedDelta(String direction) {
  return switch (direction) {
    'north' => (0, -1),
    'south' => (0, 1),
    'east' => (1, 0),
    'west' => (-1, 0),
    _ => throw ArgumentError.value(direction, 'direction'),
  };
}
