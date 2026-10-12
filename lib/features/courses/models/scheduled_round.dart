import 'package:intl/intl.dart';
import '../../tournaments/services/tournament_pairings_engine.dart';

class ScheduledRound {
  final String id;
  final int roundNumber;
  final String courseId;
  final String courseName;
  final DateTime date;
  final String teeTimeGroup1; // e.g. "9:30 AM"
  final String teeTimeGroup2; // e.g. "9:42 AM"
  final String format; // '2-Man Best Ball Net Stableford'
  final String? notes; // e.g. "Opening Round - The Bluffs"
  final bool isFinalRound;
  final RoundPairingPlan? pairingPlan;
  final int holeCount; // 18 for regulation tournament play; < 18 (e.g. 12 or 10) for Birdie Pot only

  ScheduledRound({
    required this.id,
    required this.roundNumber,
    required this.courseId,
    required this.courseName,
    required this.date,
    required this.teeTimeGroup1,
    required this.teeTimeGroup2,
    this.format = '2-Man Best Ball Net Stableford',
    this.notes,
    this.isFinalRound = false,
    this.pairingPlan,
    this.holeCount = 18,
  });

  bool get isShortCourse {
    if (holeCount != 18) return true;
    final lower = courseName.toLowerCase();
    return lower.contains('bootlegger') ||
        lower.contains('dozen') ||
        lower.contains('threetops') ||
        lower.contains('short') ||
        lower.contains('par 3');
  }

  int get actualHoleCount {
    if (holeCount != 18) return holeCount;
    final lower = courseName.toLowerCase();
    if (lower.contains('bootlegger')) return 10;
    if (lower.contains('dozen')) return 12;
    if (lower.contains('threetops')) return 9;
    return holeCount;
  }

  String get formattedDate => DateFormat('EEE, MMM d, yyyy').format(date);
  String get shortDate => DateFormat('MMM d').format(date);

  ScheduledRound copyWith({
    String? id,
    int? roundNumber,
    String? courseId,
    String? courseName,
    DateTime? date,
    String? teeTimeGroup1,
    String? teeTimeGroup2,
    String? format,
    String? notes,
    bool? isFinalRound,
    RoundPairingPlan? pairingPlan,
    bool clearPairingPlan = false,
    int? holeCount,
  }) {
    return ScheduledRound(
      id: id ?? this.id,
      roundNumber: roundNumber ?? this.roundNumber,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      date: date ?? this.date,
      teeTimeGroup1: teeTimeGroup1 ?? this.teeTimeGroup1,
      teeTimeGroup2: teeTimeGroup2 ?? this.teeTimeGroup2,
      format: format ?? this.format,
      notes: notes ?? this.notes,
      isFinalRound: isFinalRound ?? this.isFinalRound,
      pairingPlan: clearPairingPlan ? null : (pairingPlan ?? this.pairingPlan),
      holeCount: holeCount ?? this.holeCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roundNumber': roundNumber,
      'courseId': courseId,
      'courseName': courseName,
      'date': date.millisecondsSinceEpoch,
      'teeTimeGroup1': teeTimeGroup1,
      'teeTimeGroup2': teeTimeGroup2,
      'format': format,
      'notes': notes,
      'isFinalRound': isFinalRound,
      'holeCount': actualHoleCount,
      'isShortCourse': isShortCourse,
      if (pairingPlan != null) 'pairingPlan': pairingPlan!.toJson(),
    };
  }

  factory ScheduledRound.fromJson(Map<String, dynamic> json) {
    final cName = json['courseName'] as String? ?? 'Arcadia Course';
    final rawHoleCount = (json['holeCount'] as num?)?.toInt() ?? 18;
    final lowerName = cName.toLowerCase();
    final normalizedHoleCount = (rawHoleCount == 18 &&
            (lowerName.contains('bootlegger') ||
                lowerName.contains('dozen') ||
                lowerName.contains('threetops') ||
                lowerName.contains('short') ||
                lowerName.contains('par 3')))
        ? (lowerName.contains('bootlegger')
            ? 10
            : (lowerName.contains('dozen')
                ? 12
                : (lowerName.contains('threetops') ? 9 : rawHoleCount)))
        : rawHoleCount;

    return ScheduledRound(
      id: json['id'] as String? ?? 'round_${DateTime.now().millisecondsSinceEpoch}',
      roundNumber: (json['roundNumber'] as num?)?.toInt() ?? 1,
      courseId: json['courseId'] as String? ?? '',
      courseName: cName,
      date: json['date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['date'] as int)
          : DateTime.now(),
      teeTimeGroup1: json['teeTimeGroup1'] as String? ?? '9:30 AM',
      teeTimeGroup2: json['teeTimeGroup2'] as String? ?? '9:42 AM',
      format: json['format'] as String? ??
          (normalizedHoleCount != 18
              ? 'Casual Play • Birdie Pot Only (${normalizedHoleCount}H)'
              : '2-Man Best Ball Net Stableford'),
      notes: json['notes'] as String?,
      isFinalRound: json['isFinalRound'] as bool? ?? false,
      holeCount: normalizedHoleCount,
      pairingPlan: json['pairingPlan'] != null
          ? RoundPairingPlan.fromJson(json['pairingPlan'] as Map<String, dynamic>)
          : null,
    );
  }
}
