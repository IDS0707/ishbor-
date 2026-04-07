import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:job_finder_app/core/providers.dart';
import 'package:job_finder_app/models/index.dart';
import 'package:job_finder_app/ui/theme/index.dart';

class ApplicationsStatusScreen extends ConsumerWidget {
  const ApplicationsStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(userApplicationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('📊 Application Status')),
      body: applicationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (applications) {
          if (applications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inbox,
                    size: 48,
                    color: AppTheme.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No applications yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          // Group by status
          final seen = applications.where((a) => a.status == 'seen').toList();
          final replied =
              applications.where((a) => a.status == 'replied').toList();
          final rejected =
              applications.where((a) => a.status == 'rejected').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (replied.isNotEmpty) ...[
                _StatusSection(
                  title: '✅ Replied',
                  applications: replied,
                  color: AppTheme.success,
                ),
                const SizedBox(height: 16),
              ],
              if (seen.isNotEmpty) ...[
                _StatusSection(
                  title: '👁️ Seen',
                  applications: seen,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 16),
              ],
              if (rejected.isNotEmpty) ...[
                _StatusSection(
                  title: '❌ Rejected',
                  applications: rejected,
                  color: AppTheme.danger,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  final String title;
  final List<Application> applications;
  final Color color;

  const _StatusSection({
    required this.title,
    required this.applications,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...applications.map((app) {
          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Job ID: ${app.jobId}',
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Applied: ${app.createdAt.toLocal().toString().split('.')[0]}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    app.status.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
