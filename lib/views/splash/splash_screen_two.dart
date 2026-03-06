import 'package:flutter/material.dart';
import 'package:interview/core/constants/app_colors.dart';
import 'package:interview/core/constants/app_sizes.dart';
import 'package:interview/views/splash/splash_screen_three.dart';
import 'package:interview/widgets/feature_items.dart';
import 'package:interview/widgets/primary_button.dart';

class SplashScreenTwo extends StatelessWidget {
  static const String routeName = '/splash-2';

  const SplashScreenTwo({super.key});

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
                      Text('Why ChatFlow?', style: AppSizes.headingStyle),
                      AppSizes.verticalSmall,
                      Text(
                        'Everything you need for modern messaging',
                        style: AppSizes.subHeadingStyle,
                        textAlign: TextAlign.center,
                      ),
                      AppSizes.verticalXLarge,
                      const FeatureItems(
                        icon: Icons.flash_on_rounded,
                        title: 'Instant Messaging',
                        subtitle: 'Send and receive messages in real time',
                      ),
                      AppSizes.verticalMedium,
                      const FeatureItems(
                        icon: Icons.lock_rounded,
                        title: 'Secure Conversations',
                        subtitle: 'Private and protected chat experience',
                      ),
                      AppSizes.verticalMedium,
                      const FeatureItems(
                        icon: Icons.groups_rounded,
                        title: 'Group Chats',
                        subtitle: 'Stay connected with teams and friends',
                      ),
                      AppSizes.verticalXLarge,
                      PrimaryButton(
                        text: 'Next',
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                            context,
                            SplashScreenThree.routeName,
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
