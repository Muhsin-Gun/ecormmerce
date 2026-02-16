import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  String _window = '7d';

  Query<Map<String, dynamic>> _query() {
    final base = FirebaseFirestore.instance
        .collection(AppConstants.auditLogsCollection)
        .orderBy('timestamp', descending: true)
        .limit(250);

    if (_window == 'all') return base;

    final now = DateTime.now();
    final from = _window == '24h'
        ? now.subtract(const Duration(hours: 24))
        : now.subtract(const Duration(days: 7));
    return base.where('timestamp', isGreaterThanOrEqualTo: from);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Window',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(value: '24h', label: Text('24h')),
                    ButtonSegment<String>(value: '7d', label: Text('7d')),
                    ButtonSegment<String>(value: 'all', label: Text('All')),
                  ],
                  selected: {_window},
                  onSelectionChanged: (value) {
                    setState(() => _window = value.first);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _query().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ErrorState(error: snapshot.error.toString());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const _EmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final action = (data['action'] ?? 'UNKNOWN').toString();
                    final target = (data['target'] ?? 'system').toString();
                    final actor = (data['by'] ?? data['uid'] ?? 'system').toString();
                    final ts = data['timestamp'] as Timestamp?;
                    final when = ts?.toDate();
                    final metadata = Map<String, dynamic>.from(
                      data['metadata'] as Map? ?? const <String, dynamic>{},
                    );

                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _actionColor(action).withValues(alpha: 0.30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _actionColor(action)
                                        .withValues(alpha: 0.13),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    action,
                                    style: TextStyle(
                                      color: _actionColor(action),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  when == null
                                      ? 'Unknown time'
                                      : DateFormat('MMM d, HH:mm').format(when),
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              target,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Actor: $actor',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            if (metadata.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.black.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  metadata.entries
                                      .map((e) => '${e.key}: ${e.value}')
                                      .join('  •  '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _actionColor(String action) {
    final normalized = action.toUpperCase();
    if (normalized.contains('DELETE') || normalized.contains('FAILED')) {
      return AppColors.error;
    }
    if (normalized.contains('UPDATE')) return AppColors.warning;
    if (normalized.contains('CREATE') || normalized.contains('SENT')) {
      return AppColors.success;
    }
    return AppColors.primaryIndigo;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.history_toggle_off, size: 54, color: AppColors.gray500),
            SizedBox(height: 10),
            Text('No audit logs in this window'),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 46),
            const SizedBox(height: 10),
            const Text(
              'Could not load audit logs',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
