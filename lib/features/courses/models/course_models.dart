import '../../../database/app_database.dart';

class CourseDetails {
  final Course course;
  final List<CourseHole> holes;
  final List<TeeBoxWithYardages> teeBoxes;

  const CourseDetails({
    required this.course,
    required this.holes,
    required this.teeBoxes,
  });

  int get totalPar => holes.fold(0, (sum, h) => sum + h.par);
}

class TeeBoxWithYardages {
  final TeeBox teeBox;
  final Map<int, int> holeYardages; // holeNumber -> yardage

  const TeeBoxWithYardages({
    required this.teeBox,
    required this.holeYardages,
  });

  int get totalYardage =>
      teeBox.totalYardage > 0
          ? teeBox.totalYardage
          : holeYardages.values.fold(0, (sum, y) => sum + y);
}
