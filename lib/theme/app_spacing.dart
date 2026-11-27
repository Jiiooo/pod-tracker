import 'package:flutter/material.dart';

/// Token spasi (grid 4pt) dan radius.
class Sp {
  Sp._();
  static const double xs = 4, s = 8, m = 12, l = 16, xl = 20, xxl = 24, xxxl = 32;
}

class Rd {
  Rd._();
  static const double card = 20, field = 14, chip = 10, sheet = 28, dialog = 24;
  static BorderRadius get cardR => BorderRadius.circular(card);
  static BorderRadius get fieldR => BorderRadius.circular(field);
  static BorderRadius get chipR => BorderRadius.circular(chip);
}

/// Durasi & kurva animasi standar.
class Motion {
  Motion._();
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 250);
  static const Curve curve = Curves.easeOutCubic;

  static Duration of(BuildContext context, [Duration d = fast]) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;
}
