import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:job_finder_app/core/providers.dart';
import 'package:job_finder_app/ui/theme/index.dart';
import 'package:job_finder_app/ui/widgets/index.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localStorage = ref.watch(localStorageProvider);
    final favoriteIds = localStorage.getFavorites();
    final cachedJobs = localStorage.getAllCachedJobs();

    final favoriteJobs =
        cachedJobs.where((job) => favoriteIds.contains(job.id)).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('❤️ Saved Jobs')),
      body: favoriteJobs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 48,
                    color: AppTheme.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved jobs yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: favoriteJobs.length,
              itemBuilder: (context, index) {
                final job = favoriteJobs[index];
                return JobCard(
                  title: job.title,
                  salary: job.salary,
                  category: job.category,
                  distance: job.distance.toString(),
                  isFavorite: true,
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamed('/job-details', arguments: job.id);
                  },
                  onFavoriteTap: () {
                    localStorage.removeFavorite(job.id);
                    ref.refresh(isFavoriteProvider(job.id));
                  },
                );
              },
            ),
    );
  }
}
