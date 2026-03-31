import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salestrack_web/core/theme.dart';
import 'package:salestrack_web/shared/top_nav_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoUpload = true;
  bool _realTimeSync = true;
  bool _emailNotifications = true;
  bool _slackNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopNavBar(title: 'Settings'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONFIGURATION',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'System Settings',
                  style: GoogleFonts.inter(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 32),

                // Settings sections
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _buildGoogleDriveSection(),
                                const SizedBox(height: 24),
                                _buildNotificationsSection(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: Column(
                              children: [
                                _buildFirebaseSection(),
                                const SizedBox(height: 24),
                                _buildRecordingSection(),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _buildGoogleDriveSection(),
                        const SizedBox(height: 24),
                        _buildFirebaseSection(),
                        const SizedBox(height: 24),
                        _buildNotificationsSection(),
                        const SizedBox(height: 24),
                        _buildRecordingSection(),
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

  Widget _buildGoogleDriveSection() {
    return _SettingsCard(
      title: 'Google Drive',
      icon: Icons.cloud_outlined,
      children: [
        _SettingsRow(
          label: 'Auto Upload',
          description: 'Automatically upload recordings after call ends',
          trailing: Switch(
            value: _autoUpload,
            onChanged: (v) => setState(() => _autoUpload = v),
            activeThumbColor: AppColors.primaryContainer,
          ),
        ),
        const Divider(height: 32),
        _SettingsRow(
          label: 'Folder Structure',
          description: 'SalesTrack/{ExecutiveName}/{YYYY-MM}/',
          trailing: Icon(Icons.folder_outlined, size: 20, color: AppColors.outline),
        ),
        const Divider(height: 32),
        _SettingsRow(
          label: 'File Format',
          description: 'AAC/MP4 (optimized for Drive storage)',
          trailing: Icon(Icons.audio_file, size: 20, color: AppColors.outline),
        ),
      ],
    );
  }

  Widget _buildFirebaseSection() {
    return _SettingsCard(
      title: 'Firebase Sync',
      icon: Icons.sync_outlined,
      children: [
        _SettingsRow(
          label: 'Real-time Sync',
          description: 'Live KPI updates via Firestore listeners',
          trailing: Switch(
            value: _realTimeSync,
            onChanged: (v) => setState(() => _realTimeSync = v),
            activeThumbColor: AppColors.primaryContainer,
          ),
        ),
        const Divider(height: 32),
        _SettingsRow(
          label: 'Project ID',
          description: 'salestrack-prod',
          trailing: Icon(Icons.link, size: 20, color: AppColors.outline),
        ),
        const Divider(height: 32),
        _SettingsRow(
          label: 'KPI Aggregation',
          description: 'Cloud Function — runs after each call sync',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'Active',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF065F46),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return _SettingsCard(
      title: 'Notifications',
      icon: Icons.notifications_outlined,
      children: [
        _SettingsRow(
          label: 'Email Alerts',
          description: 'Daily summary and escalation alerts',
          trailing: Switch(
            value: _emailNotifications,
            onChanged: (v) => setState(() => _emailNotifications = v),
            activeThumbColor: AppColors.primaryContainer,
          ),
        ),
        const Divider(height: 32),
        _SettingsRow(
          label: 'Slack Integration',
          description: 'Post alerts to #sales-monitoring channel',
          trailing: Switch(
            value: _slackNotifications,
            onChanged: (v) => setState(() => _slackNotifications = v),
            activeThumbColor: AppColors.primaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingSection() {
    return _SettingsCard(
      title: 'Recording Defaults',
      icon: Icons.mic_outlined,
      children: [
        _SettingsRow(
          label: 'Recording Format',
          description: 'AAC/MP4',
          trailing: Icon(Icons.audio_file, size: 20, color: AppColors.outline),
        ),
        const Divider(height: 32),
        _SettingsRow(
          label: 'Missed Call Threshold',
          description: 'Calls under 5 seconds marked as missed',
          trailing: Text(
            '5s',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ),
        const Divider(height: 32),
        _SettingsRow(
          label: 'Offline Queue',
          description: 'Hive local store — retry on network restore',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'Enabled',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF065F46),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final String description;
  final Widget trailing;

  const _SettingsRow({
    required this.label,
    required this.description,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}
