import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
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
        return; // Don't override custom range
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
                        // Period selector
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
