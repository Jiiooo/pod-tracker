import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pod_config.dart';
import '../../providers/pod_provider.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_tokens.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/app_widgets.dart';
import '../add_config_screen.dart';
import '../widgets/tag_filter_bar.dart';

class ArchiveView extends StatelessWidget {
  const ArchiveView({super.key});

  @override
  Widget build(BuildContext context) {
    final archived = context
        .select<PodProvider, List<PodConfig>>((p) => p.archivedConfigs);

    final Widget body = archived.isEmpty
        ? const EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Arsip kosong',
            message: 'Pod yang kamu arsipkan dari Tracker tersimpan aman di sini.',
          )
        : ListView.builder(
            itemCount: archived.length,
            padding: const EdgeInsets.fromLTRB(Sp.l, Sp.s, Sp.l, Sp.l),
            itemBuilder: (ctx, i) => Padding(
              padding: const EdgeInsets.only(bottom: Sp.s),
              child: _ArchiveTile(
                  key: ValueKey(archived[i].id), config: archived[i]),
            ),
          );

    return Column(children: [const TagFilterBar(), Expanded(child: body)]);
  }
}

class _ArchiveTile extends StatelessWidget {
  final PodConfig config;
  const _ArchiveTile({super.key, required this.config});

  void _confirmDelete(BuildContext context) {
    final provider = context.read<PodProvider>();
    final t = context.tokens;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus permanen?'),
        content: Text('"${config.liquidName}" akan dihapus dan tidak bisa dikembalikan.'),
        actions: [
          TextButton(
              style: TextButton.styleFrom(foregroundColor: t.textSecondary),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: t.danger),
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteConfig(config.id);
              showActionAnimation(context, 'Dihapus permanen',
                  Icons.delete_outline_rounded, t.danger);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final provider = context.read<PodProvider>();
    final subtitle = [
      config.deviceName,
      if (config.price > 0) formatRupiah(config.price),
    ].join(' • ');
    return AppCard(
      padding: const EdgeInsets.only(left: Sp.l, top: Sp.xs, bottom: Sp.xs),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(config.liquidName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall),
              const SizedBox(height: 2),
              Text(subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                      fontSize: 13, fontFeatures: AppTokens.tabular)),
              const SizedBox(height: Sp.xs),
              RatingStars(config.flavorRating, size: 14),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Pakai lagi',
          icon: const Icon(Icons.content_copy_rounded, size: 20),
          color: context.scheme.primary,
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddConfigScreen(prefillFrom: config))),
        ),
        IconButton(
          tooltip: 'Kembalikan ke Tracker',
          icon: const Icon(Icons.unarchive_rounded, size: 20),
          color: t.success,
          onPressed: () {
            provider.restoreConfig(config.id);
            showActionAnimation(context, 'Data dikembalikan!',
                Icons.unarchive_rounded, t.success);
          },
        ),
        IconButton(
          tooltip: 'Hapus permanen',
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
          color: t.danger,
          onPressed: () => _confirmDelete(context),
        ),
      ]),
    );
  }
}
