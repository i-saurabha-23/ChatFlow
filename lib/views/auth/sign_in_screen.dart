import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interview/core/constants/app_colors.dart';
import 'package:interview/core/constants/app_sizes.dart';
import 'package:interview/viewmodels/sign_in_view_model.dart';
import 'package:interview/views/auth/sign_up_screen.dart';
import 'package:interview/views/chat/main_chats_screen.dart';
import 'package:interview/widgets/app_loading_indicator.dart';
import 'package:interview/widgets/app_text_field.dart';
import 'package:interview/widgets/primary_button.dart';

class SignInScreen extends StatefulWidget {
  static const String routeName = '/sign-in';

  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final SignInViewModel _viewModel = SignInViewModel();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passcodeController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePasscode = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passcodeController.dispose();
    super.dispose();
  }

  Future<void> _onSignInPressed() async {
    final validationError = _viewModel.validate(
      email: _emailController.text,
      passcode: _passcodeController.text,
    );

    if (validationError != null) {
      _showError(validationError);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _viewModel.login(
        email: _emailController.text,
        passcode: _passcodeController.text,
      );

      if (!mounted) {
        return;
      }

      _showSuccess('Signed in successfully.');
      Navigator.pushReplacementNamed(context, MainChatsScreen.routeName);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _onGoogleSignInPressed() async {
    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _viewModel.loginWithGoogle();

      if (!mounted) {
        return;
      }

      _showSuccess('Signed in with Google.');
      Navigator.pushReplacementNamed(context, MainChatsScreen.routeName);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    CherryToast.error(
      title: const Text('Sign In Failed'),
      description: Text(message),
    ).show(context);
  }

  void _showSuccess(String message) {
    CherryToast.success(
      title: const Text('Success'),
      description: Text(message),
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sign In',
              style: TextStyle(
                color: AppColors.textPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Welcome back to ChatFlow',
              style: TextStyle(
                color: AppColors.textSecondaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSizes.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSizes.verticalLarge,
              AppTextField(
                controller: _emailController,
                hintText: 'Email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
                textInputAction: TextInputAction.next,
              ),
              AppSizes.verticalMedium,
              AppTextField(
                controller: _passcodeController,
                hintText: '6-digit Passcode',
                keyboardType: TextInputType.number,
                obscureText: _obscurePasscode,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _obscurePasscode = !_obscurePasscode);
                  },
                  icon: Icon(
                    _obscurePasscode ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
              AppSizes.verticalLarge,
              if (_isSubmitting)
                const Center(child: AppLoadingIndicator(size: 36))
              else
                PrimaryButton(text: 'Sign In', onPressed: _onSignInPressed),
              AppSizes.verticalMedium,
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, SignUpScreen.routeName);
                  },
                  child: const Text("Don't have an account? Sign Up"),
                ),
              ),
              AppSizes.verticalMedium,
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSizes.curveMedium),
                  onTap: _onGoogleSignInPressed,
                  child: Container(
                    width: double.infinity,
                    height: AppSizes.buttonHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.curveMedium),
                      border: Border.all(color: const Color(0xFFE0E3E7)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFD),
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            'G',
                            style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        AppSizes.horizontalSmall,
                        const Text(
                          'Continue with Google',
                          style: TextStyle(
                            color: AppColors.textPrimaryColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
