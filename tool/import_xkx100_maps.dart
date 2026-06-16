import 'dart:convert';
import 'dart:io';

const _directions = {
  'north': (0, -1),
  'south': (0, 1),
  'east': (1, 0),
  'west': (-1, 0),
  'northeast': (1, -1),
  'northwest': (-1, -1),
  'southeast': (1, 1),
  'southwest': (-1, 1),
  'enter': (0, 0),
  'out': (0, 0),
  'up': (0, 0),
  'down': (0, 0),
};

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.contains('--help')) {
    _printUsage();
    return;
  }

  final sourceRoot = Directory(args.first);
  final outputDir = Directory(_option(args, '--out') ?? 'build/xkx100_maps');
  final mergeAssets = args.contains('--merge-assets');
  if (!sourceRoot.existsSync()) {
    stderr.writeln('xkx100 source root not found: ${sourceRoot.path}');
    exitCode = 2;
    return;
  }
  final dDir = Directory('${sourceRoot.path}/d');
  if (!dDir.existsSync()) {
    stderr.writeln('Missing xkx100 map directory: ${dDir.path}');
    exitCode = 2;
    return;
  }

  final rawRooms = _scanRooms(dDir);
  final roomIdsByPath = {for (final room in rawRooms) room.sourcePath: room.id};
  final rooms =
      rawRooms
          .map((room) => room.toJson(roomIdsByPath))
          .where((room) => (room['exits'] as Map<String, String>).isNotEmpty)
          .toList();
  final zones = _buildZones(rawRooms);
  _assignCoordinates(rooms);

  outputDir.createSync(recursive: true);
  final targetRooms =
      mergeAssets
          ? _mergeById(_readJsonList('assets/data/rooms.json'), rooms)
          : rooms;
  final targetZones =
      mergeAssets
          ? _mergeById(_readJsonList('assets/data/zones.json'), zones)
          : zones;

  File(
    '${outputDir.path}/rooms.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(targetRooms));
  File(
    '${outputDir.path}/zones.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(targetZones));

  stdout.writeln(
    'Imported ${rooms.length} rooms and ${zones.length} zones from ${dDir.path}.',
  );
  stdout.writeln('Output: ${outputDir.path}');
  if (mergeAssets) {
    stdout.writeln(
      'Merged with current assets. Review output before replacing assets/data.',
    );
  }
}

List<_RawRoom> _scanRooms(Directory dDir) {
  final rooms = <_RawRoom>[];
  final files = dDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.c'));
  for (final file in files) {
    final content = file.readAsStringSync();
    if (!content.contains('set("short"') || !content.contains('set("exits"')) {
      continue;
    }
    final sourcePath = _sourcePathFor(dDir, file);
    final zoneId = _zoneIdFor(sourcePath);
    final short = _singleLineSet(content, 'short') ?? _basename(sourcePath);
    final long = _longSet(content) ?? short;
    final exits = _exitMap(content, sourcePath);
    final objects = _objects(content, sourcePath);
    rooms.add(
      _RawRoom(
        sourcePath: sourcePath,
        id: _roomIdFor(sourcePath),
        zoneId: zoneId,
        name: short,
        description: long,
        exits: exits,
        objectPaths: objects,
      ),
    );
  }
  return rooms;
}

String _sourcePathFor(Directory dDir, File file) {
  final root = dDir.absolute.path.replaceAll('\\', '/');
  final path = file.absolute.path.replaceAll('\\', '/');
  return path.substring(root.length + 1).replaceFirst(RegExp(r'\.c$'), '');
}

String _zoneIdFor(String sourcePath) {
  final zone = sourcePath.split('/').first;
  return 'xkx_$zone';
}

String _roomIdFor(String sourcePath) {
  return 'xkx_${sourcePath.replaceAll('/', '_').replaceAll('-', '_')}';
}

String _basename(String sourcePath) {
  return sourcePath.split('/').last;
}

String? _singleLineSet(String content, String key) {
  final match = RegExp(
    'set\\("$key"\\s*,\\s*"([^"]*)"\\s*\\)',
    dotAll: true,
  ).firstMatch(content);
  return match?.group(1)?.trim();
}

String? _longSet(String content) {
  final simple = _singleLineSet(content, 'long');
  if (simple != null) {
    return simple;
  }
  final heredoc = RegExp(
    r'set\("long"\s*,\s*@([A-Z]+)\s*(.*?)\s*\1\s*\)',
    dotAll: true,
  ).firstMatch(content);
  return heredoc?.group(2)?.trim().replaceAll(RegExp(r'\s+'), ' ');
}

Map<String, String> _exitMap(String content, String sourcePath) {
  final body = _mappingBody(content, 'exits');
  if (body == null) {
    return const {};
  }
  final exits = <String, String>{};
  final entryPattern = RegExp(r'"([^"]+)"\s*:\s*(?:__DIR__\s*)?"([^"]+)"');
  for (final match in entryPattern.allMatches(body)) {
    final direction = match.group(1)!;
    final target = _normalizeTarget(sourcePath, match.group(2)!);
    if (_directions.containsKey(direction) && target != null) {
      exits[direction] = _roomIdFor(target);
    }
  }
  return exits;
}

List<String> _objects(String content, String sourcePath) {
  final body = _mappingBody(content, 'objects');
  if (body == null) {
    return const [];
  }
  final objects = <String>[];
  final entryPattern = RegExp(r'(?:__DIR__\s*)?"([^"]+)"\s*:');
  for (final match in entryPattern.allMatches(body)) {
    final target = _normalizeTarget(sourcePath, match.group(1)!);
    if (target != null) {
      objects.add(target);
    }
  }
  return objects;
}

String? _mappingBody(String content, String key) {
  final start = content.indexOf('set("$key"');
  if (start == -1) {
    return null;
  }
  final mappingStart = content.indexOf('([', start);
  if (mappingStart == -1) {
    return null;
  }
  var depth = 0;
  for (var i = mappingStart; i < content.length - 1; i += 1) {
    final pair = content.substring(i, i + 2);
    if (pair == '([') {
      depth += 1;
      i += 1;
      continue;
    }
    if (pair == '])') {
      depth -= 1;
      if (depth == 0) {
        return content.substring(mappingStart + 2, i);
      }
      i += 1;
    }
  }
  return null;
}

String? _normalizeTarget(String sourcePath, String target) {
  var path = target.replaceAll('\\', '/');
  if (path.startsWith('/d/')) {
    path = path.substring('/d/'.length);
  } else if (path.startsWith('/')) {
    return null;
  } else {
    final dirParts = sourcePath.split('/')..removeLast();
    path = [...dirParts, path].join('/');
  }
  path = path.replaceFirst(RegExp(r'\.c$'), '');
  final parts = <String>[];
  for (final part in path.split('/')) {
    if (part.isEmpty || part == '.') {
      continue;
    }
    if (part == '..') {
      if (parts.isNotEmpty) {
        parts.removeLast();
      }
      continue;
    }
    parts.add(part);
  }
  return parts.join('/');
}

List<Map<String, dynamic>> _buildZones(List<_RawRoom> rooms) {
  final zoneIds = rooms.map((room) => room.zoneId).toSet().toList()..sort();
  return [
    for (final zoneId in zoneIds)
      {
        'id': zoneId,
        'name': zoneId.replaceFirst('xkx_', ''),
        'description':
            'Imported from xkx100 /d/${zoneId.replaceFirst('xkx_', '')}.',
        'visibleRadius': 4,
        'path': '/d/${zoneId.replaceFirst('xkx_', '')}',
        'levelRange': [1, 99],
        'respawnSeconds': 300,
      },
  ];
}

void _assignCoordinates(List<Map<String, dynamic>> rooms) {
  final roomsById = {for (final room in rooms) room['id'] as String: room};
  final byZone = <String, List<Map<String, dynamic>>>{};
  for (final room in rooms) {
    byZone.putIfAbsent(room['zoneId'] as String, () => []).add(room);
  }
  for (final zoneRooms in byZone.values) {
    final queue = <Map<String, dynamic>>[];
    zoneRooms.first['mapX'] = 0;
    zoneRooms.first['mapY'] = 0;
    queue.add(zoneRooms.first);
    while (queue.isNotEmpty) {
      final room = queue.removeAt(0);
      final exits = (room['exits'] as Map<String, String>);
      for (final entry in exits.entries) {
        final delta = _directions[entry.key];
        final target = roomsById[entry.value];
        if (delta == null ||
            target == null ||
            target['zoneId'] != room['zoneId'] ||
            target.containsKey('mapX')) {
          continue;
        }
        target['mapX'] = (room['mapX'] as int) + delta.$1;
        target['mapY'] = (room['mapY'] as int) + delta.$2;
        queue.add(target);
      }
    }
    var fallback = 0;
    for (final room in zoneRooms) {
      room['mapX'] ??= fallback % 20;
      room['mapY'] ??= fallback ~/ 20;
      fallback += 1;
    }
  }
}

List<Map<String, dynamic>> _mergeById(
  List<Map<String, dynamic>> existing,
  List<Map<String, dynamic>> imported,
) {
  final merged = <String, Map<String, dynamic>>{
    for (final item in existing) item['id'] as String: item,
  };
  for (final item in imported) {
    merged.putIfAbsent(item['id'] as String, () => item);
  }
  return merged.values.toList();
}

List<Map<String, dynamic>> _readJsonList(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return [];
  }
  return (jsonDecode(file.readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();
}

String? _option(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index == -1 || index == args.length - 1) {
    return null;
  }
  return args[index + 1];
}

void _printUsage() {
  stdout.writeln(
    'Usage: dart run tool/import_xkx100_maps.dart <xkx100-root> [--out <dir>] [--merge-assets]',
  );
  stdout.writeln('');
  stdout.writeln('Example:');
  stdout.writeln(
    '  dart run tool/import_xkx100_maps.dart ../xkx100 --out build/xkx100_maps',
  );
}

class _RawRoom {
  const _RawRoom({
    required this.sourcePath,
    required this.id,
    required this.zoneId,
    required this.name,
    required this.description,
    required this.exits,
    required this.objectPaths,
  });

  final String sourcePath;
  final String id;
  final String zoneId;
  final String name;
  final String description;
  final Map<String, String> exits;
  final List<String> objectPaths;

  Map<String, dynamic> toJson(Map<String, String> roomIdsByPath) {
    return {
      'id': id,
      'name': name,
      'description': description,
      'zoneId': zoneId,
      'aliases': [sourcePath],
      'sceneType': 'outdoor',
      'levelRange': [1, 99],
      'tags': ['xkx100', zoneId.replaceFirst('xkx_', '')],
      'exits': {
        for (final entry in exits.entries)
          if (roomIdsByPath.containsValue(entry.value)) entry.key: entry.value,
      },
      'npcs': <String>[],
      'items': <String>[],
      'commands': <Map<String, dynamic>>[],
      'onEnterEvents': <String>[],
      'investigateEvents': <String>[],
      'restEvents': <String>[],
    };
  }
}
