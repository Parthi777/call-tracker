import 'package:flutter/material.dart';
import 'package:salestrack_web/shared/top_nav_bar.dart';

import 'widgets/headline_stats_section.dart';
import 'widgets/top_performers_section.dart';
import 'widgets/metrics_table_section.dart';

class AgentPerformanceScreen extends StatelessWidget {
  const AgentPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopNavBar(
          title: 'Performance Intelligence',
          searchHint: 'Search agents or metrics...',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                HeadlineStatsSection(),
                SizedBox(height: 40),
                TopPerformersSection(),
                SizedBox(height: 48),
                MetricsTableSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
