import 'dart:convert';
import 'dart:math';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salestrack_web/core/firestore_providers.dart';
import 'package:salestrack_web/core/theme.dart';
import 'package:salestrack_web/shared/top_nav_bar.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedPeriod = 'Today';

  @override
  void initState() {
    super.initState();
    _applyPeriodFilter();
  }

  void _applyPeriodFilter() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTimeRange? range;

    switch (_selectedPeriod) {
      case 'Today':
        range = DateTimeRange(start: today, end: today);
      case 'Last 7 Days':
        range = DateTimeRange(
            start: today.subtract(const Duration(days: 6)), end: today);
      case 'Last 30 Days':
        range = DateTimeRange(
            start: today.subtract(const Duration(days: 29)), end: today);
      case 'Custom':
        return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dateRangeFilterProvider.notifier).state = range;
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange: ref.read(dateRangeFilterProvider) ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
    );
    if (picked != null) {
      setState(() => _selectedPeriod = 'Custom');
      ref.read(dateRangeFilterProvider.notifier).state = picked;
    }
  }

  void _exportCsv() {
    final calls = ref.read(filteredCallsProvider);
    if (calls.isEmpty) return;

    final buf = StringBuffer();
    buf.writeln('Date,Executive,Phone,Direction,Duration (sec),Status');
    for (final c in calls) {
      final ts = c['timestamp'];
      String date = '';
      if (ts is Timestamp) {
        final dt = ts.toDate();
        date =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      final exec = c['executiveId'] as String? ?? '';
      final phone = c['phoneNumber'] as String? ?? '';
      final dir = c['direction'] as String? ?? '';
      final dur = c['duration'] as int? ?? 0;
      final status = c['status'] as String? ?? '';
      buf.writeln('"$date","$exec","$phone","$dir",$dur,"$status"');
    }

    final bytes = utf8.encode(buf.toString());
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'salestrack_calls_export.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final kpi = ref.watch(filteredKpiProvider);
    final calls = ref.watch(filteredCallsProvider);
    final execKpis = ref.watch(perExecutiveKpiProvider);

    return Column(
      children: [
        const TopNavBar(
          title: 'Reports & Analytics',
          searchHint: 'Search reports...',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ANALYTICS',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Performance Reports',
                          style: GoogleFonts.inter(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.onSurface
                                    .withValues(alpha: 0.04),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedPeriod,
                              isDense: true,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurfaceVariant,
                              ),
                              items: [
                                'Today',
                                'Last 7 Days',
                                'Last 30 Days',
                                'Custom'
                              ]
                                  .map((e) => DropdownMenuItem(
                                      value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (v) {
                                setState(() => _selectedPeriod = v!);
                                if (v == 'Custom') {
                                  _pickDateRange();
                                } else {
                                  _applyPeriodFilter();
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: calls.isEmpty ? null : _exportCsv,
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Export CSV'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // KPI Summary row
                _buildKpiRow(kpi),
                const SizedBox(height: 32),

                // Charts row
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 900) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _DailyTrendChart(calls: calls),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: _ExecutiveComparisonChart(
                                execKpis: execKpis),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _DailyTrendChart(calls: calls),
                        const SizedBox(height: 32),
                        _ExecutiveComparisonChart(execKpis: execKpis),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Call log table
                _CallLogTable(calls: calls),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiRow(Map<String, dynamic> kpi) {
    final kpis = [
      ('Total Calls', '${kpi['totalCalls']}', Icons.call),
      ('Incoming', '${kpi['incoming']}', Icons.call_received),
      ('Outgoing', '${kpi['outgoing']}', Icons.call_made),
      ('Missed', '${kpi['missed']}', Icons.call_missed),
      ('Avg Duration', '${kpi['avgDuration']}', Icons.timer),
      ('Talk Time', '${kpi['talkTime']}', Icons.access_time),
      ('Unique Contacts', '${kpi['uniqueContacts']}', Icons.contacts),
      ('Peak Hour', '${kpi['peakHour']}', Icons.schedule),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisExtent: 100,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, i) {
        final (label, value, icon) = kpis[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.04),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Daily call trend line chart.
class _DailyTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> calls;

  const _DailyTrendChart({required this.calls});

  @override
  Widget build(BuildContext context) {
    // Group calls by date
    final Map<String, _DayStats> byDate = {};
    for (final c in calls) {
      final ts = c['timestamp'];
      if (ts is! Timestamp) continue;
      final dt = ts.toDate();
      final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      byDate.putIfAbsent(key, () => _DayStats());
      byDate[key]!.total++;
      if (c['direction'] == 'incoming') {
        byDate[key]!.incoming++;
      } else {
        byDate[key]!.outgoing++;
      }
    }

    final sortedDates = byDate.keys.toList()..sort();
    final displayDates = sortedDates.length > 30
        ? sortedDates.sublist(sortedDates.length - 30)
        : sortedDates;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Call Trends',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Incoming vs Outgoing calls over time',
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            children: [
              _LegendDot(color: AppColors.primary, label: 'Incoming'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.secondary, label: 'Outgoing'),
              const SizedBox(width: 16),
              _LegendDot(
                  color: AppColors.onSurfaceVariant, label: 'Total'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: displayDates.isEmpty
                ? Center(
                    child: Text(
                      'No data for selected period',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.outline),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _calcInterval(displayDates, byDate),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.surfaceContainer,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.onSurfaceVariant),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: max(1, displayDates.length / 6)
                                .roundToDouble(),
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= displayDates.length) {
                                return const SizedBox.shrink();
                              }
                              final parts = displayDates[idx].split('-');
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '${parts[1]}/${parts[2]}',
                                  style: GoogleFonts.inter(
                                      fontSize: 9,
                                      color: AppColors.onSurfaceVariant),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        // Total
                        _buildLine(
                          displayDates,
                          byDate,
                          (s) => s.total.toDouble(),
                          AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                          isDashed: true,
                        ),
                        // Incoming
                        _buildLine(
                          displayDates,
                          byDate,
                          (s) => s.incoming.toDouble(),
                          AppColors.primary,
                        ),
                        // Outgoing
                        _buildLine(
                          displayDates,
                          byDate,
                          (s) => s.outgoing.toDouble(),
                          AppColors.secondary,
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (spots) => spots.map((spot) {
                            return LineTooltipItem(
                              '${spot.y.toInt()}',
                              GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: spot.bar.color ?? Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  double _calcInterval(
      List<String> dates, Map<String, _DayStats> byDate) {
    if (dates.isEmpty) return 1;
    final maxVal = dates
        .map((d) => byDate[d]?.total ?? 0)
        .reduce((a, b) => a > b ? a : b);
    if (maxVal <= 5) return 1;
    return (maxVal / 4).ceilToDouble();
  }

  LineChartBarData _buildLine(
    List<String> dates,
    Map<String, _DayStats> byDate,
    double Function(_DayStats) getValue,
    Color color, {
    bool isDashed = false,
  }) {
    return LineChartBarData(
      spots: List.generate(dates.length, (i) {
        final stats = byDate[dates[i]]!;
        return FlSpot(i.toDouble(), getValue(stats));
      }),
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: isDashed ? 1.5 : 2.5,
      dashArray: isDashed ? [6, 4] : null,
      dotData: const FlDotData(show: false),
      belowBarData: isDashed
          ? BarAreaData(show: false)
          : BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.08),
            ),
    );
  }
}

class _DayStats {
  int total = 0;
  int incoming = 0;
  int outgoing = 0;
}

/// Executive comparison horizontal bar chart.
class _ExecutiveComparisonChart extends StatelessWidget {
  final List<Map<String, dynamic>> execKpis;

  const _ExecutiveComparisonChart({required this.execKpis});

  @override
  Widget build(BuildContext context) {
    final displayExecs = execKpis.take(8).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Executive Comparison',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Calls by executive',
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: max(220, displayExecs.length * 44.0),
            child: displayExecs.isEmpty
                ? Center(
                    child: Text(
                      'No executive data',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.outline),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: displayExecs.isEmpty
                          ? 10
                          : (displayExecs.first['totalCalls'] as int)
                                  .toDouble() *
                              1.2,
                      barGroups: List.generate(displayExecs.length, (i) {
                        final exec = displayExecs[i];
                        final incoming =
                            (exec['incoming'] as int? ?? 0).toDouble();
                        final outgoing =
                            (exec['outgoing'] as int? ?? 0).toDouble();
                        return BarChartGroupData(
                          x: i,
                          barsSpace: 2,
                          barRods: [
                            BarChartRodData(
                              toY: incoming,
                              width: 10,
                              color: AppColors.primary,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3)),
                            ),
                            BarChartRodData(
                              toY: outgoing,
                              width: 10,
                              color: AppColors.secondary,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3)),
                            ),
                          ],
                        );
                      }),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.surfaceContainer,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (value, _) => Text(
                              '${value.toInt()}',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.onSurfaceVariant),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= displayExecs.length) {
                                return const SizedBox.shrink();
                              }
                              final name =
                                  displayExecs[idx]['name'] as String? ?? '';
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  name.split(' ').first,
                                  style: GoogleFonts.inter(
                                      fontSize: 9,
                                      color: AppColors.onSurfaceVariant),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final exec = displayExecs[group.x];
                            return BarTooltipItem(
                              '${exec['name']}\n${exec['totalCalls']} calls',
                              GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _LegendDot(color: AppColors.primary, label: 'Incoming'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.secondary, label: 'Outgoing'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style:
              GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _CallLogTable extends StatelessWidget {
  final List<Map<String, dynamic>> calls;

  const _CallLogTable({required this.calls});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Call Log',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      '${calls.length} records',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          calls.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(48),
                  child: Text(
                    'No calls found for this period.',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.onSurfaceVariant),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      AppColors.surfaceContainerLow.withValues(alpha: 0.5),
                    ),
                    columnSpacing: 32,
                    horizontalMargin: 24,
                    dividerThickness: 0.5,
                    columns: [
                      _col('DATE'),
                      _col('EXECUTIVE'),
                      _col('PHONE'),
                      _col('DIRECTION'),
                      _col('DURATION'),
                      _col('STATUS'),
                    ],
                    rows: calls.map(_buildRow).toList(),
                  ),
                ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  DataColumn _col(String label) {
    return DataColumn(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
          color: AppColors.outline,
        ),
      ),
    );
  }

  DataRow _buildRow(Map<String, dynamic> call) {
    final ts = call['timestamp'];
    String date = '--';
    if (ts is Timestamp) {
      final dt = ts.toDate();
      date =
          '${_monthName(dt.month)} ${dt.day}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    final exec = call['executiveId'] as String? ?? 'Unknown';
    final phone = call['phoneNumber'] as String? ?? '--';
    final direction = call['direction'] as String? ?? '';
    final dirLabel = direction == 'incoming' ? 'IN' : 'OUT';
    final duration = call['duration'] as int? ?? 0;
    final durMin = duration ~/ 60;
    final durSec = duration % 60;
    final durStr =
        '${durMin.toString().padLeft(2, '0')}:${durSec.toString().padLeft(2, '0')}';
    final status = call['status'] as String? ?? 'recorded';

    return DataRow(cells: [
      DataCell(Text(date,
          style:
              GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500))),
      DataCell(Text(exec,
          style:
              GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
      DataCell(Text(phone,
          style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.onSurfaceVariant))),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: dirLabel == 'IN'
                ? const Color(0xFFEFF6FF)
                : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            dirLabel,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: dirLabel == 'IN'
                  ? const Color(0xFF2563EB)
                  : AppColors.primary,
            ),
          ),
        ),
      ),
      DataCell(Text(durStr, style: GoogleFonts.inter(fontSize: 12))),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: status == 'uploaded'
                ? const Color(0xFFD1FAE5)
                : const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            status.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: status == 'uploaded'
                  ? const Color(0xFF065F46)
                  : const Color(0xFF92400E),
            ),
          ),
        ),
      ),
    ]);
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}
