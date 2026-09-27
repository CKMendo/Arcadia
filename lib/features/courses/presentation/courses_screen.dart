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
            icon: const Icon(Icons.more_vert, color: AppColors.goldLight),
            onSelected: (val) async {
              if (val == 'arcadia_templates') {
                await courseRepository.seedArcadiaBluffsTemplates();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Loaded Arcadia Bluffs (The Bluffs & The South)'),
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
                    Icon(Icons.golf_course, color: AppColors.gold, size: 20),
                    SizedBox(width: 8),
                    Text('Load Arcadia Bluffs Templates'),
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
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cardBorder, width: 2),
                      ),
                      child: const Icon(
                        Icons.golf_course,
                        size: 56,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Courses Configured',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add the courses you will be playing on your trip, including tees, par, and hole handicap ratings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _openCourseEditor(context),
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Add New Course'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await courseRepository.seedArcadiaBluffsTemplates();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Arcadia Bluffs courses loaded!'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.auto_awesome, color: AppColors.gold),
                      label: const Text('Load Arcadia Bluffs Templates'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return FutureBuilder<CourseDetails?>(
                future: courseRepository.getCourseDetails(course.id),
                builder: (context, detailsSnap) {
                  final details = detailsSnap.data;
                  return Card(
                    child: ExpansionTile(
                      shape: const Border(),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.sageGreen.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.flag, color: AppColors.gold),
                      ),
                      title: Text(
                        course.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      subtitle: Text(
                        '${course.city}, ${course.state} • ${course.holeCount} Holes'
                        '${details != null ? ' • Par ${details.totalPar}' : ''}',
                        style: const TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent, size: 20),
                            onPressed: () => _confirmDelete(context, course),
                          ),
                        ],
                      ),
                      children: [
                        if (details != null && details.teeBoxes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(color: AppColors.cardBorder),
                                const Text(
                                  'AVAILABLE TEES & RATINGS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                    color: AppColors.gold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...details.teeBoxes.map((t) {
                                  final tb = t.teeBox;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: _parseTeeColor(tb.name, tb.colorHex),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white24,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          tb.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${tb.courseRating.toStringAsFixed(1)} / ${tb.slopeRating}',
                                          style: const TextStyle(
                                            color: AppColors.goldLight,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (t.totalYardage > 0) ...[
                                          const SizedBox(width: 12),
                                          Text(
                                            '${t.totalYardage} yds',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
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
                              style: TextStyle(color: Colors.white54),
                            ),
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
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add Course', style: TextStyle(fontWeight: FontWeight.bold)),
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
    return Colors.white70;
  }

  Future<void> _confirmDelete(BuildContext context, Course course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course?'),
        content: Text('Remove "${course.name}" and its tees from the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await courseRepository.deleteCourse(course.id);
    }
  }

  void _openCourseEditor(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseEditScreen(courseRepository: courseRepository),
      ),
    );
  }
}
