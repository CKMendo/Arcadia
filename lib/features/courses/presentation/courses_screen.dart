import 'package:flutter/material.dart';
import '../../../database/app_database.dart';
import '../../../shared/theme/app_colors.dart';
import '../../players/repository/player_repository.dart';
import '../../rounds/repository/round_repository.dart';
import '../models/course_models.dart';
import '../repository/course_repository.dart';
import '../repository/trip_schedule_repository.dart';
import 'course_edit_screen.dart';
import 'course_import_dialog.dart';
import 'trip_schedule_tab.dart';

class CoursesScreen extends StatelessWidget {
  final CourseRepository courseRepository;
  final PlayerRepository? playerRepository;
  final TripScheduleRepository? tripScheduleRepository;
  final RoundRepository? roundRepository;
  final int initialTabIndex;

  const CoursesScreen({
    super.key,
    required this.courseRepository,
    this.playerRepository,
    this.tripScheduleRepository,
    this.roundRepository,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Courses & Schedule'),
          bottom: const TabBar(
            indicatorColor: AppColors.lakeCyan,
            indicatorWeight: 3.5,
            labelColor: AppColors.cyanLight,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            unselectedLabelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            tabs: [
              Tab(
                icon: Icon(Icons.calendar_month, size: 22),
                text: 'Trip Schedule',
              ),
              Tab(
                icon: Icon(Icons.golf_course, size: 22),
                text: 'Courses & Tees',
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.cloud_download, color: AppColors.cyanLight, size: 26),
              tooltip: 'Import Course',
              onPressed: () => _openCourseImportDialog(context),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.cyanLight, size: 28),
              onSelected: (val) async {
                if (val == 'import_course') {
                  _openCourseImportDialog(context);
                } else if (val == 'add_course') {
                  _openCourseEditor(context);
                } else if (val == 'arcadia_templates') {
                  await courseRepository.seedArcadiaBluffsTemplates();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Loaded Arcadia Bluffs (The Bluffs, The South & The Dozen)', style: TextStyle(fontSize: 17)),
                      ),
                    );
                  }
                } else if (val == 'forest_dunes_templates') {
                  await courseRepository.seedForestDunesTemplates();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Loaded Forest Dunes (Original, The Loop Black, The Loop Red & Bootlegger)', style: TextStyle(fontSize: 17)),
                      ),
                    );
                  }
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'import_course',
                  child: Row(
                    children: [
                      Icon(Icons.cloud_download, color: AppColors.lakeCyan, size: 22),
                      SizedBox(width: 10),
                      Text('Import Course (JSON/CSV)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'add_course',
                  child: Row(
                    children: [
                      Icon(Icons.add_location_alt_outlined, color: AppColors.lakeCyan, size: 22),
                      SizedBox(width: 10),
                      Text('Add New Course', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'arcadia_templates',
                  child: Row(
                    children: [
                      Icon(Icons.golf_course, color: AppColors.lakeCyan, size: 22),
                      SizedBox(width: 10),
                      Text('Load Arcadia Bluffs (3 Courses)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'forest_dunes_templates',
                  child: Row(
                    children: [
                      Icon(Icons.forest, color: Color(0xFF34D399), size: 22),
                      SizedBox(width: 10),
                      Text('Load Forest Dunes (4 Courses)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Trip Schedule & Course Play & Tee Times
            TripScheduleTab(
              courseRepository: courseRepository,
              playerRepository: playerRepository ?? PlayerRepository(AppDatabase()),
              tripScheduleRepository: tripScheduleRepository ?? TripScheduleRepository(),
              roundRepository: roundRepository ?? RoundRepository(AppDatabase()),
            ),

            // Tab 2: Courses & Tees Editor
            _buildCoursesAndTeesView(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesAndTeesView(BuildContext context) {
    return StreamBuilder<List<Course>>(
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
                    'Add or import the courses you will be playing on your trip, including tees, pars, and hole yardage info.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 18, height: 1.4),
                  ),
                  const SizedBox(height: 26),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _openCourseImportDialog(context),
                        icon: const Icon(Icons.cloud_download, size: 24),
                        label: const Text('Import Course', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lakeCyan,
                          foregroundColor: const Color(0xFF04111D),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _openCourseEditor(context),
                        icon: const Icon(Icons.add_location_alt_outlined, size: 24),
                        label: const Text('Add New Course', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await courseRepository.seedArcadiaBluffsTemplates();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Loaded Arcadia Bluffs 3 courses (The Bluffs, The South & The Dozen)!', style: TextStyle(fontSize: 17)),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.auto_awesome, color: AppColors.lakeCyan, size: 26),
                    label: const Text('Load Arcadia Bluffs (3 Courses)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await courseRepository.seedForestDunesTemplates();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Loaded Forest Dunes 4 courses (Original, Loop Black, Loop Red & Bootlegger)!', style: TextStyle(fontSize: 17)),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.forest, color: Color(0xFF34D399), size: 26),
                    label: const Text('Load Forest Dunes (4 Courses)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF34D399))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF34D399)),
                    ),
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
                                    Colors.black.withValues(alpha: 0.85),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              left: 16,
                              right: 16,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          course.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 22,
                                            shadows: [
                                              Shadow(color: Colors.black, blurRadius: 8),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${course.city}, ${course.state} • ${course.holeCount} Holes${details != null ? ' • Par ${details.totalPar}' : ''}',
                                          style: const TextStyle(
                                            color: AppColors.duneLight,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.white, size: 24),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black54,
                                        ),
                                        tooltip: 'Edit Course',
                                        onPressed: () => _openCourseEditor(context, course: course),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black54,
                                        ),
                                        tooltip: 'Delete Course',
                                        onPressed: () => _confirmDeleteCourse(context, course),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tees & Yardage summary table
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'AVAILABLE TEE BOXES',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1,
                                    color: AppColors.cyanLight,
                                  ),
                                ),
                                Text(
                                  'Rating / Slope',
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const Divider(color: AppColors.cardBorder, height: 16),
                            if (details == null)
                              const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                            else if (details.teeBoxes.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text('No tee boxes configured.', style: TextStyle(color: Colors.white54)),
                              )
                            else
                              ...details.teeBoxes.map((teeWithYardages) {
                                final tee = teeWithYardages.teeBox;
                                final yds = teeWithYardages.totalYardage;
                                final holeDistancesCount = teeWithYardages.holeYardages.values.where((y) => y > 0).length;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _getTeeColor(tee.name),
                                          border: Border.all(color: Colors.white38),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        tee.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '(${yds > 0 ? '$yds yds' : '18 holes'}${holeDistancesCount > 0 ? ' • $holeDistancesCount holes mapped' : ''})',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceElevated,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.cardBorder),
                                        ),
                                        child: Text(
                                          '${tee.courseRating.toStringAsFixed(1)} / ${tee.slopeRating}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.lakeCyan,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            const SizedBox(height: 14),

                            // Actions row
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _openCourseEditor(context, course: course),
                                    icon: const Icon(Icons.settings_outlined, size: 20),
                                    label: const Text('Edit Course & Tees', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.lakeCyan,
                                      side: const BorderSide(color: AppColors.lakeCyan),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton.outlined(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  tooltip: 'Delete Course',
                                  style: IconButton.styleFrom(
                                    side: const BorderSide(color: Colors.redAccent),
                                    padding: const EdgeInsets.all(12),
                                  ),
                                  onPressed: () => _confirmDeleteCourse(context, course),
                                ),
                              ],
                            ),
                          ],
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
    );
  }

  Future<void> _confirmDeleteCourse(BuildContext context, Course course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF132235),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text('Delete Course?', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 20)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${course.name}"? This will also remove all its tee boxes, hole pars, and distances.',
          style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontSize: 16)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_forever, size: 20),
            label: const Text('Delete Permanently', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await courseRepository.deleteCourse(course.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1E293B),
              content: Text(
                'Course "${course.name}" deleted successfully.',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting course: $e')),
          );
        }
      }
    }
  }

  Color _getTeeColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('black') || lower.contains('champ')) return Colors.black;
    if (lower.contains('blue')) return const Color(0xFF1E88E5);
    if (lower.contains('white')) return Colors.white;
    if (lower.contains('gold') || lower.contains('yellow')) return const Color(0xFFFFD54F);
    if (lower.contains('red') || lower.contains('forward')) return const Color(0xFFE53935);
    return Colors.teal;
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

  void _openCourseImportDialog(BuildContext context) {
    CourseImportDialog.show(context, courseRepository);
  }
}
