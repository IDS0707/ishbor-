import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:job_finder_app/core/providers.dart';
import 'package:job_finder_app/models/index.dart';
import 'package:job_finder_app/ui/theme/index.dart';
import 'package:job_finder_app/ui/widgets/index.dart';

class PostJobScreen extends ConsumerStatefulWidget {
  const PostJobScreen({super.key});

  @override
  ConsumerState<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends ConsumerState<PostJobScreen> {
  final _titleController = TextEditingController();
  final _salaryController = TextEditingController();
  String _selectedCategory = 'simple_jobs';
  bool _isPosting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  void _postJob() async {
    if (_titleController.text.isEmpty || _salaryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isPosting = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not logged in');

      final firebase = ref.read(firebaseServiceProvider);
      final job = Job(
        id: '',
        title: _titleController.text,
        salary: _salaryController.text,
        phone: user.phone,
        category: _selectedCategory,
        description: '',
        location: '',
        distance: 0.0,
        employerId: user.id,
        createdAt: DateTime.now(),
      );

      await firebase.createJob(job);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Job posted successfully!')),
        );
        Navigator.pop(context);
        ref.refresh(employerJobsProvider);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    } finally {
      setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('📝 Post Job')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ONLY 3 FIELDS - DONE IN 10 SECONDS',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.success,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 24),
              Text('Job Title', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Plumber Needed',
                  prefixIcon: Icon(Icons.work),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Salary / Rate',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _salaryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '\$50-100 per day',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 24),
              Text('Category', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  CategoryChip(
                    label: '🔧 Simple',
                    isSelected: _selectedCategory == 'simple_jobs',
                    onTap: () =>
                        setState(() => _selectedCategory = 'simple_jobs'),
                  ),
                  CategoryChip(
                    label: '💼 Office',
                    isSelected: _selectedCategory == 'office_jobs',
                    onTap: () =>
                        setState(() => _selectedCategory = 'office_jobs'),
                  ),
                  CategoryChip(
                    label: '💻 Online',
                    isSelected: _selectedCategory == 'online_jobs',
                    onTap: () =>
                        setState(() => _selectedCategory = 'online_jobs'),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: '✅ Post Job Now',
                  onPressed: _postJob,
                  isLoading: _isPosting,
                  height: 56,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '🔐 Your phone number will be shared with candidates',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
