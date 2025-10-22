import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  // Overpass API query for golf courses in Sweden (nodes, ways, relations)
  const overpassUrl = 'https://overpass-api.de/api/interpreter';
  const query = '''
  [out:json][timeout:25];
  (
    node[leisure=golf_course](55.0,10.5,69.0,24.0);
    way[leisure=golf_course](55.0,10.5,69.0,24.0);
    relation[leisure=golf_course](55.0,10.5,69.0,24.0);
  );
  out body center;
  ''';

  print('Fetching golf course data from Overpass API (Sweden, all types)...');
  final response = await http.post(
    Uri.parse(overpassUrl),
    body: {'data': query},
  );

  // Load custom fields from golf_courses_custom.json if file exists
  final customFile = File('golf_courses_custom.json');
  Map<int, Map<String, dynamic>> customFields = {};
  if (await customFile.exists()) {
    try {
      final customData = json.decode(await customFile.readAsString()) as List<dynamic>;
      for (final course in customData) {
        if (course is Map<String, dynamic> && course['id'] != null) {
          customFields[course['id']] = course;
        }
      }
    } catch (e) {
      print('Warning: Could not read custom fields: $e');
    }
  }

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final elements = data['elements'] as List<dynamic>? ?? [];
    // Filter out objects without a name or with generic/unknown names
    final validCourses = elements.where((e) {
      final tags = e['tags'] ?? {};
      final name = tags['name']?.toString().trim() ?? '';
      if (name.isEmpty) return false;
      final lower = name.toLowerCase();
      if (lower == 'unknown' || lower == 'golf course' || lower == 'course') return false;
      return true;
    }).map((e) {
      final tags = e['tags'] ?? {};
      final lat = e['lat'] ?? e['center']?['lat'];
      final lon = e['lon'] ?? e['center']?['lon'];
      final id = e['id'];
      final merged = {
        'id': id,
        'type': e['type'],
        'name': tags['name'],
        'lat': lat,
        'lon': lon,
        'tags': tags,
      };
      // Merge custom fields from custom file
      if (customFields.containsKey(id)) {
        final custom = customFields[id]!;
        for (final key in custom.keys) {
          if (!merged.containsKey(key) && key != 'id') {
            merged[key] = custom[key];
          }
          // If key is 'logo', always preserve it
          if (key == 'logo') {
            merged['logo'] = custom['logo'];
          }
        }
      }
      return merged;
    }).toList();

    final encoder = JsonEncoder.withIndent('  ');
    final file = File('assets/golf_courses.json');
    await file.writeAsString(encoder.convert(validCourses));
    print('Saved ${validCourses.length} valid golf courses to assets/golf_courses.json (custom fields merged from golf_courses_custom.json)');
  } else {
    print('Failed to fetch data: ${response.statusCode}');
  }
}
