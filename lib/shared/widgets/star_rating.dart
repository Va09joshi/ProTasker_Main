import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final bool readOnly;
  final ValueChanged<double>? onRatingChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 20.0,
    this.readOnly = true,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        Widget icon;
        if (index < rating.floor()) {
          icon = Icon(Icons.star_rounded, color: AppColors.warning, size: size);
        } else if (index < rating.ceil() && rating % 1 != 0) {
          icon = Icon(Icons.star_half_rounded, color: AppColors.warning, size: size);
        } else {
          icon = Icon(Icons.star_outline_rounded, color: AppColors.border, size: size);
        }

        if (readOnly) {
          return Padding(
            padding: const EdgeInsets.only(right: 2),
            child: icon,
          );
        }

        return GestureDetector(
          onTap: () => onRatingChanged?.call(index + 1.0),
          child: Padding(
            padding: const EdgeInsets.only(right: 2),
            child: SizedBox(
              width: size + 8,
              height: size + 8,
              child: Center(child: icon),
            ),
          ),
        );
      }),
    );
  }
}
