import 'package:flutter/material.dart';
import 'package:interview/core/constants/app_colors.dart';
import 'package:interview/core/constants/app_sizes.dart';
import 'package:interview/models/contact_model.dart';

class ContactProfileScreen extends StatelessWidget {
  final ContactModel contact;

  const ContactProfileScreen({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    final initials = contact.fullName.isEmpty
        ? '?'
        : contact.fullName.trim().substring(0, 1).toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: AppSizes.screenPadding,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E7041), Color(0xFF28935A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white.withValues(alpha: 0.24),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  AppSizes.verticalMedium,
                  Text(
                    contact.fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  AppSizes.verticalSmall,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      contact.about,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSizes.verticalLarge,
            _InfoCard(
              title: 'Contact Information',
              children: [
                _InfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: contact.phoneNumber,
                ),
                if (contact.email != null && contact.email!.isNotEmpty)
                  _InfoTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: contact.email!,
                  ),
              ],
            ),
            AppSizes.verticalMedium,
            _InfoCard(
              title: 'Profile Status',
              children: [
                _InfoTile(
                  icon: Icons.info_outline,
                  label: 'About',
                  value: contact.about,
                ),
                _InfoTile(
                  icon: Icons.verified_user_outlined,
                  label: 'ChatFlow',
                  value: contact.isOnChatFlow ? 'Registered user' : 'Not registered',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E3E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          AppSizes.verticalSmall,
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFFE7F6ED),
        child: Icon(icon, color: AppColors.primaryColor, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: AppColors.textPrimaryColor,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
