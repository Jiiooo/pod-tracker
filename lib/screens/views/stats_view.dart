import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pod_config.dart';
import '../../providers/pod_provider.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/app_widgets.dart';

const _tagKeys = ['Fruity', 'Creamy', 'Mint', 'Tobacco', 'Pastry', 'Beverage'];
const _months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];

class StatsView extends StatelessWidget {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final all =
        context.select<PodProvider, List<PodConfig>>((p) => p.configs);
    final configs = all.where((c) => !c.isDeleted).toList();

    if (configs.isEmpty) {
      return const EmptyState(
        icon: Icons.insights_rounded,
        title: 'Belum cukup data',
        message: 'Statistik muncul setelah kamu menambahkan pod pertamamu.',
      );
    }

    final total = configs.fold<double>(0, (s, c) => s + c.price);
    final active = configs.where((c) => c.isStillActive).length;
    final rated = configs.where((c) => c.flavorRating > 0).toList();
    final avgRating = rated.isEmpty
        ? 0.0
        : rated.fold<double>(0, (s, c) => s + c.flavorRating) / rated.length;

    // Prediksi pengeluaran bulan depan.
    var first = DateTime.now();
    for (final c in configs) {
      if (c.dateStarted.isBefore(first)) first = c.dateStarted;
    }
    var days = DateTime.now().difference(first).inDays;
    if (days < 1) days = 1;
    final projected =
        days < 7 ? (total / configs.length) * 2 : (total / days) * 30;

    final sorted = List<PodConfig>.of(configs)
      ..sort((a, b) => a.dateStarted.compareTo(b.dateStarted));
    final expenses = <String, double>{};
    final tagCounts = {for (final k in _tagKeys) k: 0.0};
    final spots = <FlSpot>[];
    for (var i = 0; i < sorted.length; i++) {
      final c = sorted[i];
      final key =
          "${_months[c.dateStarted.month]} '${c.dateStarted.year.toString().substring(2)}";
      expenses[key] = (expenses[key] ?? 0) + c.price;
      for (final tag in c.flavorTags) {
        if (tagCounts.containsKey(tag)) tagCounts[tag] = tagCounts[tag]! + 1;
      }
      spots.add(FlSpot(i.toDouble(), c.price / 1000));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(Sp.l, Sp.s, Sp.l, Sp.xxl),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: Sp.m,
          crossAxisSpacing: Sp.m,
          childAspectRatio: 1.45,
          children: [
            _StatTile(
                label: 'Total pod',
                value: '${configs.length}',
                icon: Icons.water_drop_outlined),
            _StatTile(
                label: 'Pod aktif',
                value: '$active',
                icon: Icons.bolt_rounded),
            _StatTile(
                label: 'Total pengeluaran',
                value: formatRupiah(total),
                icon: Icons.payments_outlined),
            _StatTile(
                label: 'Rata-rata rating',
                value: avgRating.toStringAsFixed(1),
                icon: Icons.star_rounded),
          ],
        ),
        const SizedBox(height: Sp.m),
        AppCard(
          child: Row(children: [
            Icon(Icons.trending_up_rounded,
                color: context.tokens.textSecondary),
            const SizedBox(width: Sp.m),
            Expanded(
                child: Text('Prediksi bulan depan',
                    style: context.text.labelLarge)),
            Text(formatRupiah(projected),
                style: context.text.titleSmall
                    ?.copyWith(fontFeatures: AppTokens.tabular)),
          ]),
        ),
        const SizedBox(height: Sp.xxl),
        if (spots.length > 1) ...[
          _ChartCard(
            title: 'Tren harga',
            subtitle: 'Harga beli dari waktu ke waktu (ribu rupiah)',
            height: 220,
            child: _TrendChart(spots: spots),
          ),
          const SizedBox(height: Sp.l),
        ],
        _ChartCard(
          title: 'Profil rasa',
          subtitle: 'Kecenderungan lidahmu',
          height: 250,
          child: _TasteRadar(tagCounts: tagCounts),
        ),
        const SizedBox(height: Sp.l),
        _ChartCard(
          title: 'Pengeluaran bulanan',
          subtitle: 'Dalam ribu rupiah',
          height: 200,
          child: _MonthlyBars(
              keys: expenses.keys.toList(), values: expenses),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatTile(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: context.scheme.primary),
            const SizedBox(width: Sp.s),
            Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall)),
          ]),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: context.text.displayMedium?.copyWith(
                    fontSize: 28,
                    fontFeatures: AppTokens.tabular)),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double height;
  final Widget child;
  const _ChartCard(
      {required this.title,
      required this.subtitle,
      required this.height,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(Sp.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.headlineSmall),
          const SizedBox(height: Sp.xs),
          Text(subtitle, style: context.text.bodySmall),
          const SizedBox(height: Sp.l),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}

TextStyle _axisStyle(BuildContext context) =>
    context.text.labelSmall!.copyWith(fontSize: 11);

class _TrendChart extends StatelessWidget {
  final List<FlSpot> spots;
  const _TrendChart({required this.spots});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final accent = context.scheme.primary;
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: t.outline, strokeWidth: 1, dashArray: [4, 4]),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) =>
                  Text('${v.toInt()}k', style: _axisStyle(context)),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: accent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              getDotPainter: (a, b, c, d) => FlDotCirclePainter(
                  radius: 3.5,
                  color: context.scheme.surface,
                  strokeWidth: 2,
                  strokeColor: accent),
            ),
            belowBarData: BarAreaData(show: true, color: t.accentSoft),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => t.surfaceRaised,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem('Rp ${s.y.toInt()}K',
                    context.text.labelLarge!))
                .toList(),
          ),
        ),
      ),
      duration: Motion.of(context, Motion.normal),
      curve: Motion.curve,
    );
  }
}

class _TasteRadar extends StatelessWidget {
  final Map<String, double> tagCounts;
  const _TasteRadar({required this.tagCounts});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final accent = context.scheme.primary;
    final grid = BorderSide(color: t.outline, width: 1);
    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            fillColor: t.accentSoft,
            borderColor: accent,
            borderWidth: 2,
            entryRadius: 3,
            dataEntries:
                tagCounts.values.map((v) => RadarEntry(value: v)).toList(),
          ),
        ],
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        radarBorderData: grid,
        titlePositionPercentageOffset: 0.15,
        getTitle: (i, angle) =>
            RadarChartTitle(text: tagCounts.keys.elementAt(i), angle: angle),
        titleTextStyle:
            context.text.labelMedium!.copyWith(color: t.textSecondary),
        tickCount: 4,
        ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 10),
        tickBorderData: grid,
        gridBorderData: grid,
      ),
      duration: Motion.of(context, const Duration(milliseconds: 600)),
      curve: Motion.curve,
    );
  }
}

class _MonthlyBars extends StatelessWidget {
  final List<String> keys;
  final Map<String, double> values;
  const _MonthlyBars({required this.keys, required this.values});

  @override
  Widget build(BuildContext context) {
    final accent = context.scheme.primary;
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < keys.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: values[keys[i]]! / 1000,
                color: accent,
                width: 20,
                borderRadius: BorderRadius.circular(6),
              ),
            ]),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: Sp.s),
                child: Text(keys[v.toInt()], style: _axisStyle(context)),
              ),
            ),
          ),
        ),
      ),
      duration: Motion.of(context, Motion.normal),
      curve: Motion.curve,
    );
  }
}
