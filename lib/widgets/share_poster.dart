import 'package:flutter/material.dart';

import '../models/pod_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../utils/photo_storage.dart';

/// Poster setup yang dipotret jadi gambar untuk dibagikan.
/// Selalu memakai palet dark agar hasil konsisten di semua tema.
class SharePoster extends StatelessWidget {
  final PodConfig config;
  const SharePoster({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    const c = AppColors.dark;
    TextStyle style(double size, FontWeight w, Color color) => TextStyle(
        fontFamily: kFontFamily,
        fontSize: size,
        fontWeight: w,
        color: color,
        decoration: TextDecoration.none);

    Widget row(String label, String value) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: style(15, FontWeight.w500, c.textSecondary)),
            Text(value,
                style: style(15, FontWeight.w700, c.textPrimary)
                    .copyWith(fontFeatures: AppTokens.tabular)),
          ],
        );

    return Container(
      width: 400,
      padding: const EdgeInsets.all(Sp.xxxl),
      color: c.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('MY VAPE SETUP',
              style: style(13, FontWeight.w700, c.accent)
                  .copyWith(letterSpacing: 3)),
          const SizedBox(height: Sp.xxl),
          Container(
            height: 200,
            width: 200,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: c.surfaceRaised,
              borderRadius: BorderRadius.circular(Rd.sheet),
              border: Border.all(color: c.outline),
            ),
            child: config.imagePath == null
                ? Icon(Icons.water_drop_outlined,
                    color: c.textSecondary, size: 56)
                : StoragePhoto(value: config.imagePath!, fit: BoxFit.cover),
          ),
          const SizedBox(height: Sp.xxl),
          Text(config.liquidName,
              textAlign: TextAlign.center,
              style: style(28, FontWeight.w800, c.textPrimary)),
          const SizedBox(height: Sp.s),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.star_rounded, color: c.warning, size: 22),
            const SizedBox(width: Sp.xs),
            Text('${config.flavorRating} / 5.0',
                style: style(17, FontWeight.w700, c.warning)),
          ]),
          const SizedBox(height: Sp.xxl),
          Container(
            padding: const EdgeInsets.all(Sp.xl),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: Rd.cardR,
              border: Border.all(color: c.outline),
            ),
            child: Column(children: [
              row('Device', config.deviceName),
              Divider(color: c.outline, height: Sp.xxl),
              row('Resistance', '${config.resistance} Ω'),
              Divider(color: c.outline, height: Sp.xxl),
              row('Sweet Spot', '${config.optimalWattage} W'),
            ]),
          ),
          const SizedBox(height: Sp.xxl),
          Text('Dibuat dengan Pod Tracker',
              style: style(12, FontWeight.w500, c.textSecondary)),
        ],
      ),
    );
  }
}
