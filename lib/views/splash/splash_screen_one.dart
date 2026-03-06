import 'package:flutter/material.dart';
import 'package:interview/core/constants/app_colors.dart';
import 'package:interview/core/constants/app_sizes.dart';
import 'package:interview/viewmodels/splash_view_model.dart';
import 'package:interview/widgets/app_loading_indicator.dart';

class SplashScreenOne extends StatefulWidget {
  static const String routeName = '/splash-1';

  const SplashScreenOne({super.key});

  @override
  State<SplashScreenOne> createState() => _SplashScreenOneState();
}

class _SplashScreenOneState extends State<SplashScreenOne> {
  final SplashViewModel _viewModel = SplashViewModel();

  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    final nextRouteName = await _viewModel.resolveNextRoute();
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) {
      return;
    }

    Navigator.pushReplacementNamed(context, nextRouteName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  minWidth: constraints.maxWidth,
                ),
                child: Padding(
                  padding: AppSizes.screenPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                      Text('ChatFlow', style: AppSizes.headingStyle),
                      AppSizes.verticalSmall,
                      Text(
                        'Checking your session...',
                        style: AppSizes.subHeadingStyle,
                        textAlign: TextAlign.center,
                      ),
                      AppSizes.verticalXLarge,
                      const AppLoadingIndicator(),
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
