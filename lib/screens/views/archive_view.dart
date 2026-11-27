import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../providers/pod_provider.dart';
import '../../utils/ui_helpers.dart'; // Import animasi pop-up
import '../add_config_screen.dart';
import '../widgets/tag_filter_bar.dart';

class ArchiveView extends StatelessWidget {
  const ArchiveView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<PodProvider>(
      builder: (context, provider, child) {
        final archived = provider.archivedConfigs;

        Widget body;
        if (archived.isEmpty) {
          body = Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.network(
                    'https://lottie.host/17eb60c5-1153-41c3-88c9-83c34e7bb451/DkIXX1zQ8m.json',
                    width: 200, height: 200,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.inventory_2_outlined, size: 80, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                  ),
                  Text('Arsip Kosong', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Text('Liquid yang kamu arsipkan dari Tracker\nakan tersimpan aman di sini.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
                ],
              )
          );
        } else {
          body = ListView.builder(
          itemCount: archived.length,
          padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 100),
          itemBuilder: (ctx, i) {
            final config = archived[i];
            return Card(
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6), margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Icons.history_rounded, color: Colors.amber)),
                title: Text(config.liquidName, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${config.deviceName} • Rp ${config.price.toStringAsFixed(0)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(tooltip: 'Pakai lagi', icon: const Icon(Icons.content_copy_rounded, color: Colors.blue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddConfigScreen(prefillFrom: config)))),
                    IconButton(icon: const Icon(Icons.restore_rounded, color: Colors.green), onPressed: () { provider.restoreConfig(config.id); showActionAnimation(context, 'Data Dikembalikan!', Icons.restore_rounded, Colors.green); }),
                    IconButton(icon: const Icon(Icons.delete_forever_rounded, color: Colors.red), onPressed: () => showDialog(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Konfirmasi Hapus'), content: Text('Hapus "${config.liquidName}" permanen?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')), ElevatedButton(onPressed: () { Navigator.pop(ctx); provider.deleteConfig(config.id); showActionAnimation(context, 'Dihapus Permanen', Icons.delete_outline_rounded, Colors.red); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, elevation: 0), child: const Text('Hapus'))]))),
                  ],
                ),
              ),
            );
          },
        );
        }

        return Column(children: [const TagFilterBar(), Expanded(child: body)]);
      },
    );
  }
}