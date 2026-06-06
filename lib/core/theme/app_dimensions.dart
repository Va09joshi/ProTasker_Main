class AppDimensions {
  // Spacing (Strict Grid: 4, 8, 12, 16, 20, 24, 32)
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // Legacy mappings for existing code compatibility (Mapping to strict grid where possible)
  static const double spacing2 = 4.0; // Round up
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double padding12 = 12.0;
  static const double paddingMD = 16.0;
  static const double padding20 = 20.0;
  static const double paddingLG = 24.0;
  static const double paddingXL = 32.0;
  static const double padding40 = 32.0; // Round down to strict grid
  static const double padding48 = 32.0; // Round down to strict grid

  // Border radius
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 14.0; // Target card radius specified by user
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusPill = 100.0;

  // Icon sizes
  static const double iconSM = 16.0;
  static const double iconMD = 20.0;
  static const double iconDefault = 24.0;
  static const double iconLG = 28.0;
  static const double iconXL = 32.0;

  // Touch targets
  static const double touchTarget = 52.0; // Updated to 52px

  // Cards
  static const double cardElevation = 2.0; // Subtle shadow
  static const double cardBorderWidth = 1.0;
}
