import 'package:flutter/material.dart';

/// A reusable widget that displays social login buttons (Google, Facebook).
///
/// This widget handles the common UI structure for social buttons and takes
/// callbacks for press events to keep the UI separate from the logic.
class SocialAuthButtons extends StatelessWidget {
  final VoidCallback onGooglePressed;
  final VoidCallback onFacebookPressed;
  final String googleText;
  final String facebookText;

  const SocialAuthButtons({
    super.key,
    required this.onGooglePressed,
    required this.onFacebookPressed,
    required this.facebookText,
    required this.googleText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Google Button
        _buildSocialButton(
          onPressed: onGooglePressed,
          iconUrl:
              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
          label: 'Google ile ' + googleText,
        ),
        const SizedBox(height: 12),
        // Facebook Button
        _buildSocialButton(
          onPressed: onFacebookPressed,
          iconUrl:
              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cd/Facebook_logo_%28square%29.png/960px-Facebook_logo_%28square%29.png',
          label: 'Facebook ile ' + facebookText,
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required String iconUrl,
    required String label,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color.fromARGB(134, 255, 255, 255),
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.network(
                iconUrl,
                height: 20,
                width: 20,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error, size: 20);
                },
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
