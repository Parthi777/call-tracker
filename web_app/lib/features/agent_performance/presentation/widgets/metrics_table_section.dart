import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salestrack_web/core/firestore_providers.dart';
import 'package:salestrack_web/core/theme.dart';

class MetricsTableSection extends ConsumerStatefulWidget {
  const MetricsTableSection({super.key});

  @override
  ConsumerState<MetricsTableSection> createState() => _MetricsTableSectionState();
}

class _MetricsTableSectionState extends ConsumerState<MetricsTableSection> {
  bool _realtime = true;

  @override
  Widget build(BuildContext context) {
    final execKpis = ref.watch(perExecutiveKpiProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agent Metrics Matrix',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Granular comparison of call-by-call performance data',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _ToggleChip(
                            label: 'Real-time',
                            active: _realtime,
                            onTap: () => setState(() => _realtime = true),
                          ),
                          _ToggleChip(
                            label: 'Historical',
                            active: !_realtime,
                            onTap: () => setState(() => _realtime = false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.filter_list,
                        size: 20,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Table
          if (execKpis.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No agent data available yet',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.outline),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 320,
                ),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    AppColors.surfaceContainerLow.withValues(alpha: 0.5),
                  ),
                  headingRowHeight: 56,
                  dataRowMinHeight: 72,
                  dataRowMaxHeight: 72,
                  columnSpacing: 32,
                  horizontalMargin: 32,
                  dividerThickness: 0.5,
                  columns: [
                    _buildColumn('AGENT DETAILS'),
                    _buildColumn('TOTAL CALLS'),
                    _buildColumn('AVG DURATION'),
                    _buildColumn('INCOMING'),
                    _buildColumn('OUTGOING'),
                    _buildColumn('STATUS'),
                    _buildColumn('ACTION', alignRight: true),
                  ],
                  rows: execKpis.map(_buildRow).toList(),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  DataColumn _buildColumn(String label, {bool alignRight = false}) {
    return DataColumn(
      label: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: AppColors.outline,
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(Map<String, dynamic> exec) {
    final name = exec['name'] as String? ?? 'Unknown';
    final execId = exec['executiveId'] as String? ?? '';
    final totalCalls = exec['totalCalls'] as int? ?? 0;
    final avgDuration = exec['avgDuration'] as String? ?? '0s';
    final incoming = exec['incoming'] as int? ?? 0;
    final outgoing = exec['outgoing'] as int? ?? 0;
    final isActive = exec['isActive'] as bool? ?? false;
    final status = isActive ? 'Online' : 'Offline';

    return DataRow(
      cells: [
        // Agent details
        DataCell(
          SizedBox(
            width: 180,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  child: Text(
                    name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').join(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        'ID: ${execId.length > 6 ? execId.substring(0, 6) : execId}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Total Calls
        DataCell(Text(
          '$totalCalls',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        )),

        // Avg Duration
        DataCell(Text(
          avgDuration,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        )),

        // Incoming
        DataCell(Text(
          '$incoming',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        )),

        // Outgoing
        DataCell(Text(
          '$outgoing',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        )),

        // Status
        DataCell(_StatusBadge(status: status)),

        // Action
        DataCell(
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Drill-down',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.onSurface.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.primary : AppColors.outline,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case 'Online':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
      case 'In Call':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
      default:
        bg = AppColors.surfaceContainerHigh;
        fg = AppColors.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
