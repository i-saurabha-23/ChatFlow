import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interview/core/constants/app_colors.dart';
import 'package:interview/core/constants/app_sizes.dart';
import 'package:interview/viewmodels/sign_up_view_model.dart';
import 'package:interview/views/auth/sign_in_screen.dart';
import 'package:interview/views/chat/main_chats_screen.dart';
import 'package:interview/widgets/app_loading_indicator.dart';
import 'package:interview/widgets/app_text_field.dart';
import 'package:interview/widgets/primary_button.dart';

class SignUpScreen extends StatefulWidget {
  static const String routeName = '/sign-up';

  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final SignUpViewModel _viewModel = SignUpViewModel();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passcodeController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePasscode = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passcodeController.dispose();
    super.dispose();
  }

  Future<void> _onSignUpPressed() async {
    final validationError = _viewModel.validate(
      name: _nameController.text,
      email: _emailController.text,
      passcode: _passcodeController.text,
    );

    if (validationError != null) {
      _showError(validationError);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _viewModel.register(
        name: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        passcode: _passcodeController.text,
      );

      if (!mounted) {
        return;
      }

      _showSuccess('Account created successfully.');
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
      title: const Text('Sign Up Failed'),
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
              'Sign Up',
              style: TextStyle(
                color: AppColors.textPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Create your ChatFlow account',
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
                controller: _nameController,
                hintText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                textInputAction: TextInputAction.next,
              ),
              AppSizes.verticalMedium,
              AppTextField(
                controller: _emailController,
                hintText: 'Email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
                textInputAction: TextInputAction.next,
              ),
              AppSizes.verticalMedium,
              AppTextField(
                controller: _phoneController,
                hintText: 'Phone Number',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
                textInputAction: TextInputAction.next,
              ),
              AppSizes.verticalMedium,
              AppTextField(
                controller: _passcodeController,
                hintText: '6-digit Passcode',
                keyboardType: TextInputType.number,
                obscureText: _obscurePasscode,
                maxLength: 6,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
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
                PrimaryButton(text: 'Create Account', onPressed: _onSignUpPressed),
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
              AppSizes.verticalMedium,
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, SignInScreen.routeName);
                  },
                  child: const Text('Already have an account? Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
