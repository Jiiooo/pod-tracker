import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/catalog_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.select<CatalogProvider, bool>((p) => p.isLoading);
    final catalogs = context
        .select<CatalogProvider, List<LiquidCategory>>((p) => p.catalogs);

    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (catalogs.isEmpty) {
      return const EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'Panduan belum tersedia',
        message: 'Gagal memuat katalog panduan. Periksa koneksimu lalu coba lagi.',
      );
    }

    return MaxWidth(
      width: 640,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(Sp.l, Sp.s, Sp.l, Sp.xxl),
        itemCount: catalogs.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: Sp.l),
              child: Text(
                'Katalog setingan liquid & device. Ketuk kategori untuk melihat rekomendasi tiap device.',
                style: context.text.bodyMedium
                    ?.copyWith(color: context.tokens.textSecondary),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: Sp.m),
            child: _CategoryCard(category: catalogs[i - 1]),
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final LiquidCategory category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final accent = context.scheme.primary;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (e) {
            if (e) HapticFeedback.lightImpact();
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: Sp.l, vertical: Sp.xs),
          childrenPadding:
              const EdgeInsets.fromLTRB(Sp.l, 0, Sp.l, Sp.l),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(color: t.accentSoft, borderRadius: Rd.fieldR),
            child: Icon(category.icon, color: accent),
          ),
          title: Text(category.title, style: context.text.titleSmall),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('${category.nicotine} • ${category.subtitle}',
                style: context.text.bodySmall),
          ),
          children: [
            for (final setup in category.setups) _SetupTile(setup: setup),
          ],
        ),
      ),
    );
  }
}

class _SetupTile extends StatelessWidget {
  final DeviceSetup setup;
  const _SetupTile({required this.setup});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      margin: const EdgeInsets.only(top: Sp.s),
      decoration: BoxDecoration(
          color: t.surfaceRaised, borderRadius: Rd.fieldR),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (e) {
            if (e) HapticFeedback.selectionClick();
          },
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: Sp.l),
          childrenPadding: const EdgeInsets.fromLTRB(Sp.l, 0, Sp.l, Sp.l),
          title: Text(setup.deviceName, style: context.text.titleSmall),
          children: [
            for (final spec in setup.specs)
              Padding(
                padding: const EdgeInsets.only(bottom: Sp.s),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, right: Sp.m),
                      child: CircleAvatar(
                          radius: 3, backgroundColor: context.scheme.primary),
                    ),
                    Expanded(child: Text(spec, style: context.text.bodyMedium)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
