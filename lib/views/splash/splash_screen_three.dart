import 'package:flutter/material.dart';
import 'package:interview/core/constants/app_colors.dart';
import 'package:interview/core/constants/app_sizes.dart';
import 'package:interview/views/auth/sign_up_screen.dart';
import 'package:interview/widgets/primary_button.dart';

class SplashScreenThree extends StatelessWidget {
  static const String routeName = '/splash-3';

  const SplashScreenThree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: AppSizes.screenPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: AppSizes.splashLogoSize,
                        height: AppSizes.splashLogoSize,
                        padding: const EdgeInsets.all(AppSizes.paddingLarge),
                        decoration: BoxDecoration(
                          color: AppColors.cardColor,
                          borderRadius: BorderRadius.circular(
                            AppSizes.curveXLarge,
                          ),
                        ),
                        child: Image.asset('lib/assets/icon.png'),
                      ),
                      AppSizes.verticalLarge,
                      Text(
                        'Ready to get started?',
                        style: AppSizes.headingStyle,
                      ),
                      AppSizes.verticalSmall,
                      Text(
                        'Connect, chat and collaborate in one place.',
                        style: AppSizes.subHeadingStyle,
                        textAlign: TextAlign.center,
                      ),
                      AppSizes.verticalXLarge,
                      PrimaryButton(
                        text: 'Get Started',
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                            context,
                            SignUpScreen.routeName,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
