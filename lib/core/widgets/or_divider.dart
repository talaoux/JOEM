import 'package:flutter/material.dart';

/// The "— OU —" divider used between a social sign-in option and a
/// regular email/password form.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE3E3EC))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OU',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9A9AAE),
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE3E3EC))),
      ],
    );
  }
}
