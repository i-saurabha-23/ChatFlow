import 'package:flutter/material.dart';
import 'package:interview/core/constants/app_colors.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final Color color;

  const AppLoadingIndicator({
    super.key,
    this.size = 50,
    this.color = AppColors.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingAnimationWidget.staggeredDotsWave(color: color, size: size);
  }
}
