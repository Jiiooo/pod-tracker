import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/pod_provider.dart';

class StatsView extends StatefulWidget {
  const StatsView({super.key});
  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Consumer<PodProvider>(
      builder: (context, provider, child) {
        final configs = provider.configs;
        if (configs.isEmpty) {
          return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_graph_rounded, size: 80, color: primaryColor.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('Belum Cukup Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Text('Statistik akan muncul setelah kamu\nmenambahkan liquid pertamamu.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
                ],
              )
          );
        }

        // --- ALGORITMA PREDIKSI KEUANGAN ---
        double projectedExpense = 0;
        if (configs.isNotEmpty) {
          DateTime firstDate = DateTime.now();
          for (var c in configs) {
            if (c.dateStarted.isBefore(firstDate)) firstDate = c.dateStarted;
          }
          int totalDays = DateTime.now().difference(firstDate).inDays;
          if (totalDays < 1) totalDays = 1;

          if (totalDays < 7) {
            double avgPricePerItem = provider.totalExpense / configs.length;
            projectedExpense = avgPricePerItem * 2;
          } else {
            projectedExpense = (provider.totalExpense / totalDays) * 30;
          }
        }

        // --- PENGOLAHAN DATA GRAFIK ---
        final Map<String, double> expensesMap = {};
        final List<String> monthKeys = [];
        final Map<String, double> tagCounts = {'Fruity': 0, 'Creamy': 0, 'Mint': 0, 'Tobacco': 0, 'Pastry': 0, 'Beverage': 0};
        final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];

        // Data untuk Trend Line Chart
        List<FlSpot> trendSpots = [];
        var sortedConfigs = List.of(configs)..sort((a, b) => a.dateStarted.compareTo(b.dateStarted));

        for (int i = 0; i < sortedConfigs.length; i++) {
          final c = sortedConfigs[i];
          final key = "${months[c.dateStarted.month]} '${c.dateStarted.year.toString().substring(2)}";

          if (!expensesMap.containsKey(key)) { monthKeys.add(key); expensesMap[key] = 0; }
          expensesMap[key] = expensesMap[key]! + c.price;

          for (var tag in c.flavorTags) { if (tagCounts.containsKey(tag)) tagCounts[tag] = tagCounts[tag]! + 1; }

          // Memasukkan data harga (dalam ribuan) berdasarkan urutan waktu
          trendSpots.add(FlSpot(i.toDouble(), c.price / 1000));
        }

        return Stack(
          children: [
            AnimatedBuilder(
              animation: _scrollController,
              builder: (context, child) {
                double offset = _scrollController.hasClients ? _scrollController.offset : 0;
                return Positioned(
                  top: -offset * 0.4, right: -50,
                  child: Opacity(opacity: isDark ? 0.03 : 0.05, child: Icon(Icons.bar_chart_rounded, size: 450, color: primaryColor)),
                );
              },
            ),

            ListView(
              controller: _scrollController, physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 90.0),
              children: [
                Row(
                  children: [
                    Expanded(child: _buildDashboardCard(context, 'Total Investasi', provider.totalExpense, Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.onPrimaryContainer)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDashboardCard(context, 'Prediksi Bulan Depan', projectedExpense, isDark ? Colors.orange.withOpacity(0.2) : Colors.orange.shade50, Colors.orange.shade700)),
                  ],
                ),

                const SizedBox(height: 32),

                // --- FITUR BARU: GRAFIK TREN HARGA (LINE CHART) ---
                if (trendSpots.length > 1) ...[
                  _buildTrendChart(context, trendSpots, isDark),
                  const SizedBox(height: 32),
                ],

                _buildRadarChart(context, tagCounts),
                const SizedBox(height: 32),
                _buildBarChart(monthKeys, expensesMap),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrendChart(BuildContext context, List<FlSpot> spots, bool isDark) {
    // Warna hijau neon untuk memberikan nuansa grafik teknikal
    final lineColor = Colors.greenAccent.shade400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📈 Tren Harga Liquid', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Pergerakan harga belimu dari waktu ke waktu', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.only(right: 24, left: 8, top: 24, bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            boxShadow: [isDark ? const BoxShadow(color: Colors.transparent) : BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 50, // Garis horizontal setiap selisih Rp 50.000
                getDrawingHorizontalLine: (value) => FlLine(color: isDark ? Colors.white10 : Colors.black12, strokeWidth: 1, dashArray: [5, 5]),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text('${value.toInt()}k', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: lineColor,
                  barWidth: 3.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: isDark ? Colors.grey.shade900 : Colors.white, strokeWidth: 2, strokeColor: lineColor),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [lineColor.withOpacity(0.3), lineColor.withOpacity(0.0)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) => LineTooltipItem('Rp ${spot.y.toInt()}K', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title, double value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor.withOpacity(0.8))),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: value), duration: const Duration(seconds: 2), curve: Curves.easeOutCubic,
            builder: (context, val, child) => Text('Rp ${(val/1000).toStringAsFixed(0)}K', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarChart(BuildContext context, Map<String, double> tagCounts) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4), borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          const Text('🕸️ Analisis Profil Rasa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Kecenderungan lidahmu', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 30),
          SizedBox(
            height: 250,
            child: RadarChart(
              RadarChartData(
                dataSets: [RadarDataSet(fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.4), borderColor: Theme.of(context).colorScheme.primary, entryRadius: 4, dataEntries: tagCounts.values.map((v) => RadarEntry(value: v)).toList())],
                radarBackgroundColor: Colors.transparent, borderData: FlBorderData(show: false),
                radarBorderData: const BorderSide(color: Colors.grey, width: 1.5), titlePositionPercentageOffset: 0.15,
                getTitle: (i, angle) => RadarChartTitle(text: tagCounts.keys.elementAt(i), angle: angle),
                titleTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                tickCount: 4, ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 10),
                tickBorderData: BorderSide(color: Colors.grey.shade400, width: 1), gridBorderData: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
              swapAnimationDuration: const Duration(milliseconds: 800), swapAnimationCurve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<String> monthKeys, Map<String, double> expensesMap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📊 Pengeluaran Bulanan (Rp)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: monthKeys.asMap().entries.map((entry) => BarChartGroupData(
                x: entry.key, barRods: [BarChartRodData(toY: expensesMap[entry.value]! / 1000, color: Colors.redAccent, width: 24, borderRadius: BorderRadius.circular(6))],
              )).toList(),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) => Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(monthKeys[val.toInt()], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))))),
              ),
            ),
          ),
        ),
      ],
    );
  }
}