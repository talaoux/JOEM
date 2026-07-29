import 'package:flutter/material.dart';

/// The JOEM wordmark centered at the top of the registration/login
/// screens.
class CenteredLogo extends StatelessWidget {
  const CenteredLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/joem_logo.png',
      width: 200,
    );
  }
}
