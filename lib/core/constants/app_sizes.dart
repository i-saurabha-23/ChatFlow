import 'package:flutter/material.dart';
import 'package:interview/core/constants/app_colors.dart';

class AppSizes {
  static const double paddingXSmall = 4;
  static const double paddingSmall = 8;
  static const double paddingMedium = 16;
  static const double paddingLarge = 24;
  static const double paddingXLarge = 32;
  static const double paddingXXLarge = 40;

  static const double spaceXSmall = 4;
  static const double spaceSmall = 8;
  static const double spaceMedium = 16;
  static const double spaceLarge = 24;
  static const double spaceXLarge = 32;

  static const double iconSizeSmall = 20;
  static const double iconSize = 28;
  static const double iconSizeLarge = 40;
  static const double splashLogoSize = 140;
  static const double buttonHeight = 54;
  static const double textFieldHeight = 54;

  static const SizedBox verticalXSmall = SizedBox(height: 4);
  static const SizedBox verticalSmall = SizedBox(height: 8);
  static const SizedBox verticalMedium = SizedBox(height: 16);
  static const SizedBox verticalLarge = SizedBox(height: 24);
  static const SizedBox verticalXLarge = SizedBox(height: 32);

  static const SizedBox horizontalXSmall = SizedBox(width: 4);
  static const SizedBox horizontalSmall = SizedBox(width: 8);
  static const SizedBox horizontalMedium = SizedBox(width: 16);
  static const SizedBox horizontalLarge = SizedBox(width: 24);
  static const SizedBox horizontalXLarge = SizedBox(width: 32);

  static const double curveSmall = 8;
  static const double curveMedium = 16;
  static const double curveLarge = 24;
  static const double curveXLarge = 32;

  static const TextStyle paragraphStyle = TextStyle(
    color: AppColors.textSecondaryColor,
    fontSize: 14,
  );

  static const TextStyle textStyle = TextStyle(
    color: AppColors.textPrimaryColor,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle subHeadingStyle = TextStyle(
    color: AppColors.textSecondaryColor,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle headingStyle = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );

  static const EdgeInsets screenPadding = EdgeInsets.all(paddingMedium);
  static const EdgeInsets cardPadding = EdgeInsets.all(paddingMedium);
}
