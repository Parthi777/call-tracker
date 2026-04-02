import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salestrack_web/core/firestore_providers.dart';
import 'package:salestrack_web/core/theme.dart';
import 'package:salestrack_web/shared/shimmer_loading.dart';
import 'package:salestrack_web/shared/top_nav_bar.dart';

class CallFeedScreen extends ConsumerStatefulWidget {
  const CallFeedScreen({super.key});

  @override
  ConsumerState<CallFeedScreen> createState() => _CallFeedScreenState();
}

class _CallFeedScreenState extends ConsumerState<CallFeedScreen> {
  String _activeFilter = 'All';

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> calls) {
    switch (_activeFilter) {
      case 'Incoming':
        return calls.where((c) => c['direction'] == 'incoming').toList();
      case 'Outgoing':
        return calls.where((c) => c['direction'] == 'outgoing').toList();
      case 'Missed':
        return calls
            .where((c) =>
                (c['duration'] as int? ?? 0) < 5 &&
                c['direction'] == 'incoming')
            .toList();
      default:
        return calls;
    }
  }

  @override
  Widget build(BuildContext context) {
    final callsAsync = ref.watch(callsStreamProvider);

    return Column(
      children: [
        const TopNavBar(
          title: 'Call Feed',
          searchHint: 'Search by agent, phone number...',
        ),
        Expanded(
          child: callsAsync.when(
            loading: () => const DashboardSkeleton(),
            error: (e, _) => ErrorStateWidget(
              message: '$e',
              onRetry: () => ref.invalidate(callsStreamProvider),
            ),
            data: (calls) {
              final filtered = _applyFilter(calls);
              return SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LIVE MONITORING',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.0,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Real-time Call Intelligence',
                              style: GoogleFonts.inter(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.0,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${calls.length} Calls',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Filter chips
                    Row(
                      children: [
                        for (final filter in [
                          'All',
                          'Incoming',
                          'Outgoing',
                          'Missed'
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label: filter,
                              active: _activeFilter == filter,
                              onTap: () =>
                                  setState(() => _activeFilter = filter),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Call feed table
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.onSurface.withValues(alpha: 0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: filtered.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(48),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.call_outlined,
                                        size: 48,
                                        color: AppColors.onSurfaceVariant),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No calls yet',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      'Calls will appear here in real-time as executives make and receive calls.',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth:
                                      MediaQuery.of(context).size.width - 360,
                                ),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    AppColors.surfaceContainerLow
                                        .withValues(alpha: 0.5),
                                  ),
                                  headingRowHeight: 52,
                                  dataRowMinHeight: 64,
                                  dataRowMaxHeight: 64,
                                  columnSpacing: 24,
                                  horizontalMargin: 24,
                                  dividerThickness: 0.5,
                                  columns: [
                                    _col('TIME'),
                                    _col('EXECUTIVE'),
                                    _col('PHONE'),
                                    _col('DIR'),
                                    _col('DURATION'),
                                    _col('STATUS'),
                                  ],
                                  rows: filtered.map(_buildRow).toList(),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
    String time = '--';
    if (ts is Timestamp) {
      final dt = ts.toDate();
      time =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    }

    final direction = call['direction'] as String? ?? '';
    final dirLabel = direction == 'incoming' ? 'IN' : 'OUT';
    final duration = call['duration'] as int? ?? 0;
    final phone = call['phoneNumber'] as String? ?? 'Unknown';
    final executive = call['executiveId'] as String? ?? 'Unknown';
    final status = call['status'] as String? ?? 'recorded';
    final isMissed = duration < 5 && direction == 'incoming';

    final durMin = duration ~/ 60;
    final durSec = duration % 60;
    final durStr = isMissed
        ? 'Missed'
        : '${durMin.toString().padLeft(2, '0')}:${durSec.toString().padLeft(2, '0')}';

    return DataRow(
      color: isMissed
          ? WidgetStateProperty.all(
              const Color(0xFFFEF2F2).withValues(alpha: 0.3))
          : null,
      cells: [
        DataCell(Text(time,
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w500))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.surfaceContainerHigh,
                child: Text(
                  executive.isNotEmpty ? executive[0].toUpperCase() : '?',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Text(executive,
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
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
        DataCell(
          isMissed
              ? Text('Missed',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tertiary))
              : Text(durStr,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.onSurfaceVariant)),
        ),
        DataCell(
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'uploaded'
                  ? const Color(0xFFD1FAE5)
                  : status == 'uploading'
                      ? const Color(0xFFFEF3C7)
                      : AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              status.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: status == 'uploaded'
                    ? const Color(0xFF065F46)
                    : status == 'uploading'
                        ? const Color(0xFF92400E)
                        : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(99),
          boxShadow: active
              ? null
              : [
                  BoxShadow(
                    color: AppColors.onSurface.withValues(alpha: 0.04),
                    blurRadius: 4,
                  ),
                ],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
