import 'package:flutter/material.dart';
import 'package:joem/core/widgets/animated_entrance.dart';

/// The white/outlined "Continuer avec Google" button shared by every
/// account/login form in the app.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onTap, this.label = 'Continuer avec Google'});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return PressableScale(child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE3E3EC)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/google_logo.png',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C26),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
