import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salestrack_web/core/theme.dart';

class _AgentMetric {
  final String name;
  final String id;
  final String aht;
  final String silence;
  final String crosstalk;
  final double adherence;
  final String status;

  const _AgentMetric({
    required this.name,
    required this.id,
    required this.aht,
    required this.silence,
    required this.crosstalk,
    required this.adherence,
    required this.status,
  });
}

const _mockData = [
  _AgentMetric(
    name: 'Julian Schmidt',
    id: '#44021',
    aht: '03:45',
    silence: '8.2%',
    crosstalk: '4.1%',
    adherence: 0.92,
    status: 'Online',
  ),
  _AgentMetric(
    name: 'Maya Lin',
    id: '#44029',
    aht: '04:12',
    silence: '12.5%',
    crosstalk: '1.8%',
    adherence: 0.98,
    status: 'In Call',
  ),
  _AgentMetric(
    name: 'Derrick Wells',
    id: '#44033',
    aht: '05:20',
    silence: '15.2%',
    crosstalk: '2.4%',
    adherence: 0.76,
    status: 'Offline',
  ),
];

class MetricsTableSection extends StatefulWidget {
  const MetricsTableSection({super.key});

  @override
  State<MetricsTableSection> createState() => _MetricsTableSectionState();
}

class _MetricsTableSectionState extends State<MetricsTableSection> {
  bool _realtime = true;

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
                  _buildColumn('AHT (MIN)'),
                  _buildColumn('SILENCE %'),
                  _buildColumn('CROSSTALK %'),
                  _buildColumn('ADHERENCE'),
                  _buildColumn('STATUS'),
                  _buildColumn('ACTION', alignRight: true),
                ],
                rows: _mockData.map(_buildRow).toList(),
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

  DataRow _buildRow(_AgentMetric agent) {
    final isCrosstalkHigh =
        double.tryParse(agent.crosstalk.replaceAll('%', ''))! > 3.0;

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
                    agent.name.split(' ').map((w) => w[0]).join(),
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
                        agent.name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        'ID: ${agent.id}',
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

        // AHT
        DataCell(Text(
          agent.aht,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        )),

        // Silence
        DataCell(Text(
          agent.silence,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        )),

        // Crosstalk
        DataCell(Text(
          agent.crosstalk,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isCrosstalkHigh ? AppColors.tertiary : AppColors.onSurface,
          ),
        )),

        // Adherence
        DataCell(
          Row(
            children: [
              SizedBox(
                width: 64,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: agent.adherence,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation(
                      agent.adherence >= 0.9
                          ? AppColors.primaryContainer
                          : AppColors.secondaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(agent.adherence * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),

        // Status
        DataCell(_StatusBadge(status: agent.status)),

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
