/// Animation-duration tokens shared across JOEM screens.
class AppDurations {
  AppDurations._();

  /// Fade + slide transition used when a form/wizard step changes content.
  static const Duration stepTransition = Duration(milliseconds: 350);

  /// Quick press/tap feedback (scale, highlight...).
  static const Duration tapFeedback = Duration(milliseconds: 150);
}
