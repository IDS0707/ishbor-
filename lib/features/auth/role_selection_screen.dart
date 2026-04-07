import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:job_finder_app/core/providers.dart';
import 'package:job_finder_app/models/index.dart';
import 'package:job_finder_app/ui/theme/index.dart';
import 'package:job_finder_app/ui/widgets/index.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  String? _selectedRole;
  bool _isLoading = false;
  final _nameController = TextEditingController();
  final _skillsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  void _proceedWithRole() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a role')));
      return;
    }

    if (_nameController.text.isEmpty || _skillsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final firebase = ref.read(firebaseServiceProvider);
      final localStorage = ref.read(localStorageProvider);
      final currentFirebaseUser = firebase.getCurrentUser();

      if (currentFirebaseUser == null) {
        throw Exception('User not authenticated');
      }

      final user = User(
        id: currentFirebaseUser.uid,
        name: _nameController.text,
        phone: currentFirebaseUser.phoneNumber ?? '',
        skills: _skillsController.text,
        userType: _selectedRole!,
        createdAt: DateTime.now(),
      );

      await firebase.saveUser(currentFirebaseUser.uid, user);
      await localStorage.saveUser(user);
      await localStorage.setUserType(_selectedRole!);

      ref.read(currentUserProvider.notifier).state = user;

      if (mounted) {
        if (_selectedRole == 'job_seeker') {
          Navigator.of(context).pushReplacementNamed('/home-seeker');
        } else {
          Navigator.of(context).pushReplacementNamed('/home-employer');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Who are you?',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 24),
                _RoleCard(
                  icon: '👤',
                  title: 'Job Seeker',
                  description: 'I want to find jobs',
                  isSelected: _selectedRole == 'job_seeker',
                  onTap: () {
                    setState(() => _selectedRole = 'job_seeker');
                  },
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  icon: '🏢',
                  title: 'Employer',
                  description: 'I want to post jobs',
                  isSelected: _selectedRole == 'employer',
                  onTap: () {
                    setState(() => _selectedRole = 'employer');
                  },
                ),
                const SizedBox(height: 36),
                Text(
                  'Complete your profile',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Your name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _skillsController,
                  decoration: InputDecoration(
                    hintText: _selectedRole == 'job_seeker'
                        ? 'Your skills (e.g., Driver, Plumber, Developer)'
                        : 'Job category (e.g., Simple Jobs, Office)',
                    prefixIcon: const Icon(Icons.star),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Continue',
                  onPressed: _proceedWithRole,
                  isLoading: _isLoading,
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}
