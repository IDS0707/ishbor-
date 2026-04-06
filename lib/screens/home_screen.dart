import 'package:flutter/material.dart';
import '../core/app_locale.dart';
import '../core/app_theme.dart';
import '../core/responsive.dart';
import '../core/categories.dart';
import '../core/l10n.dart';
import '../models/job.dart';
import 'post_job_screen.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import '../services/firestore_service.dart';
import 'job_detail_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0; // 0 = all, 1 = chats, 2 = saved
  int _navIndex = 0; // mirrors _tab for NavigationBar
  Set<String> _savedIds = {};
  String _selectedCategory = 'all';
  String _selectedRegion = 'all';
  String _selectedEmpType = 'all';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reloadFavorites();
    appLocale.addListener(_rebuild);
    appThemeMode.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});
  String _t(String k) => L10n.t(k, appLocale.value);

  int get _activeFilterCount =>
      (_selectedCategory != 'all' ? 1 : 0) +
      (_selectedRegion != 'all' ? 1 : 0) +
      (_selectedEmpType != 'all' ? 1 : 0);

  void _openFilterSheet() {
    final isDark = appThemeMode.value == ThemeMode.dark;
    String tempCat = _selectedCategory;
    String tempReg = _selectedRegion;
    String tempEmp = _selectedEmpType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
          final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
          final border =
              isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
          final textPri = isDark ? Colors.white : const Color(0xFF111827);
          final textSec =
              isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

          // 2-column grid cell for category
          Widget catCard(String key) {
            final isSel = tempCat == key;
            final color = key == 'all'
                ? const Color(0xFF2563EB)
                : (kCategoryColors[key] ?? const Color(0xFF2563EB));
            final icon = key == 'all'
                ? Icons.apps_rounded
                : (kCategoryIcons[key] ?? Icons.work_outline);
            final label = key == 'all' ? _t('all_categories') : _t(key);
            return GestureDetector(
              onTap: () => setSheet(() => tempCat = key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSel ? color.withValues(alpha: 0.12) : surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isSel ? color : border, width: isSel ? 2 : 1),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Icon(icon,
                        size: 20,
                        color: isSel ? color : const Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel ? color : textPri,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSel)
                      Icon(Icons.check_rounded, size: 16, color: color),
                  ],
                ),
              ),
            );
          }

          // Large row for region
          Widget regionRow(String key) {
            final isSel = tempReg == key;
            const color = Color(0xFF16A34A);
            final label = key == 'all' ? _t('all_regions') : _t(key);
            return GestureDetector(
              onTap: () => setSheet(() => tempReg = key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSel
                      ? const Color(0xFF16A34A).withValues(alpha: 0.08)
                      : surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isSel ? color : border, width: isSel ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 20, color: isSel ? color : textSec),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel ? color : textPri,
                        ),
                      ),
                    ),
                    if (isSel)
                      const Icon(Icons.check_rounded, size: 18, color: color),
                  ],
                ),
              ),
            );
          }

          // Large button for employment type
          Widget empBtn(String key) {
            final isSel = tempEmp == key;
            final color = kEmpTypeColors[key] ?? const Color(0xFF2563EB);
            final icon = kEmpTypeIcons[key] ?? Icons.work_outline;
            final label = key == 'all' ? _t('all_emp_types') : _t(key);
            return GestureDetector(
              onTap: () => setSheet(() => tempEmp = key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: isSel ? color.withValues(alpha: 0.1) : surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isSel ? color : border, width: isSel ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSel
                            ? color.withValues(alpha: 0.15)
                            : color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon,
                          size: 22,
                          color: isSel ? color : color.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel ? color : textPri,
                      ),
                    ),
                    const Spacer(),
                    if (isSel)
                      Icon(Icons.check_circle_rounded, size: 22, color: color),
                  ],
                ),
              ),
            );
          }

          // Section header
          Widget sectionHeader(String label, IconData icon, Color accent,
              bool active, VoidCallback onClear) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: accent),
                  ),
                  const SizedBox(width: 10),
                  Text(label,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: textPri)),
                  const Spacer(),
                  if (active)
                    GestureDetector(
                      onTap: onClear,
                      child: Text(
                        _t('reset_filters'),
                        style: TextStyle(
                            fontSize: 13,
                            color: accent,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            );
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.92,
            decoration: BoxDecoration(
              color: bg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                // Title row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(_t('filter_title'),
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: textPri)),
                      const Spacer(),
                      if (tempCat != 'all' ||
                          tempReg != 'all' ||
                          tempEmp != 'all')
                        TextButton.icon(
                          onPressed: () => setSheet(() {
                            tempCat = 'all';
                            tempReg = 'all';
                            tempEmp = 'all';
                          }),
                          icon: const Icon(Icons.refresh_rounded,
                              size: 16, color: Color(0xFFDC2626)),
                          label: Text(_t('reset_filters'),
                              style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4)),
                        ),
                    ],
                  ),
                ),
                Divider(height: 16, color: border),
                // Scrollable sections
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Category ──────────────────────────────────
                        sectionHeader(
                            _t('category'),
                            Icons.category_rounded,
                            const Color(0xFF2563EB),
                            tempCat != 'all',
                            () => setSheet(() => tempCat = 'all')),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 3.0,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          children:
                              ['all', ...kCategories].map(catCard).toList(),
                        ),
                        const SizedBox(height: 28),
                        // ── Region ────────────────────────────────────
                        sectionHeader(
                            _t('region'),
                            Icons.location_on_rounded,
                            const Color(0xFF16A34A),
                            tempReg != 'all',
                            () => setSheet(() => tempReg = 'all')),
                        ...['all', ...kRegions].map(regionRow),
                        const SizedBox(height: 28),
                        // ── Employment type ───────────────────────────
                        sectionHeader(
                            _t('employment_type'),
                            Icons.work_outline_rounded,
                            const Color(0xFF7C3AED),
                            tempEmp != 'all',
                            () => setSheet(() => tempEmp = 'all')),
                        ...kEmploymentTypes.map(empBtn),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                // Apply button
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, 8, 20, MediaQuery.of(ctx).padding.bottom + 20),
                  child: SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = tempCat;
                          _selectedRegion = tempReg;
                          _selectedEmpType = tempEmp;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(_t('apply_filters'),
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    appLocale.removeListener(_rebuild);
    appThemeMode.removeListener(_rebuild);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _reloadFavorites() async {
    final ids = await FavoritesService.load();
    if (mounted) setState(() => _savedIds = ids);
  }

  Future<void> _toggleFavorite(String jobId) async {
    await FavoritesService.toggle(jobId);
    await _reloadFavorites();
  }

  void _openDetail(Job job) {
    Navigator.push(context,
            MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)))
        .then((_) => _reloadFavorites());
  }

  // Slide-up "separate window" for post-job
  void _openPostJob() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const PostJobScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ).then((_) => _reloadFavorites());
  }

  void _openNotifSheet() {
    final uid = AuthService.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final isDark = appThemeMode.value == ThemeMode.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotifSheet(uid: uid, isDark: isDark),
    );
  }

  List<Job> _filterJobs(List<Job> jobs) {
    var r = jobs;
    if (_selectedCategory != 'all') {
      r = r.where((j) => j.category == _selectedCategory).toList();
    }
    if (_selectedRegion != 'all') {
      r = r.where((j) => j.region == _selectedRegion).toList();
    }
    if (_selectedEmpType != 'all') {
      r = r.where((j) => j.employmentType == _selectedEmpType).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      r = r
          .where((j) =>
              j.title.toLowerCase().contains(q) ||
              j.salary.toLowerCase().contains(q) ||
              j.description.toLowerCase().contains(q))
          .toList();
    }
    return r;
  }

  String _initials() {
    final u = AuthService.currentUser;
    final name = u?.displayName ?? u?.email ?? u?.phoneNumber ?? 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isEmpty ? 'U' : name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appThemeMode.value == ThemeMode.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFF);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final dividerColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final searchFill =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgColor,
      // ── App bar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ishbor',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 24,
                color: Color(0xFF2563EB),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'beta',
                style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        actions: [
          // Notification bell
          StreamBuilder<int>(
            stream: () {
              final uid = AuthService.currentUser?.uid ?? '';
              return uid.isNotEmpty
                  ? FirestoreService.unreadNotifCount(uid)
                  : Stream.value(0);
            }(),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return GestureDetector(
                onTap: _openNotifSheet,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color:
                              isDark ? dividerColor : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          count > 0
                              ? Icons.notifications_rounded
                              : Icons.notifications_outlined,
                          color: count > 0
                              ? const Color(0xFF2563EB)
                              : textSecondary,
                          size: 22,
                        ),
                      ),
                      if (count > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: surfaceColor, width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              count > 9 ? '9+' : '$count',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Avatar
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile')
                .then((_) => _reloadFavorites()),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                _initials(),
                style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w800,
                    fontSize: 14),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: dividerColor),
        ),
      ),
      // ── Body ─────────────────────────────────────────────────────────────
      body: ResponsiveBody(
          child: StreamBuilder<List<Job>>(
        stream: FirestoreService.jobsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                _t('error_load'),
                style: TextStyle(color: textSecondary),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            );
          }

          final allJobs = snapshot.data!;
          final filteredAll = _filterJobs(allJobs);
          final filteredSaved = _filterJobs(
              allJobs.where((j) => _savedIds.contains(j.id)).toList());

          return Column(
            children: [
              // ── Search + Filter row ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: TextStyle(color: textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: _t('search_hint'),
                            hintStyle:
                                TextStyle(color: textSecondary, fontSize: 14),
                            prefixIcon: Icon(Icons.search_rounded,
                                size: 20, color: textSecondary),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.close_rounded,
                                        size: 18, color: textSecondary),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 13),
                            isDense: true,
                            filled: true,
                            fillColor: searchFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: Color(0xFF2563EB), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Filter icon button
                    GestureDetector(
                      onTap: _openFilterSheet,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _activeFilterCount > 0
                                  ? const Color(0xFF2563EB)
                                  : surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _activeFilterCount > 0
                                    ? const Color(0xFF2563EB)
                                    : dividerColor,
                                width: 1.5,
                              ),
                              boxShadow: [
                                if (_activeFilterCount > 0)
                                  BoxShadow(
                                    color: const Color(0xFF2563EB)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                              ],
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              size: 22,
                              color: _activeFilterCount > 0
                                  ? Colors.white
                                  : textSecondary,
                            ),
                          ),
                          if (_activeFilterCount > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF97316),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: bgColor, width: 1.5),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$_activeFilterCount',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Active filter chips (only when filters are active) ─────
              if (_activeFilterCount > 0)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      if (_selectedCategory != 'all')
                        _ActiveChip(
                          label: _t(_selectedCategory),
                          color: kCategoryColors[_selectedCategory] ??
                              const Color(0xFF2563EB),
                          icon: kCategoryIcons[_selectedCategory] ??
                              Icons.work_outline,
                          onRemove: () =>
                              setState(() => _selectedCategory = 'all'),
                        ),
                      if (_selectedRegion != 'all')
                        _ActiveChip(
                          label: _t(_selectedRegion),
                          color: const Color(0xFF059669),
                          icon: Icons.location_on_rounded,
                          onRemove: () =>
                              setState(() => _selectedRegion = 'all'),
                        ),
                      if (_selectedEmpType != 'all')
                        _ActiveChip(
                          label: _t(_selectedEmpType),
                          color: kEmpTypeColors[_selectedEmpType] ??
                              const Color(0xFF2563EB),
                          icon: kEmpTypeIcons[_selectedEmpType] ??
                              Icons.work_outline,
                          onRemove: () =>
                              setState(() => _selectedEmpType = 'all'),
                        ),
                    ],
                  ),
                ),

              // ── Job lists + Chats (IndexedStack keeps scroll on tab switch) ──
              Expanded(
                child: IndexedStack(
                  index: _tab,
                  children: [
                    _JobList(
                      jobs: filteredAll,
                      savedIds: _savedIds,
                      onTap: _openDetail,
                      onToggle: _toggleFavorite,
                      emptyMessage: _searchQuery.isNotEmpty ||
                              _selectedCategory != 'all' ||
                              _selectedRegion != 'all' ||
                              _selectedEmpType != 'all'
                          ? _t('no_results')
                          : _t('no_jobs'),
                      isDark: isDark,
                      isFiltered: _searchQuery.isNotEmpty ||
                          _selectedCategory != 'all' ||
                          _selectedRegion != 'all' ||
                          _selectedEmpType != 'all',
                    ),
                    // ── My Chats tab ────────────────────────────────────
                    _MyChatsTab(
                      uid: AuthService.currentUser?.uid ?? '',
                      t: _t,
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      dividerColor: dividerColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    _JobList(
                      jobs: filteredSaved,
                      savedIds: _savedIds,
                      onTap: _openDetail,
                      onToggle: _toggleFavorite,
                      emptyMessage: _t('no_saved'),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      )),
      // ── Bottom NavigationBar ─────────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _navIndex,
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFF2563EB).withValues(alpha: 0.13),
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) {
            if (i == 0 || i == 1 || i == 2) {
              setState(() {
                _navIndex = i;
                _tab = i;
              });
            } else if (i == 3) {
              Navigator.pushNamed(context, '/profile')
                  .then((_) => _reloadFavorites());
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon:
                  const Icon(Icons.home_rounded, color: Color(0xFF2563EB)),
              label: _t('all_jobs'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: const Icon(Icons.chat_bubble_rounded,
                  color: Color(0xFF2563EB)),
              label: _t('my_chats'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.bookmark_border_rounded),
              selectedIcon:
                  const Icon(Icons.bookmark_rounded, color: Color(0xFF2563EB)),
              label: _t('saved_jobs'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon:
                  const Icon(Icons.person_rounded, color: Color(0xFF2563EB)),
              label: _t('profile'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Job list ──────────────────────────────────────────────────────────────────

class _JobList extends StatelessWidget {
  final List<Job> jobs;
  final Set<String> savedIds;
  final void Function(Job) onTap;
  final void Function(String) onToggle;
  final String emptyMessage;
  final bool isDark;
  final bool isFiltered;
  final VoidCallback? onPostJob;
  final String? postJobLabel;

  const _JobList({
    required this.jobs,
    required this.savedIds,
    required this.onTap,
    required this.onToggle,
    required this.emptyMessage,
    required this.isDark,
    this.isFiltered = false,
    this.onPostJob,
    this.postJobLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return _EmptyState(
        message: emptyMessage,
        isDark: isDark,
        isFiltered: isFiltered,
        onPostJob: onPostJob,
        postJobLabel: postJobLabel,
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF2563EB),
      onRefresh: () async {},
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        itemCount: jobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final job = jobs[i];
          return _JobCard(
            job: job,
            isSaved: savedIds.contains(job.id),
            onTap: () => onTap(job),
            onToggle: () => onToggle(job.id),
            isDark: isDark,
          );
        },
      ),
    );
  }
}

// ── Job card ──────────────────────────────────────────────────────────────────
class _JobCard extends StatelessWidget {
  final Job job;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final bool isDark;

  const _JobCard({
    required this.job,
    required this.isSaved,
    required this.onTap,
    required this.onToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = kCategoryColors[job.category] ?? const Color(0xFF2563EB);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final catIcon = kCategoryIcons[job.category] ?? Icons.work_outline_rounded;
    final empColor =
        kEmpTypeColors[job.employmentType] ?? const Color(0xFF2563EB);
    final empIcon = kEmpTypeIcons[job.employmentType] ?? Icons.work_outline;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: category icon box ───────────────────────────────
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(catIcon, size: 28, color: accent),
              ),
              const SizedBox(width: 12),

              // ── Right: content ────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row + bookmark
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            job.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              height: 1.3,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onToggle,
                          behavior: HitTestBehavior.opaque,
                          child: Icon(
                            isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 22,
                            color: isSaved ? accent : textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Category label
                    Text(
                      L10n.t(job.category, appLocale.value),
                      style: TextStyle(
                        fontSize: 13,
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Info chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _InfoChip(
                          icon: Icons.payments_outlined,
                          label: job.salary,
                          color: accent,
                        ),
                        if (job.region.isNotEmpty)
                          _InfoChip(
                            icon: Icons.location_on_rounded,
                            label: L10n.t(job.region, appLocale.value),
                            color: const Color(0xFF059669),
                          ),
                        if (job.employmentType.isNotEmpty)
                          _InfoChip(
                            icon: empIcon,
                            label: L10n.t(job.employmentType, appLocale.value),
                            color: empColor,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Phone row
                    Row(
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 14, color: textSecondary),
                        const SizedBox(width: 5),
                        Text(
                          job.phone,
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Small reusable info chip used inside job cards
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 6, 11, 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  final bool isDark;
  final bool isFiltered;
  final VoidCallback? onPostJob;
  final String? postJobLabel;
  const _EmptyState({
    required this.message,
    required this.isDark,
    this.isFiltered = false,
    this.onPostJob,
    this.postJobLabel,
  });

  @override
  Widget build(BuildContext context) {
    final textSec = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                isFiltered
                    ? Icons.search_off_rounded
                    : Icons.work_outline_rounded,
                color: const Color(0xFF2563EB),
                size: 46,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSec,
                fontSize: 16,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!isFiltered && onPostJob != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: onPostJob,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    postJobLabel ?? '',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Active filter chip shown in the filter bar ─────────────────────────────
class _ActiveChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onRemove;
  const _ActiveChip(
      {required this.label,
      required this.color,
      required this.icon,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.fromLTRB(8, 5, 6, 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 13, color: color),
          ),
        ],
      ),
    );
  }
}

// ── My Chats tab (seeker view — conversations they started) ──────────────────
class _MyChatsTab extends StatelessWidget {
  final String uid;
  final String Function(String) t;
  final bool isDark;
  final Color surfaceColor;
  final Color dividerColor;
  final Color textPrimary;
  final Color textSecondary;

  const _MyChatsTab({
    required this.uid,
    required this.t,
    required this.isDark,
    required this.surfaceColor,
    required this.dividerColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '< 1 min';
    if (diff.inHours < 1) return '${diff.inMinutes} min';
    if (diff.inDays < 1) return '${diff.inHours} h';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) {
      return Center(
        child: Text(t('no_chats'),
            style: TextStyle(color: textSecondary, fontSize: 14)),
      );
    }

    return StreamBuilder<List<ChatMeta>>(
      stream: FirestoreService.myChatsStream(uid),
      builder: (ctx, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Xatolik: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2563EB),
              strokeWidth: 2,
            ),
          );
        }
        final chats = snapshot.data ?? [];
        if (chats.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded,
                        color: Color(0xFF2563EB), size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t('no_chats'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: textSecondary, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: chats.length,
          itemBuilder: (_, i) {
            final chat = chats[i];
            final timeLabel = _timeLabel(chat.lastAt);
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    jobId: chat.jobId,
                    jobTitle: chat.jobTitle,
                    seekerUid: chat.seekerUid,
                    posterUid: chat.posterUid,
                    opponentName: chat.jobTitle,
                  ),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: dividerColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(Icons.work_outline_rounded,
                          color: Color(0xFF2563EB), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chat.jobTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            chat.lastMsg.isNotEmpty ? chat.lastMsg : '...',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeLabel,
                      style: TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Notification bottom sheet ─────────────────────────────────────────────────
class _NotifSheet extends StatelessWidget {
  final String uid;
  final bool isDark;

  const _NotifSheet({required this.uid, required this.isDark});

  String _timeAgo(DateTime dt, String lang) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return L10n.t('just_now', lang);
    if (diff.inHours < 1) {
      return L10n.t('min_ago', lang).replaceAll('{n}', '${diff.inMinutes}');
    }
    if (diff.inDays < 1) {
      return L10n.t('hr_ago', lang).replaceAll('{n}', '${diff.inHours}');
    }
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final lang = appLocale.value;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFF);
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPri = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSec = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final divider = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  L10n.t('notifications', lang),
                  style: TextStyle(
                    color: textPri,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                // Mark all read button
                TextButton(
                  onPressed: () => FirestoreService.markAllNotifsRead(uid),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    backgroundColor:
                        const Color(0xFF2563EB).withValues(alpha: 0.1),
                  ),
                  child: Text(
                    L10n.t('mark_all_read', lang),
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: divider),
          // Notifications list
          Flexible(
            child: StreamBuilder<List<NotifItem>>(
              stream: FirestoreService.notificationsStream(uid),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF2563EB))),
                  );
                }
                final notifs = snap.data ?? [];
                if (notifs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.notifications_off_outlined,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          L10n.t('no_notifications', lang),
                          style: TextStyle(
                            color: textSec,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: notifs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final n = notifs[i];
                    final isMsg = n.type == 'message';
                    final accent = isMsg
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF16A34A);
                    return GestureDetector(
                      onTap: () async {
                        if (!n.isRead) {
                          await FirestoreService.markNotifRead(uid, n.id);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: n.isRead
                              ? surface
                              : accent.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: n.isRead
                                ? divider
                                : accent.withValues(alpha: 0.3),
                            width: n.isRead ? 1 : 1.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isMsg
                                    ? Icons.chat_bubble_rounded
                                    : Icons.work_rounded,
                                color: accent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          n.title,
                                          style: TextStyle(
                                            color: textPri,
                                            fontSize: 14,
                                            fontWeight: n.isRead
                                                ? FontWeight.w500
                                                : FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (!n.isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: accent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    n.body,
                                    style: TextStyle(
                                      color: textSec,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _timeAgo(n.createdAt, lang),
                                    style: TextStyle(
                                      color: textSec,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}
