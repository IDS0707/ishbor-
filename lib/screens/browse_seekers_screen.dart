import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_locale.dart';
import '../core/app_theme.dart';
import '../core/categories.dart';
import '../core/l10n.dart';
import '../core/responsive.dart';
import '../models/job.dart';
import '../models/worker_profile.dart';
import '../services/firestore_service.dart';

class BrowseSeekersScreen extends StatefulWidget {
  /// The job whose category and age requirements are used for matching.
  final Job job;
  const BrowseSeekersScreen({required this.job, super.key});

  @override
  State<BrowseSeekersScreen> createState() => _BrowseSeekersScreenState();
}

class _BrowseSeekersScreenState extends State<BrowseSeekersScreen> {
  List<WorkerProfile>? _workers;
  bool _loading = true;

  String _t(String k) => L10n.t(k, appLocale.value);
  void _rebuild() => setState(() {});

  @override
  void initState() {
    super.initState();
    appLocale.addListener(_rebuild);
    appThemeMode.addListener(_rebuild);
    _load();
  }

  @override
  void dispose() {
    appLocale.removeListener(_rebuild);
    appThemeMode.removeListener(_rebuild);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final job = widget.job;

    // Build category list: job's own category + try to match by name
    final cats = <String>[];
    if (job.category.isNotEmpty && job.category != 'cat_other') {
      cats.add(job.category);
    }
    // If no specific category, search across all
    if (cats.isEmpty) cats.addAll(kCategories);

    final workers = await FirestoreService.matchingWorkers(
      categories: cats,
      ageMin: job.ageMin,
      ageMax: job.ageMax,
      gender: job.gender,
    );
    if (mounted) {
      setState(() {
        _workers = workers;
        _loading = false;
      });
    }
  }

  Future<void> _callWorker(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appThemeMode.value == ThemeMode.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFF);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final job = widget.job;

    // Build age range label
    String ageLabel;
    if (job.ageMin > 0 && job.ageMax > 0) {
      ageLabel = _t('age_range_label')
          .replaceAll('{min}', '${job.ageMin}')
          .replaceAll('{max}', '${job.ageMax}');
    } else if (job.ageMin > 0) {
      ageLabel = '${_t('age_min')}: ${job.ageMin}+';
    } else if (job.ageMax > 0) {
      ageLabel = '${_t('age_max')}: ≤${job.ageMax}';
    } else {
      ageLabel = _t('age_any');
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('matching_workers'),
          style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 18, color: textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ResponsiveBody(
        child: Column(
          children: [
            // Job info banner
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (kCategoryColors[job.category] ??
                                  const Color(0xFF2563EB))
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          kCategoryIcons[job.category] ?? Icons.work_outline,
                          size: 22,
                          color: kCategoryColors[job.category] ??
                              const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          job.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _chip(
                        Icons.category_rounded,
                        _t(job.category),
                        kCategoryColors[job.category] ??
                            const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 8),
                      _chip(
                        Icons.cake_rounded,
                        ageLabel,
                        const Color(0xFFF59E0B),
                      ),
                      if (job.gender.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _chip(
                          job.gender == 'male'
                              ? Icons.male_rounded
                              : Icons.female_rounded,
                          _t(job.gender == 'male'
                              ? 'gender_male'
                              : 'gender_female'),
                          job.gender == 'male'
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFEC4899),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Worker list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_workers == null || _workers!.isEmpty)
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_outline_rounded,
                                  size: 64, color: textSecondary),
                              const SizedBox(height: 12),
                              Text(
                                _t('no_matching_workers'),
                                style: TextStyle(
                                    fontSize: 16, color: textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _workers!.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => _workerCard(
                            _workers![i],
                            surfaceColor,
                            borderColor,
                            textPrimary,
                            textSecondary,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _workerCard(
    WorkerProfile w,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final cats =
        w.categories.where((c) => kCategories.contains(c)).take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + age + call button
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    const Color(0xFF2563EB).withValues(alpha: 0.12),
                child: Text(
                  w.name.isNotEmpty ? w.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.name.isNotEmpty ? w.name : '—',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _t('worker_age_label').replaceAll('{n}', '${w.age}'),
                          style: TextStyle(fontSize: 13, color: textSecondary),
                        ),
                        if (w.gender.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            w.gender == 'male'
                                ? Icons.male_rounded
                                : Icons.female_rounded,
                            size: 16,
                            color: w.gender == 'male'
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFEC4899),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _t(w.gender == 'male'
                                ? 'gender_male'
                                : 'gender_female'),
                            style: TextStyle(
                              fontSize: 13,
                              color: w.gender == 'male'
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFEC4899),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (w.phone.isNotEmpty)
                GestureDetector(
                  onTap: () => _callWorker(w.phone),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                              const Color(0xFF059669).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone_rounded,
                            size: 16, color: Color(0xFF059669)),
                        const SizedBox(width: 4),
                        Text(
                          _t('call_worker'),
                          style: const TextStyle(
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Skills
          if (w.skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              w.skills,
              style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Category chips
          if (cats.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...cats.map((c) {
                  final color = kCategoryColors[c] ?? const Color(0xFF2563EB);
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _t(c),
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),
                if (w.categories.length > 3)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B7280).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${w.categories.length - 3}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
