import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salestrack_web/core/firestore_providers.dart';
import 'package:salestrack_web/core/theme.dart';
import 'package:salestrack_web/shared/top_nav_bar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const TopNavBar(
          title: 'Dashboard',
          searchHint: 'Search calls, agents or metrics...',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI Bento Grid - 2 rows of 4
                _buildKpiGrid(ref),
                const SizedBox(height: 32),

                // Charts row: Quality Performance (2/3) + Sentiment & Outcomes (1/3)
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 900) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _QualityPerformanceChart()),
                          const SizedBox(width: 32),
                          Expanded(
                            child: Column(
                              children: [
                                _SentimentDonutCard(),
                                const SizedBox(height: 32),
                                _CallOutcomesCard(),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _QualityPerformanceChart(),
                        const SizedBox(height: 32),
                        _SentimentDonutCard(),
                        const SizedBox(height: 32),
                        _CallOutcomesCard(),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Bottom row: Top Performers (1/4) + Live Call Feed (3/4)
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 1000) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(width: 280, child: _TopPerformersCard()),
                          const SizedBox(width: 32),
                          Expanded(child: _LiveCallFeedTable()),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        const _TopPerformersCard(),
                        const SizedBox(height: 32),
                        _LiveCallFeedTable(),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiGrid(WidgetRef ref) {
    final agg = ref.watch(aggregatedKpiProvider);
    final kpis = [
      _KpiData('Total Calls', '${agg['totalCalls']}', 'Live', Icons.call, const Color(0xFFECFDF5), AppColors.primary, true),
      _KpiData('Incoming', '${agg['incoming']}', 'IN', Icons.call_received, const Color(0xFFEFF6FF), const Color(0xFF2563EB), true),
      _KpiData('Outgoing', '${agg['outgoing']}', 'OUT', Icons.call_made, const Color(0xFFFFF7ED), AppColors.secondary, true),
      _KpiData('Missed', '${agg['missed']}', '<5s', Icons.call_missed, const Color(0xFFFEF2F2), AppColors.tertiary, false),
      _KpiData('Avg Duration', '${agg['avgDuration']}', 'Optimal', Icons.timer, AppColors.surfaceContainerHigh, AppColors.onSurface, null),
      _KpiData('Talk Time', '${agg['talkTime']}', 'Total', Icons.access_time, const Color(0xFFFAF5FF), const Color(0xFF7C3AED), true),
      _KpiData('Unique Contacts', '${agg['uniqueContacts']}', 'Distinct', Icons.contacts, const Color(0xFFFDF2F8), const Color(0xFFDB2777), true),
      _KpiData('Peak Hour', '${agg['peakHour']}', 'Busiest', Icons.schedule, const Color(0xFFFFF7ED), const Color(0xFFEA580C), null),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        mainAxisExtent: 150,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, i) => _KpiCard(data: kpis[i]),
    );
  }
}

class _KpiData {
  final String label;
  final String value;
  final String badge;
  final IconData icon;
  final Color iconBg;
  final Color accent;
  final bool? isPositive;

  const _KpiData(this.label, this.value, this.badge, this.icon, this.iconBg, this.accent, this.isPositive);
}

class _KpiCard extends StatefulWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: _hovering
            ? (Matrix4.identity()..translateByDouble(0, -2, 0, 0))
            : Matrix4.identity(),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.data.iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(widget.data.icon, size: 20, color: widget.data.accent),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.data.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    widget.data.badge,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.data.accent,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              widget.data.label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.data.value,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quality chart now shows per-executive call counts as bars.
class _QualityPerformanceChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execKpis = ref.watch(perExecutiveKpiProvider);
    final displayExecs = execKpis.take(10).toList();
    final maxCalls = displayExecs.isEmpty
        ? 1
        : displayExecs.map((e) => e['totalCalls'] as int).reduce(max);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calls by Executive',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    'Real-time call volume per agent',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'Live',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (displayExecs.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'No call data yet',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.outline),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < displayExecs.length; i++) ...[
                    Expanded(
                      child: _ChartBar(
                        heightFraction: maxCalls > 0
                            ? (displayExecs[i]['totalCalls'] as int) / maxCalls
                            : 0,
                        isHighlighted: i == 0,
                        label: i == 0
                            ? '${displayExecs[i]['totalCalls']} calls'
                            : null,
                        tooltip: displayExecs[i]['name'] as String? ?? '',
                      ),
                    ),
                    if (i < displayExecs.length - 1) const SizedBox(width: 4),
                  ],
                ],
              ),
            ),
          if (displayExecs.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 20,
              child: Row(
                children: [
                  for (var i = 0; i < displayExecs.length; i++) ...[
                    Expanded(
                      child: Text(
                        (displayExecs[i]['name'] as String? ?? '').split(' ').first,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 9, color: AppColors.onSurfaceVariant),
                      ),
                    ),
                    if (i < displayExecs.length - 1) const SizedBox(width: 4),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  final double heightFraction;
  final bool isHighlighted;
  final String? label;
  final String? tooltip;

  const _ChartBar({
    required this.heightFraction,
    this.isHighlighted = false,
    this.label,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (label != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.onSurface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label!,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          Flexible(
            child: FractionallySizedBox(
              heightFactor: heightFraction.clamp(0.05, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: isHighlighted
                      ? const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [AppColors.primary, AppColors.primaryContainer],
                        )
                      : null,
                  color: isHighlighted ? null : AppColors.primary.withValues(alpha: heightFraction * 0.5 + 0.15),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  boxShadow: isHighlighted
                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 12)]
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sentiment donut computed from call durations (short=negative, medium=neutral, long=positive).
class _SentimentDonutCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agg = ref.watch(aggregatedKpiProvider);
    final total = agg['totalCalls'] as int? ?? 0;
    final missed = agg['missed'] as int? ?? 0;
    final incoming = agg['incoming'] as int? ?? 0;
    final outgoing = agg['outgoing'] as int? ?? 0;

    // Use call direction breakdown as the donut: incoming / outgoing / missed
    final inPct = total > 0 ? (incoming / total * 100).round() : 0;
    final outPct = total > 0 ? (outgoing / total * 100).round() : 0;
    final missedPct = total > 0 ? (missed / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Call Breakdown',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _DonutPainter(
                    incomingPct: total > 0 ? incoming / total : 0,
                    outgoingPct: total > 0 ? outgoing / total : 0,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$total',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          'TOTAL',
                          style: GoogleFonts.inter(
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendItem(color: AppColors.primary, label: 'Incoming ($inPct%)'),
                    const SizedBox(height: 8),
                    _LegendItem(color: AppColors.secondary, label: 'Outgoing ($outPct%)'),
                    const SizedBox(height: 8),
                    _LegendItem(color: AppColors.tertiary, label: 'Missed ($missedPct%)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double incomingPct;
  final double outgoingPct;

  _DonutPainter({required this.incomingPct, required this.outgoingPct});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 12.0;
    const startAngle = -1.5708; // -pi/2
    const fullCircle = 2 * 3.14159;

    final bgPaint = Paint()
      ..color = AppColors.surfaceContainer
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    if (incomingPct > 0) {
      final inPaint = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        fullCircle * incomingPct,
        false,
        inPaint,
      );
    }

    if (outgoingPct > 0) {
      final outPaint = Paint()
        ..color = AppColors.secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + fullCircle * incomingPct,
        fullCircle * outgoingPct,
        false,
        outPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.incomingPct != incomingPct || oldDelegate.outgoingPct != outgoingPct;
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

/// Call outcomes now shows real call status breakdown from Firestore.
class _CallOutcomesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calls = ref.watch(callsStreamProvider).valueOrNull ?? [];
    final total = calls.length;
    final recorded = calls.where((c) => c['status'] == 'recorded').length;
    final uploaded = calls.where((c) => c['status'] == 'uploaded').length;
    final failed = calls.where((c) => c['status'] == 'failed').length;

    final recordedPct = total > 0 ? (recorded / total * 100).round() : 0;
    final uploadedPct = total > 0 ? (uploaded / total * 100).round() : 0;
    final failedPct = total > 0 ? (failed / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Call Status',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _OutcomeBar(label: 'Uploaded', pct: uploadedPct, color: AppColors.primary),
          const SizedBox(height: 16),
          _OutcomeBar(label: 'Recorded', pct: recordedPct, color: AppColors.secondary),
          const SizedBox(height: 16),
          _OutcomeBar(label: 'Failed', pct: failedPct, color: AppColors.tertiary),
        ],
      ),
    );
  }
}

class _OutcomeBar extends StatelessWidget {
  final String label;
  final int pct;
  final Color color;
  const _OutcomeBar({required this.label, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              '$pct%',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 8,
            backgroundColor: AppColors.surfaceContainer,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

/// Top performers from real Firestore data, ranked by total calls.
class _TopPerformersCard extends ConsumerWidget {
  const _TopPerformersCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execKpis = ref.watch(perExecutiveKpiProvider);
    final topPerformers = execKpis.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Performers',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          if (topPerformers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No data yet',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.outline),
                ),
              ),
            )
          else
            for (var i = 0; i < topPerformers.length; i++) ...[
              _PerformerRow(
                rank: i + 1,
                name: topPerformers[i]['name'] as String? ?? 'Unknown',
                totalCalls: topPerformers[i]['totalCalls'] as int? ?? 0,
                maxCalls: topPerformers.first['totalCalls'] as int? ?? 1,
              ),
              if (i < topPerformers.length - 1) const SizedBox(height: 24),
            ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Text(
                'VIEW ALL AGENTS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformerRow extends StatelessWidget {
  final int rank;
  final String name;
  final int totalCalls;
  final int maxCalls;
  const _PerformerRow({required this.rank, required this.name, required this.totalCalls, required this.maxCalls});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: rank == 1
                ? AppColors.primaryContainer.withValues(alpha: 0.2)
                : AppColors.surfaceContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: rank == 1 ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    '$totalCalls calls',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: maxCalls > 0 ? totalCalls / maxCalls : 0,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceContainer,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiveCallFeedTable extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callsAsync = ref.watch(callsStreamProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Call Feed',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      'Real-time call activity',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_list, size: 16),
                      label: const Text('Filter'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide.none,
                        backgroundColor: AppColors.surfaceContainerLow,
                        foregroundColor: AppColors.onSurface,
                        textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Live Monitor'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 360,
              ),
              child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                AppColors.surfaceContainerLow.withValues(alpha: 0.5),
              ),
              headingRowHeight: 48,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 56,
              columnSpacing: 32,
              horizontalMargin: 24,
              dividerThickness: 0.5,
              columns: [
                _col('TIME'),
                _col('AGENT'),
                _col('PHONE'),
                _col('DIRECTION'),
                _col('DURATION'),
                _col('STATUS'),
              ],
              rows: _buildCallRows(callsAsync),
            ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<DataRow> _buildCallRows(AsyncValue<List<Map<String, dynamic>>> callsAsync) {
    final calls = callsAsync.valueOrNull ?? [];
    if (calls.isEmpty) {
      return [
        DataRow(cells: [
          DataCell(Text('--', style: GoogleFonts.inter(fontSize: 12, color: AppColors.outline))),
          DataCell(Text('No calls yet', style: GoogleFonts.inter(fontSize: 12, color: AppColors.outline))),
          DataCell(Text('--', style: GoogleFonts.inter(fontSize: 12, color: AppColors.outline))),
          DataCell(Text('--', style: GoogleFonts.inter(fontSize: 12, color: AppColors.outline))),
          DataCell(Text('--', style: GoogleFonts.inter(fontSize: 12, color: AppColors.outline))),
          DataCell(Text('--', style: GoogleFonts.inter(fontSize: 12, color: AppColors.outline))),
        ]),
      ];
    }

    return calls.take(10).map((call) {
      final ts = call['timestamp'];
      String timeStr = '--';
      if (ts is Timestamp) {
        final d = ts.toDate();
        timeStr = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
      }

      final direction = call['direction'] as String? ?? 'unknown';
      final isIncoming = direction == 'incoming';
      final durSec = call['duration'] as int? ?? 0;
      final m = durSec ~/ 60;
      final s = durSec % 60;
      final durStr = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      final phone = call['phoneNumber'] as String? ?? 'Unknown';
      final status = call['status'] as String? ?? 'recorded';
      final execId = call['executiveId'] as String? ?? 'Unknown';

      final (statusBg, statusFg) = switch (status) {
        'uploaded' => (const Color(0xFFD1FAE5), const Color(0xFF065F46)),
        'uploading' => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
        'failed' => (const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
        _ => (AppColors.surfaceContainer, AppColors.onSurfaceVariant),
      };

      return DataRow(cells: [
        DataCell(Text(timeStr, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500))),
        DataCell(Text(execId, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700))),
        DataCell(Text(phone, style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isIncoming ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isIncoming ? 'IN' : 'OUT',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isIncoming ? const Color(0xFF2563EB) : AppColors.primary,
              ),
            ),
          ),
        ),
        DataCell(Text(durStr, style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              status.toUpperCase(),
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: statusFg),
            ),
          ),
        ),
      ]);
    }).toList();
  }

  DataColumn _col(String label) {
    return DataColumn(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
