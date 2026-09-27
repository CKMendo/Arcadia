import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PlayerAvatar extends StatelessWidget {
  final String initials;
  final String? photoPath;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;

  const PlayerAvatar({
    super.key,
    required this.initials,
    this.photoPath,
    this.radius = 20,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (photoPath != null && photoPath!.isNotEmpty) {
      final file = File(photoPath!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: FileImage(file),
        );
      }
    }

    final bg = backgroundColor ?? AppColors.sageGreen;
    final fg = textColor ?? AppColors.goldLight;

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Text(
        initials.isNotEmpty ? initials : '?',
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
