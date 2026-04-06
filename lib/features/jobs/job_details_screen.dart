import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:job_finder_app/core/providers.dart';
import 'package:job_finder_app/models/index.dart';
import 'package:job_finder_app/services/index.dart';
import 'package:job_finder_app/ui/theme/index.dart';
import 'package:job_finder_app/ui/widgets/index.dart';

class JobDetailsScreen extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailsScreen({required this.jobId, super.key});

  @override
  ConsumerState<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends ConsumerState<JobDetailsScreen> {
  bool _isApplying = false;

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobDetailsProvider(widget.jobId));
    final isFavorite = ref.watch(isFavoriteProvider(widget.jobId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? AppTheme.danger : null,
            ),
            onPressed: () => _toggleFavorite(),
          ),
        ],
      ),
      body: jobAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (job) {
          if (job == null) {
            return const Center(child: Text('Job not found'));
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Job Title & Salary
                  Text(
                    job.title,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.salary,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Category & Location
                  Row(
                    children: [
                      Chip(
                        label: Text(job.category),
                        backgroundColor: AppTheme.primary.withOpacity(0.1),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('${job.distance} km away'),
                        backgroundColor: AppTheme.secondary.withOpacity(0.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Job Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.description.isEmpty
                        ? 'No description provided'
                        : job.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // Contact Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        HiddenPhoneWidget(phoneNumber: job.phone),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: '📞 Call',
                      onPressed: () => _makeCall(job.phone),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SecondaryButton(
                      label: '💬 Open Telegram',
                      onPressed: () => _openTelegram(job.phone),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: '✋ Apply Now',
                      onPressed: () => _applyForJob(job),
                      isLoading: _isApplying,
                      backgroundColor: AppTheme.success,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _toggleFavorite() {
    final localStorage = ref.read(localStorageProvider);
    if (localStorage.isFavorite(widget.jobId)) {
      localStorage.removeFavorite(widget.jobId);
    } else {
      localStorage.addFavorite(widget.jobId);
    }
    ref.refresh(isFavoriteProvider(widget.jobId));
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openTelegram(String phone) async {
    // Remove + and format phone for Telegram
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _applyForJob(Job job) async {
    setState(() => _isApplying = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not logged in');

      final firebase = ref.read(firebaseServiceProvider);
      final application = Application(
        id: '',
        userId: user.id,
        jobId: job.id,
        status: 'applied',
        createdAt: DateTime.now(),
      );

      await firebase.applyForJob(application);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Application sent successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    } finally {
      setState(() => _isApplying = false);
    }
  }
}
