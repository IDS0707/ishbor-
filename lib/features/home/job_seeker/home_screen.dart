import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:job_finder_app/core/providers.dart';
import 'package:job_finder_app/models/index.dart';
import 'package:job_finder_app/services/index.dart';
import 'package:job_finder_app/ui/theme/index.dart';
import 'package:job_finder_app/ui/widgets/index.dart';

class JobSeekerHomeScreen extends ConsumerStatefulWidget {
  const JobSeekerHomeScreen({super.key});

  @override
  ConsumerState<JobSeekerHomeScreen> createState() =>
      _JobSeekerHomeScreenState();
}

class _JobSeekerHomeScreenState extends ConsumerState<JobSeekerHomeScreen> {
  int _selectedTabIndex = 0;
  String _selectedCategory = 'simple_jobs';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('👋 Hi ${user?.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(ref, context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                CategoryChip(
                  label: '🔧 Simple',
                  isSelected: _selectedCategory == 'simple_jobs',
                  onTap: () =>
                      setState(() => _selectedCategory = 'simple_jobs'),
                ),
                const SizedBox(width: 8),
                CategoryChip(
                  label: '💼 Office',
                  isSelected: _selectedCategory == 'office_jobs',
                  onTap: () =>
                      setState(() => _selectedCategory = 'office_jobs'),
                ),
                const SizedBox(width: 8),
                CategoryChip(
                  label: '💻 Online',
                  isSelected: _selectedCategory == 'online_jobs',
                  onTap: () =>
                      setState(() => _selectedCategory = 'online_jobs'),
                ),
              ],
            ),
          ),
          // Jobs List
          Expanded(child: _buildJobsList(_selectedCategory)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: (index) {
          setState(() => _selectedTabIndex = index);
          if (index == 1) {
            Navigator.of(context).pushNamed('/favorites');
          } else if (index == 2) {
            Navigator.of(context).pushNamed('/applications');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Status'),
        ],
      ),
    );
  }

  Widget _buildJobsList(String category) {
    return Consumer(
      builder: (context, ref, child) {
        final jobsAsync = _getJobsByCategory(ref, category);

        return jobsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: AppTheme.danger),
                const SizedBox(height: 12),
                Text('Error: $error'),
              ],
            ),
          ),
          data: (jobs) {
            if (jobs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.inbox,
                      size: 48,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No jobs in this category',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                final isFavorite = ref.watch(isFavoriteProvider(job.id));

                return JobCard(
                  title: job.title,
                  salary: job.salary,
                  category: job.category,
                  distance: job.distance.toString(),
                  phone: job.phone,
                  isFavorite: isFavorite,
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamed('/job-details', arguments: job.id);
                  },
                  onFavoriteTap: () {
                    _toggleFavorite(ref, job.id);
                  },
                  onCallTap:
                      job.phone.isNotEmpty ? () => _makeCall(job.phone) : null,
                );
              },
            );
          },
        );
      },
    );
  }

  AsyncValue<List<Job>> _getJobsByCategory(WidgetRef ref, String category) {
    switch (category) {
      case 'simple_jobs':
        return ref.watch(simpleJobsProvider);
      case 'office_jobs':
        return ref.watch(officeJobsProvider);
      case 'online_jobs':
        return ref.watch(onlineJobsProvider);
      default:
        return ref.watch(jobsProvider);
    }
  }

  void _toggleFavorite(WidgetRef ref, String jobId) {
    final localStorage = ref.read(localStorageProvider);
    if (localStorage.isFavorite(jobId)) {
      localStorage.removeFavorite(jobId);
    } else {
      localStorage.addFavorite(jobId);
    }
    // Refresh state
    ref.refresh(isFavoriteProvider(jobId));
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _logout(WidgetRef ref, BuildContext context) async {
    final firebase = ref.read(firebaseServiceProvider);
    final localStorage = ref.read(localStorageProvider);

    await firebase.signOut();
    await localStorage.clearAll();

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }
}
