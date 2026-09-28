import 'dart:async';
import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../features/courses/repository/course_repository.dart';
import '../features/players/repository/player_repository.dart';
import '../features/rounds/repository/round_repository.dart';
import '../features/tournaments/repository/tournament_repository.dart';
import '../shared/theme/app_colors.dart';
import 'arcadia_shell.dart';

class ArcadiaSplashScreen extends StatefulWidget {
  final AppDatabase database;
  final PlayerRepository playerRepository;
  final CourseRepository courseRepository;
  final TournamentRepository tournamentRepository;
  final RoundRepository roundRepository;

  const ArcadiaSplashScreen({
    super.key,
    required this.database,
    required this.playerRepository,
    required this.courseRepository,
    required this.tournamentRepository,
    required this.roundRepository,
  });

  @override
  State<ArcadiaSplashScreen> createState() => _ArcadiaSplashScreenState();
}

class _ArcadiaSplashScreenState extends State<ArcadiaSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _glowAnimation;
  Timer? _navTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.75).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animController.forward();

    // Transition automatically after 1.8 seconds
    _navTimer = Timer(const Duration(milliseconds: 1900), _proceedToHome);
  }

  void _proceedToHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _navTimer?.cancel();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1000),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: ArcadiaShell(
            database: widget.database,
            playerRepository: widget.playerRepository,
            courseRepository: widget.courseRepository,
            tournamentRepository: widget.tournamentRepository,
            roundRepository: widget.roundRepository,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Fill the phone screen width generously (up to 94% of screen width)
    final logoSize = (screenSize.width * 0.94).clamp(330.0, 580.0);

    return Scaffold(
      backgroundColor: const Color(0xFF06111D),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _proceedToHome,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.15),
              radius: 1.1,
              colors: [
                Color(0xFF0F2B20), // Deep Pine Lake
                Color(0xFF0A1C2E), // Obsidian Deep
                Color(0xFF040A12), // Pure Deep Night
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Large Full-Screen Centered Tournament Crest Emblem
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Hero(
                          tag: 'arcadia_cup_crest_hero',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Container(
                              width: logoSize,
                              height: logoSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.duneSand,
                                  width: 4.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.duneSand.withValues(
                                      alpha: _glowAnimation.value * 0.6,
                                    ),
                                    blurRadius: 36,
                                    spreadRadius: 6,
                                  ),
                                  BoxShadow(
                                    color: AppColors.lakeCyan.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 48,
                                    spreadRadius: 2,
                                  ),
                                  const BoxShadow(
                                    color: Colors.black87,
                                    blurRadius: 20,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/arcadia_cup_crest.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Elegant Tournament Title & Location
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          const Text(
                            'ARCADIA CUP',
                            style: TextStyle(
                              color: AppColors.duneLight,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4.0,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 16,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 32,
                                height: 1.5,
                                color: AppColors.lakeCyan.withValues(alpha: 0.7),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'ARCADIA BLUFFS GOLF CLUB',
                                  style: TextStyle(
                                    color: AppColors.cyanLight,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2.2,
                                  ),
                                ),
                              ),
                              Container(
                                width: 32,
                                height: 1.5,
                                color: AppColors.lakeCyan.withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Subtle Bottom Enter Prompt
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.lakeCyan.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Entering Arcadia Bluffs...',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
