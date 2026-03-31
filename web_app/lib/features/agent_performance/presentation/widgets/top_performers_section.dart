import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salestrack_web/core/theme.dart';

class TopPerformersSection extends StatelessWidget {
  const TopPerformersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top Performers',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppColors.onSurface,
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: Text(
                'View All Agents',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              label: const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Agent cards
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 900 ? 3 : 1;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 32,
              crossAxisSpacing: 32,
              childAspectRatio: 1.3,
              children: const [
                _AgentCard(
                  name: 'Julian Schmidt',
                  role: 'Senior Agent • Tier 1',
                  calls: '142',
                  csat: '4.9',
                  trend: '+18%',
                  sparklineHeights: [0.40, 0.60, 0.45, 0.75, 0.65, 0.90, 1.0],
                ),
                _AgentCard(
                  name: 'Maya Lin',
                  role: 'Specialist • Fintech',
                  calls: '128',
                  csat: '4.8',
                  trend: '+12%',
                  sparklineHeights: [0.30, 0.50, 0.85, 0.65, 0.75, 0.80, 0.85],
                ),
                _SpotlightCard(
                  name: 'Derrick Wells',
                  role: 'Lead Strategist',
                  targetReach: '114%',
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AgentCard extends StatefulWidget {
  final String name;
  final String role;
  final String calls;
  final String csat;
  final String trend;
  final List<double> sparklineHeights;

  const _AgentCard({
    required this.name,
    required this.role,
    required this.calls,
    required this.csat,
    required this.trend,
    required this.sparklineHeights,
  });

  @override
  State<_AgentCard> createState() => _AgentCardState();
}

class _AgentCardState extends State<_AgentCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: _hovering
            ? (Matrix4.identity()..translateByDouble(0.0, -4.0, 0.0, 0.0))
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
            // Agent info header
            Row(
              children: [
                // Avatar with online indicator
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      child: Text(
                        widget.name.split(' ').map((w) => w[0]).join(),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        widget.role,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_hovering)
                  Icon(
                    Icons.more_vert,
                    size: 20,
                    color: AppColors.onSurfaceVariant,
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats row
            Row(
              children: [
                Expanded(child: _StatChip(label: 'CALLS', value: widget.calls)),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatChip(
                    label: 'CSAT',
                    value: widget.csat,
                    valueColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Spacer(),

            // Efficiency trend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Efficiency Trend',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  widget.trend,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Sparkline
            SizedBox(
              height: 40,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < widget.sparklineHeights.length; i++) ...[
                    Expanded(
                      child: FractionallySizedBox(
                        heightFactor: widget.sparklineHeights[i],
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              const Color(0xFFD1FAE5),
                              AppColors.primaryContainer,
                              i / (widget.sparklineHeights.length - 1),
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (i < widget.sparklineHeights.length - 1)
                      const SizedBox(width: 4),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatChip({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.outline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightCard extends StatelessWidget {
  final String name;
  final String role;
  final String targetReach;

  const _SpotlightCard({
    required this.name,
    required this.role,
    required this.targetReach,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF064E3B), // emerald-900
            Color(0xFF047857), // emerald-700
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorations
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF34D399).withValues(alpha: 0.2),
              ),
            ),
          ),

          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF34D399),
                    child: Text(
                      name.split(' ').map((w) => w[0]).join(),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF064E3B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        role,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFFA7F3D0).withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'WEEKLY TARGET REACH',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: const Color(0xFFA7F3D0),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                targetReach,
                style: GoogleFonts.inter(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF064E3B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'VIEW FULL ANALYTICS',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
