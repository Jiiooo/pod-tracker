import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pod_provider.dart';

/// Baris FilterChip tag rasa (disembunyikan bila belum ada tag).
class TagFilterBar extends StatelessWidget {
  const TagFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PodProvider>();
    final tags = provider.availableTags;
    if (tags.isEmpty) return const SizedBox.shrink();
    final selected = provider.selectedTags.map((t) => t.toLowerCase()).toSet();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Semua'),
              selected: selected.isEmpty,
              onSelected: (_) => provider.clearTagFilter(),
            ),
          ),
          for (final t in tags)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(t),
                selected: selected.contains(t.toLowerCase()),
                onSelected: (_) => provider.toggleTag(t),
              ),
            ),
        ],
      ),
    );
  }
}
