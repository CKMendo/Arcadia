import 'package:flutter/material.dart';
import '../../../database/app_database.dart';
import '../../../shared/theme/app_colors.dart';
import '../models/course_models.dart';
import '../repository/course_repository.dart';
import 'course_edit_screen.dart';

class CoursesScreen extends StatelessWidget {
  final CourseRepository courseRepository;

  const CoursesScreen({
    super.key,
    required this.courseRepository,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses & Tees'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.cyanLight, size: 28),
            onSelected: (val) async {
              if (val == 'arcadia_templates') {
                await courseRepository.seedArcadiaBluffsTemplates();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Loaded Arcadia Bluffs (The Bluffs & The South)', style: TextStyle(fontSize: 17)),
                    ),
                  );
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'arcadia_templates',
                child: Row(
                  children: [
                    Icon(Icons.golf_course, color: AppColors.lakeCyan, size: 24),
                    SizedBox(width: 10),
                    Text('Load Arcadia Bluffs Templates', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Course>>(
        stream: courseRepository.watchAllCourses(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final courses = snapshot.data!;

          if (courses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cardBorder, width: 2),
                      ),
                      child: const Icon(
                        Icons.golf_course,
                        size: 64,
                        color: AppColors.lakeCyan,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Courses Configured',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Add the courses you will be playing on your trip, including tees, par, and hole handicap ratings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 18, height: 1.4),
                    ),
                    const SizedBox(height: 26),
                    ElevatedButton.icon(
                      onPressed: () => _openCourseEditor(context),
                      icon: const Icon(Icons.add_location_alt_outlined, size: 26),
                      label: const Text('Add New Course', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await courseRepository.seedArcadiaBluffsTemplates();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Arcadia Bluffs courses loaded!', style: TextStyle(fontSize: 17)),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.auto_awesome, color: AppColors.lakeCyan, size: 26),
                      label: const Text('Load Arcadia Bluffs Templates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return FutureBuilder<CourseDetails?>(
                future: courseRepository.getCourseDetails(course.id),
                builder: (context, detailsSnap) {
                  final details = detailsSnap.data;
                  final imagePath = course.name.toLowerCase().contains('south')
                      ? 'assets/images/arcadia_south.jpg'
                      : 'assets/images/arcadia_bluffs.jpg';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Course Photo Hero Banner
                        SizedBox(
                          height: 160,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                imagePath,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.4),
                                      const Color(0xFF0A1420).withValues(alpha: 0.95),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: const [0.0, 0.45, 1.0],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0A1420).withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.lakeCyan.withValues(alpha: 0.6)),
                                  ),
                                  child: Text(
                                    '${course.holeCount} Holes${details != null ? ' • Par ${details.totalPar}' : ''}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.cyanLight),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                left: 16,
                                right: 16,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 24,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                        shadows: [
                                          Shadow(color: Colors.black, blurRadius: 6),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${course.city}, ${course.state} • Coastal Championship Links',
                                      style: const TextStyle(color: AppColors.duneSand, fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Action Bar & Tees Expansion
                        ExpansionTile(
                          shape: const Border(),
                          initiallyExpanded: true,
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          title: const Text(
                            'Course Tees & Ratings',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.cyanLight),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.lakeCyan, size: 24),
                                tooltip: 'Edit Course',
                                onPressed: () => _openCourseEditor(context, course: course),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
                                tooltip: 'Delete Course',
                                onPressed: () => _confirmDelete(context, course),
                              ),
                            ],
                          ),
                          children: [
                        if (details != null && details.teeBoxes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(color: AppColors.cardBorder),
                                const SizedBox(height: 4),
                                const Text(
                                  'AVAILABLE TEES & RATINGS',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1,
                                    color: AppColors.cyanLight,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...details.teeBoxes.map((t) {
                                  final tb = t.teeBox;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 5),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: _parseTeeColor(tb.name, tb.colorHex),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white30,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          tb.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${tb.courseRating.toStringAsFixed(1)} / ${tb.slopeRating}',
                                          style: const TextStyle(
                                            color: AppColors.duneSand,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        if (t.totalYardage > 0) ...[
                                          const SizedBox(width: 14),
                                          Text(
                                            '${t.totalYardage} yds',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No tees configured for this course yet.',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCourseEditor(context),
        backgroundColor: AppColors.lakeCyan,
        foregroundColor: const Color(0xFF06111D),
        icon: const Icon(Icons.add_location_alt_outlined, size: 28),
        label: const Text('Add Course', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
      ),
    );
  }

  Color _parseTeeColor(String name, String? hex) {
    if (hex != null && hex.isNotEmpty) {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
    }
    final lower = name.toLowerCase();
    if (lower.contains('black')) return const Color(0xFF1A1A1A);
    if (lower.contains('blue')) return const Color(0xFF2563EB);
    if (lower.contains('white')) return const Color(0xFFE2E8F0);
    if (lower.contains('gold') || lower.contains('yellow')) return const Color(0xFFEAB308);
    if (lower.contains('red')) return const Color(0xFFEF4444);
    if (lower.contains('green')) return const Color(0xFF10B981);
    return Colors.grey;
  }

  void _openCourseEditor(BuildContext context, {Course? course}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseEditScreen(
          courseRepository: courseRepository,
          course: course,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Course course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove "${course.name}"?', style: const TextStyle(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontSize: 17)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await courseRepository.deleteCourse(course.id);
    }
  }
}
