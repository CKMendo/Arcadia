import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ScoreBadge extends StatelessWidget {
  final int score;
  final int par;
  final bool isNet;

  const ScoreBadge({
    super.key,
    required this.score,
    required this.par,
    this.isNet = false,
  });

  @override
  Widget build(BuildContext context) {
    if (score <= 0) {
      return const Text(
        '-',
        style: TextStyle(color: Colors.white38, fontSize: 19, fontWeight: FontWeight.bold),
      );
    }

    final diff = score - par;
    Color bgColor;
    Color textColor = Colors.white;
    String label = score.toString();

    if (diff <= -2) {
      bgColor = AppColors.scoreEagle;
      textColor = Colors.black;
    } else if (diff == -1) {
      bgColor = AppColors.scoreBirdie;
    } else if (diff == 0) {
      bgColor = AppColors.scorePar;
    } else if (diff == 1) {
      bgColor = AppColors.scoreBogey;
    } else {
      bgColor = AppColors.scoreDouble;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }
}

class HandDots extends StatelessWidget {
  final int count;
  final Color color;

  const HandDots({
    super.key,
    required this.count,
    this.color = AppColors.duneSand,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count.clamp(1, 3),
        (i) => Container(
          margin: const EdgeInsets.only(left: 3),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
