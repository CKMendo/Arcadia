import 'package:flutter/material.dart';
import '../../../database/app_database.dart';
import '../../../shared/theme/app_colors.dart';
import '../../players/repository/player_repository.dart';
import '../../rounds/repository/round_repository.dart';
import '../models/course_models.dart';
import '../repository/course_repository.dart';
import '../repository/trip_schedule_repository.dart';
import 'course_edit_screen.dart';
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
                                          '${course.city}, ${course.state} • ${course.holeCount} Holes',
                                          style: const TextStyle(
                                            color: AppColors.duneLight,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.white, size: 26),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black45,
                                    ),
                                    onPressed: () => _openCourseEditor(context, course: course),
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
                                        '(${tee.totalYardage > 0 ? '${tee.totalYardage} yds' : '18 holes'})',
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
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => _openCourseEditor(context, course: course),
                              icon: const Icon(Icons.settings_outlined, size: 20),
                              label: const Text('Manage Tees, Pars & Handicap Indexes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.lakeCyan,
                                side: const BorderSide(color: AppColors.lakeCyan),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
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

  Color _getTeeColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('black')) return Colors.black;
    if (lower.contains('blue')) return const Color(0xFF1E88E5);
    if (lower.contains('white')) return Colors.white;
    if (lower.contains('gold') || lower.contains('yellow')) return const Color(0xFFFFD54F);
    if (lower.contains('red')) return const Color(0xFFE53935);
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
}
