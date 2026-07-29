import 'package:flutter/widgets.dart';

/// Shared breakpoint helper used across JOEM screens so layout decisions
/// (paddings, max content width, font scaling) stay consistent.
class Responsive {
  Responsive._();

  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 1024;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;
}
