import 'package:flutter/material.dart';
import 'package:interview/core/constants/app_colors.dart';
import 'package:interview/core/constants/app_sizes.dart';

class FeatureItems extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const FeatureItems({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSizes.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.curveLarge),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: AppSizes.iconSizeLarge,
            color: AppColors.primaryColor,
          ),
          AppSizes.horizontalMedium,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppSizes.textStyle),
                AppSizes.verticalXSmall,
                Text(subtitle, style: AppSizes.paragraphStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
