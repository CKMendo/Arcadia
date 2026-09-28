import '../../features/rounds/models/scoring_calculator.dart';

class CourseHandicapCalculator {
  CourseHandicapCalculator._();

  // Arcadia Bluffs (The Bluffs) - Par 72
  static const bluffsTees = <String, ({double rating, int slope, int yardage})>{
    'Black': (rating: 75.4, slope: 147, yardage: 7300),
    'Blue': (rating: 73.1, slope: 138, yardage: 6800),
    'White': (rating: 70.8, slope: 133, yardage: 6300),
    'Gold': (rating: 67.9, slope: 122, yardage: 5700),
    'Red': (rating: 67.9, slope: 122, yardage: 5100),
  };

  // Arcadia Bluffs (The South) - Par 72
  static const southTees = <String, ({double rating, int slope, int yardage})>{
    'Black': (rating: 75.9, slope: 141, yardage: 7412),
    'Blue': (rating: 73.5, slope: 135, yardage: 6848),
    'White': (rating: 71.0, slope: 129, yardage: 6328),
    'Gold': (rating: 68.2, slope: 123, yardage: 5815),
    'Red': (rating: 68.2, slope: 123, yardage: 5200),
  };

  /// Calculates USGA Course Handicap:
  /// CH = Handicap Index * (Slope / 113) + (Course Rating - Par)
  static int calculate({
    required double handicapIndex,
    required double courseRating,
    required int slopeRating,
    int par = 72,
    double allowance = 1.0,
  }) {
    return ScoringCalculator.calculateCourseHandicap(
      handicapIndex: handicapIndex,
      slopeRating: slopeRating,
      courseRating: courseRating,
      par: par,
      allowance: allowance,
    );
  }

  /// Calculates Course Handicap for The Bluffs course
  static int forBluffs(double handicapIndex, [String tee = 'White']) {
    final t = bluffsTees[tee] ?? bluffsTees['White']!;
    return calculate(
      handicapIndex: handicapIndex,
      courseRating: t.rating,
      slopeRating: t.slope,
      par: 72,
    );
  }

  /// Calculates Course Handicap for The South course
  static int forSouth(double handicapIndex, [String tee = 'White']) {
    final t = southTees[tee] ?? southTees['White']!;
    return calculate(
      handicapIndex: handicapIndex,
      courseRating: t.rating,
      slopeRating: t.slope,
      par: 72,
    );
  }

  /// Calculates Course Handicap given course name and tee name
  static int forCourse({
    required String courseName,
    required double handicapIndex,
    String tee = 'White',
  }) {
    final isSouth = courseName.toLowerCase().contains('south');
    return isSouth ? forSouth(handicapIndex, tee) : forBluffs(handicapIndex, tee);
  }
}
