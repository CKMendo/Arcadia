import 'dart:convert';
import '../repository/course_repository.dart';

class CourseImportData {
  final String name;
  final String city;
  final String state;
  final int holeCount;
  final List<int> pars;
  final List<int> strokeIndexes;
  final List<TeeBoxInput> tees;

  const CourseImportData({
    required this.name,
    required this.city,
    required this.state,
    this.holeCount = 18,
    required this.pars,
    required this.strokeIndexes,
    required this.tees,
  });

  int get totalPar => pars.fold(0, (sum, p) => sum + p);

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'city': city,
      'state': state,
      'holeCount': holeCount,
      'holes': List.generate(holeCount, (i) {
        return {
          'holeNumber': i + 1,
          'par': (i < pars.length) ? pars[i] : 4,
          'strokeIndex': (i < strokeIndexes.length) ? strokeIndexes[i] : i + 1,
        };
      }),
      'tees': tees.map((t) {
        return {
          'name': t.name,
          'colorHex': t.colorHex,
          'courseRating': t.courseRating,
          'slopeRating': t.slopeRating,
          'totalYardage': t.totalYardage,
          'yardages': t.holeYardages?.map((k, v) => MapEntry(k.toString(), v)),
        };
      }).toList(),
    };
  }
}

class CourseImportService {
  /// Parses JSON string with complete course, holes, and tee distances.
  static CourseImportData parseJson(String jsonStr) {
    final Map<String, dynamic> data = jsonDecode(jsonStr.trim()) as Map<String, dynamic>;

    final String name = (data['name'] ?? data['courseName'] ?? 'Imported Course').toString().trim();
    final String city = (data['city'] ?? 'Arcadia').toString().trim();
    final String state = (data['state'] ?? 'MI').toString().trim();
    final int holeCount = (data['holeCount'] as num?)?.toInt() ?? 18;

    final List<int> pars = [];
    final List<int> strokeIndexes = [];

    if (data['holes'] is List) {
      final holesList = data['holes'] as List;
      for (var i = 0; i < holesList.length; i++) {
        final h = holesList[i];
        if (h is Map) {
          final p = (h['par'] as num?)?.toInt() ?? 4;
          final s = (h['strokeIndex'] ?? h['stroke'] ?? h['handicap'] ?? h['hcp'] as num?)?.toInt() ?? (i + 1);
          pars.add(p);
          strokeIndexes.add(s);
        } else if (h is num) {
          pars.add(h.toInt());
          strokeIndexes.add(i + 1);
        }
      }
    } else {
      if (data['pars'] is List) {
        for (final p in data['pars'] as List) {
          pars.add((p as num).toInt());
        }
      }
      if (data['strokeIndexes'] is List || data['handicaps'] is List) {
        final list = (data['strokeIndexes'] ?? data['handicaps']) as List;
        for (final s in list) {
          strokeIndexes.add((s as num).toInt());
        }
      }
    }

    // Fallback if pars or strokes weren't fully provided
    while (pars.length < holeCount) {
      pars.add(4);
    }
    while (strokeIndexes.length < holeCount) {
      strokeIndexes.add(strokeIndexes.length + 1);
    }

    // Parse tees
    final List<TeeBoxInput> tees = [];
    if (data['tees'] is List) {
      for (final t in data['tees'] as List) {
        if (t is Map) {
          final teeName = (t['name'] ?? 'Tee').toString();
          final rating = (t['courseRating'] ?? t['rating'] as num?)?.toDouble() ?? 72.0;
          final slope = (t['slopeRating'] ?? t['slope'] as num?)?.toInt() ?? 125;
          final colorHex = t['colorHex']?.toString();

          final yardagesMap = <int, int>{};
          final rawYardages = t['yardages'] ?? t['distances'] ?? t['holeYardages'];
          if (rawYardages is Map) {
            rawYardages.forEach((k, v) {
              final holeNum = int.tryParse(k.toString());
              final y = (v as num?)?.toInt();
              if (holeNum != null && y != null) {
                yardagesMap[holeNum] = y;
              }
            });
          } else if (rawYardages is List) {
            for (var idx = 0; idx < rawYardages.length; idx++) {
              final y = (rawYardages[idx] as num?)?.toInt();
              if (y != null) {
                yardagesMap[idx + 1] = y;
              }
            }
          }

          int totalYardage = (t['totalYardage'] ?? t['yardage'] as num?)?.toInt() ?? 0;
          if (totalYardage == 0 && yardagesMap.isNotEmpty) {
            totalYardage = yardagesMap.values.fold(0, (sum, y) => sum + y);
          }

          tees.add(TeeBoxInput(
            name: teeName,
            colorHex: colorHex ?? _defaultTeeColor(teeName),
            courseRating: rating,
            slopeRating: slope,
            totalYardage: totalYardage,
            holeYardages: yardagesMap.isNotEmpty ? yardagesMap : null,
          ));
        }
      }
    }

    // Fallback tee if none provided
    if (tees.isEmpty) {
      tees.add(const TeeBoxInput(
        name: 'Regular',
        courseRating: 72.0,
        slopeRating: 125,
        totalYardage: 6500,
      ));
    }

    return CourseImportData(
      name: name,
      city: city,
      state: state,
      holeCount: holeCount,
      pars: pars.sublist(0, holeCount),
      strokeIndexes: strokeIndexes.sublist(0, holeCount),
      tees: tees,
    );
  }

  /// Parses scorecard table text (CSV, tab-delimited, or comma-separated).
  /// Format lines can include:
  /// Hole, 1, 2, 3...
  /// Par, 4, 3, 5...
  /// HCP / Handicap, 7, 15, 1...
  /// Black (75.4/147), 519, 189, 530...
  /// Blue, 490, 175, 505...
  static CourseImportData parseScorecardText(
    String text, {
    String? defaultName,
    String? defaultCity,
    String? defaultState,
  }) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String courseName = defaultName ?? 'Imported Course';
    String city = defaultCity ?? 'Arcadia';
    String state = defaultState ?? 'MI';

    List<int> holesFound = [];
    List<int> parsFound = [];
    List<int> strokesFound = [];
    final List<TeeBoxInput> teesFound = [];

    for (final line in lines) {
      // Split by comma, tab, or multiple spaces if tab/comma not present
      List<String> tokens;
      if (line.contains('\t')) {
        tokens = line.split('\t').map((t) => t.trim()).toList();
      } else if (line.contains(',')) {
        tokens = line.split(',').map((t) => t.trim()).toList();
      } else {
        tokens = line.split(RegExp(r'\s{2,}|\s+')).map((t) => t.trim()).toList();
      }

      if (tokens.isEmpty) continue;
      final header = tokens[0].toLowerCase();

      // Check if this line is a Course Name header (e.g. Course: Pebble Beach)
      if (header.startsWith('course:') || header.startsWith('course name:')) {
        courseName = line.substring(line.indexOf(':') + 1).trim();
        continue;
      }
      if (header.startsWith('city:')) {
        city = line.substring(line.indexOf(':') + 1).trim();
        continue;
      }
      if (header.startsWith('state:')) {
        state = line.substring(line.indexOf(':') + 1).trim();
        continue;
      }

      // Check Hole row
      if (header == 'hole' || header == 'holes' || header == '#') {
        holesFound = _extractInts(tokens.sublist(1));
        continue;
      }

      // Check Par row
      if (header == 'par' || header == 'pars') {
        parsFound = _extractInts(tokens.sublist(1));
        continue;
      }

      // Check Handicap / Stroke Index row
      if (header == 'hcp' || header == 'handicap' || header == 'stroke' || header == 'si' || header == 'index') {
        strokesFound = _extractInts(tokens.sublist(1));
        continue;
      }

      // Tee Yardage row (e.g. Black, Blue, White, Gold, Red, Championship, Forward, etc.)
      final numbers = _extractInts(tokens.sublist(1));
      if (numbers.isNotEmpty) {
        final rawTeeName = tokens[0];
        final parsedTee = _parseTeeNameAndNumbers(rawTeeName, numbers);
        teesFound.add(parsedTee);
      }
    }

    final int holeCount = holesFound.isNotEmpty
        ? holesFound.length
        : (parsFound.isNotEmpty ? parsFound.length : 18);

    // Fill missing pars
    while (parsFound.length < holeCount) {
      parsFound.add(4);
    }
    // Fill missing strokes
    while (strokesFound.length < holeCount) {
      strokesFound.add(strokesFound.length + 1);
    }

    if (teesFound.isEmpty) {
      teesFound.add(const TeeBoxInput(
        name: 'Regular',
        courseRating: 72.0,
        slopeRating: 125,
        totalYardage: 6500,
      ));
    }

    return CourseImportData(
      name: courseName,
      city: city,
      state: state,
      holeCount: holeCount,
      pars: parsFound.sublist(0, holeCount),
      strokeIndexes: strokesFound.sublist(0, holeCount),
      tees: teesFound,
    );
  }

  static List<int> _extractInts(List<String> items) {
    final result = <int>[];
    for (final item in items) {
      // Remove any non-digit except minus
      final clean = item.replaceAll(RegExp(r'[^\d]'), '');
      if (clean.isNotEmpty) {
        final val = int.tryParse(clean);
        if (val != null) {
          result.add(val);
        }
      }
    }
    return result;
  }

  static TeeBoxInput _parseTeeNameAndNumbers(String rawName, List<int> yardageList) {
    // Check if name has rating and slope e.g. "Blue (73.1/138)" or "Black (75.4 / 147)"
    double rating = 72.0;
    int slope = 125;
    String cleanName = rawName;

    final match = RegExp(r'^(.*?)\s*\((\d+\.?\d*)\s*[\/|\,]\s*(\d+)\)').firstMatch(rawName);
    if (match != null) {
      cleanName = match.group(1)?.trim() ?? rawName;
      rating = double.tryParse(match.group(2) ?? '') ?? 72.0;
      slope = int.tryParse(match.group(3) ?? '') ?? 125;
    } else {
      // Estimate realistic rating and slope from tee color
      final lower = rawName.toLowerCase();
      if (lower.contains('black') || lower.contains('champ')) {
        rating = 75.0;
        slope = 145;
      } else if (lower.contains('blue')) {
        rating = 73.0;
        slope = 135;
      } else if (lower.contains('white')) {
        rating = 70.8;
        slope = 130;
      } else if (lower.contains('gold') || lower.contains('yellow')) {
        rating = 68.0;
        slope = 122;
      } else if (lower.contains('red') || lower.contains('forward')) {
        rating = 66.5;
        slope = 118;
      }
    }

    final yardageMap = <int, int>{};
    for (var i = 0; i < yardageList.length; i++) {
      yardageMap[i + 1] = yardageList[i];
    }

    final total = yardageList.fold(0, (sum, y) => sum + y);

    return TeeBoxInput(
      name: cleanName.isNotEmpty ? cleanName : 'Tee',
      colorHex: _defaultTeeColor(cleanName),
      courseRating: rating,
      slopeRating: slope,
      totalYardage: total,
      holeYardages: yardageMap.isNotEmpty ? yardageMap : null,
    );
  }

  static String _defaultTeeColor(String name) {
    final l = name.toLowerCase();
    if (l.contains('black')) return '#1A1A1A';
    if (l.contains('blue')) return '#2563EB';
    if (l.contains('white')) return '#E2E8F0';
    if (l.contains('gold') || l.contains('yellow')) return '#EAB308';
    if (l.contains('red')) return '#EF4444';
    if (l.contains('green')) return '#10B981';
    return '#64748B';
  }

  /// Returns sample JSON template for one-tap copy/pasting.
  static String getSampleJsonTemplate() {
    final sample = {
      'name': 'Arcadia Bluffs (The Bluffs)',
      'city': 'Arcadia',
      'state': 'MI',
      'holeCount': 18,
      'holes': [
        {'holeNumber': 1, 'par': 5, 'strokeIndex': 5},
        {'holeNumber': 2, 'par': 3, 'strokeIndex': 9},
        {'holeNumber': 3, 'par': 5, 'strokeIndex': 17},
        {'holeNumber': 4, 'par': 4, 'strokeIndex': 13},
        {'holeNumber': 5, 'par': 5, 'strokeIndex': 1},
        {'holeNumber': 6, 'par': 3, 'strokeIndex': 15},
        {'holeNumber': 7, 'par': 4, 'strokeIndex': 3},
        {'holeNumber': 8, 'par': 4, 'strokeIndex': 7},
        {'holeNumber': 9, 'par': 3, 'strokeIndex': 11},
        {'holeNumber': 10, 'par': 4, 'strokeIndex': 8},
        {'holeNumber': 11, 'par': 5, 'strokeIndex': 2},
        {'holeNumber': 12, 'par': 4, 'strokeIndex': 6},
        {'holeNumber': 13, 'par': 3, 'strokeIndex': 18},
        {'holeNumber': 14, 'par': 4, 'strokeIndex': 10},
        {'holeNumber': 15, 'par': 5, 'strokeIndex': 4},
        {'holeNumber': 16, 'par': 4, 'strokeIndex': 14},
        {'holeNumber': 17, 'par': 3, 'strokeIndex': 16},
        {'holeNumber': 18, 'par': 4, 'strokeIndex': 12},
      ],
      'tees': [
        {
          'name': 'Black',
          'courseRating': 75.4,
          'slopeRating': 147,
          'totalYardage': 7300,
          'yardages': {
            '1': 519, '2': 189, '3': 530, '4': 415, '5': 583, '6': 195, '7': 472, '8': 449, '9': 203,
            '10': 481, '11': 633, '12': 431, '13': 190, '14': 340, '15': 519, '16': 486, '17': 176, '18': 439
          }
        },
        {
          'name': 'Blue',
          'courseRating': 73.1,
          'slopeRating': 138,
          'totalYardage': 6913,
          'yardages': {
            '1': 490, '2': 175, '3': 505, '4': 390, '5': 555, '6': 180, '7': 445, '8': 420, '9': 185,
            '10': 455, '11': 605, '12': 405, '13': 170, '14': 320, '15': 490, '16': 460, '17': 160, '18': 410
          }
        },
        {
          'name': 'White',
          'courseRating': 70.8,
          'slopeRating': 133,
          'totalYardage': 6389,
          'yardages': {
            '1': 460, '2': 155, '3': 475, '4': 365, '5': 525, '6': 160, '7': 415, '8': 390, '9': 165,
            '10': 425, '11': 575, '12': 375, '13': 150, '14': 300, '15': 460, '16': 430, '17': 140, '18': 380
          }
        }
      ]
    };
    return const JsonEncoder.withIndent('  ').convert(sample);
  }

  /// Returns sample Scorecard CSV format for pasting.
  static String getSampleScorecardCsv() {
    return '''Hole,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18
Par,5,3,5,4,5,3,4,4,3,4,5,4,3,4,5,4,3,4
HCP,5,9,17,13,1,15,3,7,11,8,2,6,18,10,4,14,16,12
Black (75.4/147),519,189,530,415,583,195,472,449,203,481,633,431,190,340,519,486,176,439
Blue (73.1/138),490,175,505,390,555,180,445,420,185,455,605,405,170,320,490,460,160,410
White (70.8/133),460,155,475,365,525,160,415,390,165,425,575,375,150,300,460,430,140,380
Gold (67.9/122),420,135,435,335,485,140,375,350,145,385,535,335,130,270,420,390,120,340''';
  }

  /// Complete built-in presets library
  static List<CourseImportData> getBuiltInPresets() {
    return [
      // 1. Arcadia Bluffs (The Bluffs)
      const CourseImportData(
        name: 'Arcadia Bluffs (The Bluffs)',
        city: 'Arcadia',
        state: 'MI',
        holeCount: 18,
        pars: [5, 3, 5, 4, 5, 3, 4, 4, 3, 4, 5, 4, 3, 4, 5, 4, 3, 4],
        strokeIndexes: [5, 9, 17, 13, 1, 15, 3, 7, 11, 8, 2, 6, 18, 10, 4, 14, 16, 12],
        tees: [
          TeeBoxInput(
            name: 'Black',
            colorHex: '#1A1A1A',
            courseRating: 75.4,
            slopeRating: 147,
            totalYardage: 7300,
            holeYardages: {
              1: 519, 2: 189, 3: 530, 4: 415, 5: 583, 6: 195, 7: 472, 8: 449, 9: 203,
              10: 481, 11: 633, 12: 431, 13: 190, 14: 340, 15: 519, 16: 486, 17: 176, 18: 439,
            },
          ),
          TeeBoxInput(
            name: 'Blue',
            colorHex: '#2563EB',
            courseRating: 73.1,
            slopeRating: 138,
            totalYardage: 6913,
            holeYardages: {
              1: 490, 2: 175, 3: 505, 4: 390, 5: 555, 6: 180, 7: 445, 8: 420, 9: 185,
              10: 455, 11: 605, 12: 405, 13: 170, 14: 320, 15: 490, 16: 460, 17: 160, 18: 410,
            },
          ),
          TeeBoxInput(
            name: 'White',
            colorHex: '#E2E8F0',
            courseRating: 70.8,
            slopeRating: 133,
            totalYardage: 6389,
            holeYardages: {
              1: 460, 2: 155, 3: 475, 4: 365, 5: 525, 6: 160, 7: 415, 8: 390, 9: 165,
              10: 425, 11: 575, 12: 375, 13: 150, 14: 300, 15: 460, 16: 430, 17: 140, 18: 380,
            },
          ),
          TeeBoxInput(
            name: 'Gold',
            colorHex: '#EAB308',
            courseRating: 67.9,
            slopeRating: 122,
            totalYardage: 5700,
            holeYardages: {
              1: 420, 2: 135, 3: 435, 4: 335, 5: 485, 6: 140, 7: 375, 8: 350, 9: 145,
              10: 385, 11: 535, 12: 335, 13: 130, 14: 270, 15: 420, 16: 390, 17: 120, 18: 340,
            },
          ),
        ],
      ),

      // 2. Arcadia Bluffs (The South Course)
      const CourseImportData(
        name: 'Arcadia Bluffs (The South)',
        city: 'Arcadia',
        state: 'MI',
        holeCount: 18,
        pars: [4, 4, 4, 5, 3, 4, 3, 5, 4, 4, 3, 4, 5, 4, 3, 5, 4, 4],
        strokeIndexes: [11, 7, 1, 9, 17, 3, 15, 5, 13, 8, 18, 4, 2, 10, 16, 6, 12, 14],
        tees: [
          TeeBoxInput(
            name: 'Black',
            colorHex: '#1A1A1A',
            courseRating: 75.9,
            slopeRating: 141,
            totalYardage: 7412,
            holeYardages: {
              1: 460, 2: 445, 3: 485, 4: 575, 5: 220, 6: 450, 7: 210, 8: 595, 9: 465,
              10: 440, 11: 195, 12: 460, 13: 580, 14: 435, 15: 215, 16: 605, 17: 420, 18: 480,
            },
          ),
          TeeBoxInput(
            name: 'Blue',
            colorHex: '#2563EB',
            courseRating: 73.5,
            slopeRating: 135,
            totalYardage: 6848,
            holeYardages: {
              1: 425, 2: 410, 3: 450, 4: 535, 5: 195, 6: 415, 7: 185, 8: 555, 9: 430,
              10: 405, 11: 175, 12: 425, 13: 540, 14: 400, 15: 190, 16: 565, 17: 385, 18: 445,
            },
          ),
          TeeBoxInput(
            name: 'White',
            colorHex: '#E2E8F0',
            courseRating: 71.0,
            slopeRating: 129,
            totalYardage: 6328,
            holeYardages: {
              1: 395, 2: 380, 3: 415, 4: 495, 5: 175, 6: 380, 7: 165, 8: 515, 9: 395,
              10: 375, 11: 155, 12: 390, 13: 500, 14: 370, 15: 170, 16: 525, 17: 355, 18: 410,
            },
          ),
          TeeBoxInput(
            name: 'Gold',
            colorHex: '#EAB308',
            courseRating: 68.2,
            slopeRating: 123,
            totalYardage: 5815,
            holeYardages: {
              1: 360, 2: 345, 3: 380, 4: 455, 5: 150, 6: 350, 7: 140, 8: 475, 9: 360,
              10: 340, 11: 135, 12: 355, 13: 460, 14: 335, 15: 145, 16: 485, 17: 320, 18: 375,
            },
          ),
        ],
      ),

      // 3. Forest Dunes Golf Club
      const CourseImportData(
        name: 'Forest Dunes Golf Club',
        city: 'Roscommon',
        state: 'MI',
        holeCount: 18,
        pars: [4, 4, 4, 4, 4, 3, 4, 5, 3, 4, 3, 4, 4, 4, 5, 3, 5, 4],
        strokeIndexes: [9, 5, 13, 1, 11, 15, 7, 3, 17, 8, 18, 4, 14, 6, 12, 16, 2, 10],
        tees: [
          TeeBoxInput(
            name: 'Dunes',
            colorHex: '#1A1A1A',
            courseRating: 75.2,
            slopeRating: 146,
            totalYardage: 7104,
            holeYardages: {
              1: 412, 2: 440, 3: 388, 4: 464, 5: 435, 6: 215, 7: 422, 8: 554, 9: 165,
              10: 442, 11: 178, 12: 430, 13: 395, 14: 420, 15: 540, 16: 180, 17: 575, 18: 450,
            },
          ),
          TeeBoxInput(
            name: 'Forest',
            colorHex: '#2563EB',
            courseRating: 72.8,
            slopeRating: 139,
            totalYardage: 6547,
            holeYardages: {
              1: 380, 2: 410, 3: 355, 4: 425, 5: 400, 6: 190, 7: 390, 8: 520, 9: 145,
              10: 410, 11: 155, 12: 395, 13: 360, 14: 385, 15: 505, 16: 160, 17: 540, 18: 418,
            },
          ),
          TeeBoxInput(
            name: 'Lake',
            colorHex: '#E2E8F0',
            courseRating: 69.9,
            slopeRating: 130,
            totalYardage: 5910,
            holeYardages: {
              1: 345, 2: 375, 3: 320, 4: 385, 5: 360, 6: 165, 7: 350, 8: 480, 9: 125,
              10: 370, 11: 135, 12: 355, 13: 325, 14: 345, 15: 465, 16: 140, 17: 495, 18: 375,
            },
          ),
        ],
      ),

      // 4. Pebble Beach Golf Links
      const CourseImportData(
        name: 'Pebble Beach Golf Links',
        city: 'Pebble Beach',
        state: 'CA',
        holeCount: 18,
        pars: [4, 5, 4, 4, 3, 5, 3, 4, 4, 4, 4, 3, 4, 5, 4, 4, 3, 5],
        strokeIndexes: [8, 10, 12, 16, 14, 2, 18, 6, 4, 7, 5, 17, 9, 3, 13, 11, 15, 1],
        tees: [
          TeeBoxInput(
            name: 'Black',
            colorHex: '#1A1A1A',
            courseRating: 75.5,
            slopeRating: 145,
            totalYardage: 7075,
            holeYardages: {
              1: 381, 2: 516, 3: 404, 4: 331, 5: 195, 6: 523, 7: 107, 8: 428, 9: 505,
              10: 495, 11: 390, 12: 202, 13: 445, 14: 580, 15: 397, 16: 403, 17: 208, 18: 545,
            },
          ),
          TeeBoxInput(
            name: 'Blue',
            colorHex: '#2563EB',
            courseRating: 74.3,
            slopeRating: 143,
            totalYardage: 6828,
            holeYardages: {
              1: 377, 2: 502, 3: 390, 4: 326, 5: 188, 6: 506, 7: 106, 8: 418, 9: 483,
              10: 446, 11: 373, 12: 201, 13: 399, 14: 572, 15: 396, 16: 401, 17: 178, 18: 543,
            },
          ),
          TeeBoxInput(
            name: 'Gold',
            colorHex: '#EAB308',
            courseRating: 72.6,
            slopeRating: 136,
            totalYardage: 6416,
            holeYardages: {
              1: 350, 2: 475, 3: 370, 4: 310, 5: 165, 6: 480, 7: 98, 8: 395, 9: 450,
              10: 420, 11: 350, 12: 185, 13: 375, 14: 540, 15: 370, 16: 375, 17: 160, 18: 515,
            },
          ),
        ],
      ),
    ];
  }
}
