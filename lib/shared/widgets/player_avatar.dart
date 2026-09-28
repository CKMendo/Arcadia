import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/player_initials_helper.dart';

class PlayerAvatar extends StatelessWidget {
  final String initials;
  final String? name;
  final String? photoPath;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isHeadshotSpace;
  final bool showBadge;
  final IconData badgeIcon;
  final VoidCallback? onTap;

  const PlayerAvatar({
    super.key,
    this.initials = '',
    this.name,
    this.photoPath,
    this.radius = 24,
    this.backgroundColor,
    this.textColor,
    this.isHeadshotSpace = false,
    this.showBadge = false,
    this.badgeIcon = Icons.camera_alt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null &&
        photoPath!.isNotEmpty &&
        File(photoPath!).existsSync();

    final bg = backgroundColor ??
        (hasPhoto
            ? AppColors.surfaceElevated
            : isHeadshotSpace
                ? const Color(0xFF132235)
                : AppColors.surfaceElevated);
    final fg = textColor ?? AppColors.cyanLight;
    final size = radius * 2;

    Widget avatarContent;

    final displayInitials = PlayerInitialsHelper.compute(name, initials);

    if (hasPhoto) {
      avatarContent = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isHeadshotSpace ? AppColors.lakeCyan : AppColors.cardBorder,
            width: isHeadshotSpace ? 2.0 : 1.2,
          ),
          image: DecorationImage(
            image: FileImage(File(photoPath!)),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      avatarContent = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(
            color: isHeadshotSpace
                ? AppColors.lakeCyan.withValues(alpha: 0.6)
                : AppColors.cardBorder,
            width: isHeadshotSpace ? 1.8 : 1.0,
          ),
          boxShadow: isHeadshotSpace
              ? [
                  BoxShadow(
                    color: AppColors.lakeCyan.withValues(alpha: 0.12),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // If it's a headshot space without a photo, show initials with subtle camera placeholder
            if (isHeadshotSpace)
              Icon(
                Icons.person,
                size: radius * 1.15,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            Text(
              displayInitials,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w900,
                fontSize: isHeadshotSpace ? radius * 0.75 : radius * 0.9,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    Widget stack = Stack(
      clipBehavior: Clip.none,
      children: [
        avatarContent,
        if (showBadge || (isHeadshotSpace && !hasPhoto && radius >= 30))
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.all(radius > 36 ? 5 : 3),
              decoration: BoxDecoration(
                color: AppColors.lakeCyan,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.backgroundDark, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                badgeIcon,
                size: radius > 36 ? 16 : 11,
                color: const Color(0xFF06111D),
              ),
            ),
          ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: stack,
      );
    }

    return stack;
  }
}
