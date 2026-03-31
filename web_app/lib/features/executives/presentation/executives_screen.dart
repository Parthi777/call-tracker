import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salestrack_web/core/firestore_providers.dart';
import 'package:salestrack_web/core/theme.dart';
import 'package:salestrack_web/shared/top_nav_bar.dart';

class ExecutivesScreen extends ConsumerWidget {
  const ExecutivesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executivesAsync = ref.watch(executivesStreamProvider);

    return Column(
      children: [
        const TopNavBar(
          title: 'Executive Management',
          searchHint: 'Search executives...',
        ),
        Expanded(
          child: executivesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (executives) => _buildContent(context, executives),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
      BuildContext context, List<Map<String, dynamic>> executives) {
    final active = executives.where((e) => e['isActive'] == true).length;
    final inactive = executives.length - active;

    return SingleChildScrollView(
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
                    'TEAM',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage Executives',
                    style: GoogleFonts.inter(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Add Executive'),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Stats row
          Row(
            children: [
              _StatCard(
                  label: 'Total Executives',
                  value: '${executives.length}',
                  icon: Icons.people),
              const SizedBox(width: 16),
              _StatCard(
                label: 'Active',
                value: '$active',
                icon: Icons.check_circle_outline,
                color: AppColors.primary,
              ),
              const SizedBox(width: 16),
              _StatCard(
                label: 'Inactive',
                value: '$inactive',
                icon: Icons.pause_circle_outline,
                color: AppColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Executive table
          Container(
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
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Executives',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.filter_list, size: 16),
                        label: const Text('Filter'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide.none,
                          backgroundColor: AppColors.surfaceContainerLow,
                          foregroundColor: AppColors.onSurface,
                          textStyle: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                executives.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(48),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.people_outline,
                                  size: 48,
                                  color: AppColors.onSurfaceVariant),
                              const SizedBox(height: 12),
                              Text(
                                'No executives yet',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                'Executives will appear here when they sign in on the mobile app.',
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
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            AppColors.surfaceContainerLow
                                .withValues(alpha: 0.5),
                          ),
                          headingRowHeight: 52,
                          dataRowMinHeight: 72,
                          dataRowMaxHeight: 72,
                          columnSpacing: 32,
                          horizontalMargin: 24,
                          dividerThickness: 0.5,
                          columns: [
                            _col('EXECUTIVE'),
                            _col('PHONE'),
                            _col('DRIVE FOLDER'),
                            _col('STATUS'),
                            _col('ACTIONS'),
                          ],
                          rows:
                              executives.map((e) => _buildRow(e)).toList(),
                        ),
                      ),
                const SizedBox(height: 16),
              ],
            ),
          ),
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

  DataRow _buildRow(Map<String, dynamic> exec) {
    final name = exec['name'] as String? ?? 'Unknown';
    final phone = exec['phone'] as String? ?? '--';
    final driveFolder = exec['driveFolder'] as String? ?? '--';
    final isActive = exec['isActive'] as bool? ?? true;

    return DataRow(cells: [
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isActive
                  ? AppColors.surfaceContainerHigh
                  : AppColors.surfaceDim,
              child: Text(
                name.split(' ').map((w) => w[0]).join(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive ? AppColors.primary : AppColors.outline,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              name,
              style:
                  GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      DataCell(Text(phone,
          style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.onSurfaceVariant))),
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_outlined, size: 16, color: AppColors.outline),
            const SizedBox(width: 6),
            Text(driveFolder,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFD1FAE5)
                : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            isActive ? 'Active' : 'Inactive',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? const Color(0xFF065F46)
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () {},
              color: AppColors.primary,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: Icon(
                isActive
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                size: 18,
              ),
              onPressed: () {},
              color: isActive ? AppColors.secondary : AppColors.primary,
              tooltip: isActive ? 'Deactivate' : 'Activate',
            ),
          ],
        ),
      ),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.onSurface;
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: c),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
