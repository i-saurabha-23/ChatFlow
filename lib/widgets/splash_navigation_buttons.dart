import 'package:flutter/material.dart';
import 'package:interview/core/constants/app_colors.dart';
import 'package:interview/core/constants/app_sizes.dart';

class SplashNavigationButtons extends StatelessWidget {
  final VoidCallback onBackPressed;
  final VoidCallback onNextPressed;

  const SplashNavigationButtons({
    super.key,
    required this.onBackPressed,
    required this.onNextPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: AppSizes.buttonHeight,
            child: OutlinedButton(
              onPressed: onBackPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.curveMedium),
                ),
              ),
              child: Text(
                'Back',
                style: AppSizes.textStyle.copyWith(
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),
        ),
        AppSizes.horizontalMedium,
        Expanded(
          child: SizedBox(
            height: AppSizes.buttonHeight,
            child: ElevatedButton(
              onPressed: onNextPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.curveMedium),
                ),
              ),
              child: const Text('Next', style: AppSizes.buttonTextStyle),
            ),
          ),
        ),
      ],
    );
  }
}
