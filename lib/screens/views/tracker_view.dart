import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/pod_config.dart';
import '../../providers/pod_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_tokens.dart';
import '../../utils/photo_storage.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/share_poster.dart';
import '../add_config_screen.dart';
import '../widgets/tag_filter_bar.dart';

class TrackerView extends StatelessWidget {
  const TrackerView({super.key});

  @override
  Widget build(BuildContext context) {
    final configs =
        context.select<PodProvider, List<PodConfig>>((p) => p.activeConfigs);
    final isLoading = context.select<PodProvider, bool>((p) => p.isLoading);
    final hasPending = context.select<PodProvider, bool>(
        (p) => p.syncError != null || p.pendingCount > 0);

    Widget body;
    if (isLoading && configs.isEmpty) {
      body = const _ShimmerList();
    } else if (configs.isEmpty) {
      body = EmptyState(
        icon: Icons.water_drop_outlined,
        title: 'Belum ada pod',
        message: 'Catat setup pertamamu untuk mulai melacak rasa dan biaya.',
        actionLabel: 'Tambah pod',
        onAction: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddConfigScreen())),
      );
    } else {
      body = _PodList(configs: configs);
    }

    return Column(
      children: [
        const _SearchSortRow(),
        const TagFilterBar(),
        if (hasPending) const _SyncBanner(),
        Expanded(
          child: AnimatedSwitcher(
            duration: Motion.of(context),
            switchInCurve: Motion.curve,
            child: KeyedSubtree(
                key: ValueKey(body.runtimeType), child: body),
          ),
        ),
      ],
    );
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final provider = context.read<PodProvider>();
    final msg = context.select<PodProvider, String>((p) =>
        p.syncError ?? '${p.pendingCount} perubahan belum tersinkron');
    final loading = context.select<PodProvider, bool>((p) => p.isLoading);
    return Container(
      margin: const EdgeInsets.fromLTRB(Sp.l, Sp.xs, Sp.l, Sp.s),
      padding: const EdgeInsets.only(left: Sp.m, right: Sp.xs),
      decoration: BoxDecoration(
        color: t.warning.withValues(alpha: 0.12),
        borderRadius: Rd.fieldR,
      ),
      child: Row(children: [
        Icon(Icons.cloud_off_rounded, color: t.warning, size: 18),
        const SizedBox(width: Sp.s),
        Expanded(
            child: Text(msg,
                style: context.text.labelLarge
                    ?.copyWith(fontSize: 12, color: t.warning))),
        TextButton(
          style: TextButton.styleFrom(
              minimumSize: const Size(48, 48), foregroundColor: t.warning),
          onPressed: loading ? null : provider.syncData,
          child: const Text('Coba lagi'),
        ),
      ]),
    );
  }
}

class _SearchSortRow extends StatelessWidget {
  const _SearchSortRow();

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PodProvider>();
    final sort = context.select<PodProvider, String>((p) => p.sortBy);
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.l, Sp.s, Sp.l, Sp.s),
      child: Row(children: [
        Expanded(
          child: TextField(
            onChanged: provider.setSearchQuery,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Cari liquid atau device',
              prefixIcon: Icon(Icons.search_rounded),
              contentPadding: EdgeInsets.symmetric(vertical: Sp.m),
            ),
          ),
        ),
        const SizedBox(width: Sp.s),
        PopupMenuButton<String>(
          tooltip: 'Urutkan',
          initialValue: sort,
          onSelected: provider.setSortBy,
          shape: RoundedRectangleBorder(borderRadius: Rd.fieldR),
          position: PopupMenuPosition.under,
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'date', child: Text('Terbaru')),
            PopupMenuItem(value: 'rating', child: Text('Rating tertinggi')),
            PopupMenuItem(value: 'price', child: Text('Harga termurah')),
          ],
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: t.surfaceRaised, borderRadius: Rd.fieldR),
            child: Icon(Icons.swap_vert_rounded,
                color: sort == 'date' ? t.textSecondary : context.scheme.primary),
          ),
        ),
      ]),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      padding: const EdgeInsets.fromLTRB(Sp.l, Sp.s, Sp.l, Sp.l),
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.only(bottom: Sp.m),
        child: Shimmer.fromColors(
          baseColor: t.surfaceRaised,
          highlightColor: t.outline,
          child: Container(
            height: 260,
            decoration: BoxDecoration(
                color: t.surfaceRaised, borderRadius: Rd.cardR),
          ),
        ),
      ),
    );
  }
}

class _PodList extends StatelessWidget {
  final List<PodConfig> configs;
  const _PodList({required this.configs});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: configs.length,
      padding: const EdgeInsets.fromLTRB(Sp.l, Sp.s, Sp.l, 96),
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.only(bottom: Sp.m),
        child: PodCard(key: ValueKey(configs[i].id), config: configs[i]),
      ),
    );
  }
}

class PodCard extends StatelessWidget {
  final PodConfig config;
  const PodCard({super.key, required this.config});

  Future<void> _share(BuildContext context) async {
    HapticFeedback.heavyImpact();
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
        const SnackBar(content: Text('Menyiapkan poster setup...')));
    try {
      final bytes = await ScreenshotController().captureFromWidget(
        SharePoster(config: config),
        delay: const Duration(milliseconds: 100),
        context: context,
      );
      final temp = await getTemporaryDirectory();
      final file = File('${temp.path}/my_vape_setup.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(
          files: [XFile(file.path)],
          text: 'Cek racikan andalanku untuk ${config.liquidName}!'));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal membuat poster: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final scheme = context.scheme;
    final tags = config.flavorTags.take(3).toList();

    return Dismissible(
      key: ValueKey('dismiss_${config.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration:
            BoxDecoration(color: t.warning, borderRadius: Rd.cardR),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Sp.xxl),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.archive_rounded, color: scheme.surface, size: 28),
          const SizedBox(height: Sp.xs),
          Text('Arsip',
              style: context.text.labelLarge?.copyWith(color: scheme.surface)),
        ]),
      ),
      onDismissed: (_) {
        context.read<PodProvider>().archiveConfig(config.id);
        showActionAnimation(
            context, 'Disimpan ke Arsip', Icons.inventory_2_rounded, t.warning);
      },
      child: PressScale(
        child: AppCard(
          padding: EdgeInsets.zero,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddConfigScreen(configToEdit: config)));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: GestureDetector(
                  onTap: config.imagePath == null
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => FullScreenImageView(
                                      heroTag: config.id,
                                      imagePath: config.imagePath!)));
                        },
                  child: Hero(
                    tag: config.id,
                    child: ColoredBox(
                      color: t.surfaceRaised,
                      child: config.imagePath == null
                          ? Center(
                              child: Icon(Icons.water_drop_outlined,
                                  size: 40, color: t.textSecondary))
                          : StoragePhoto(
                              value: config.imagePath!, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Sp.l, Sp.m, Sp.xs, Sp.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(config.liquidName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.titleMedium),
                            const SizedBox(height: 2),
                            Text(config.deviceName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.bodySmall
                                    ?.copyWith(fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Bagikan setup',
                        icon: const Icon(Icons.ios_share_rounded, size: 20),
                        color: t.textSecondary,
                        onPressed: () => _share(context),
                      ),
                    ]),
                    const SizedBox(height: Sp.s),
                    Padding(
                      padding: const EdgeInsets.only(right: Sp.l),
                      child: Wrap(spacing: Sp.s, runSpacing: Sp.s, children: [
                        StatPill('${config.resistance} Ω'),
                        StatPill('${config.optimalWattage} W'),
                        if (config.airflowLevel.isNotEmpty)
                          StatPill(config.airflowLevel,
                              icon: Icons.air_rounded),
                      ]),
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: Sp.s),
                      Wrap(spacing: Sp.s, runSpacing: Sp.s, children: [
                        for (final tag in tags)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Sp.s, vertical: Sp.xs),
                            decoration: BoxDecoration(
                                color: t.accentSoft,
                                borderRadius: Rd.chipR),
                            child: Text(tag,
                                style: context.text.labelMedium?.copyWith(
                                    fontSize: 12, color: scheme.primary)),
                          ),
                      ]),
                    ],
                    const SizedBox(height: Sp.m),
                    Padding(
                      padding: const EdgeInsets.only(right: Sp.l),
                      child: Row(children: [
                        RatingStars(config.flavorRating),
                        const Spacer(),
                        if (config.price > 0)
                          Text(formatRupiah(config.price),
                              style: context.text.titleSmall?.copyWith(
                                  fontFeatures: AppTokens.tabular)),
                      ]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FullScreenImageView extends StatelessWidget {
  final String heroTag;
  final String imagePath;
  const FullScreenImageView(
      {super.key, required this.heroTag, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.dark.textPrimary,
        iconTheme: IconThemeData(color: AppColors.dark.textPrimary),
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: Rd.fieldR,
              child: StoragePhoto(value: imagePath, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
