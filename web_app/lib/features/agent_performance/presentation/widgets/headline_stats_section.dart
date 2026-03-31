import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salestrack_web/core/theme.dart';

class HeadlineStatsSection extends StatelessWidget {
  const HeadlineStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WORKFORCE OVERVIEW',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Global Efficiency Targets',
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
                _ActionButton(
                  icon: Icons.calendar_today,
                  label: 'Last 7 Days',
                  filled: false,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.download,
                  label: 'Export Report',
                  filled: true,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // KPI cards grid
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 24,
              crossAxisSpacing: 24,
              childAspectRatio: 1.6,
              children: const [
                _KpiCard(
                  label: 'Avg Handle Time',
                  value: '04:12',
                  badge: '-12%',
                  badgePositive: true,
                  progress: 0.80,
                  progressColor: AppColors.primary,
                ),
                _KpiCard(
                  label: 'Sentiment Score',
                  value: '88%',
                  badge: '+5.2%',
                  badgePositive: true,
                  progress: 0.88,
                  progressColor: AppColors.secondaryContainer,
                ),
                _KpiCard(
                  label: 'Resolution Rate',
                  value: '94.2%',
                  badge: '-0.8%',
                  badgePositive: false,
                  progress: 0.94,
                  progressColor: AppColors.primaryContainer,
                ),
                _KpiCard(
                  label: 'Active Agents',
                  value: '42/48',
                  badge: 'Live',
                  badgePositive: null,
                  progress: null,
                  progressColor: null,
                  showAvatars: true,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: filled ? AppColors.primary : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: filled ? 0.1 : 0.04),
            blurRadius: filled ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: filled ? Colors.white : AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String badge;
  final bool? badgePositive;
  final double? progress;
  final Color? progressColor;
  final bool showAvatars;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.badge,
    required this.badgePositive,
    required this.progress,
    required this.progressColor,
    this.showAvatars = false,
  });

  @override
  Widget build(BuildContext context) {
    final badgeBg = badgePositive == null
        ? AppColors.surfaceContainerHigh
        : badgePositive!
            ? const Color(0xFFECFDF5)
            : AppColors.errorContainer;
    final badgeFg = badgePositive == null
        ? AppColors.outline
        : badgePositive!
            ? AppColors.primary
            : AppColors.tertiary;

    return Container(
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeFg,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              if (progress != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceContainerLow,
                    valueColor: AlwaysStoppedAnimation(progressColor!),
                  ),
                ),
              if (showAvatars) _buildAvatarStack(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStack() {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
    ];
    return SizedBox(
      height: 28,
      child: Stack(
        children: [
          for (var i = 0; i < colors.length; i++)
            Positioned(
              left: i * 18.0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colors[i],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          Positioned(
            left: 3 * 18.0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '+39',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
