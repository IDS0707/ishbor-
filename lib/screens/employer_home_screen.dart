import 'package:flutter/material.dart';
import '../core/app_locale.dart';
import '../core/app_theme.dart';
import '../core/categories.dart';
import '../core/l10n.dart';
import '../models/job.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../core/responsive.dart';
import 'chat_screen.dart';
import 'job_detail_screen.dart';
import 'post_job_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EMPLOYER HOME SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class EmployerHomeScreen extends StatefulWidget {
  const EmployerHomeScreen({super.key});

  @override
  State<EmployerHomeScreen> createState() => _EmployerHomeScreenState();
}

class _EmployerHomeScreenState extends State<EmployerHomeScreen> {
  int _navIndex = 0; // 0 = My Jobs, 1 = Chats, 2 = Profile

  String get _uid => AuthService.currentUser?.uid ?? '';
  String get _displayName =>
      AuthService.currentUser?.displayName ?? 'Ish beruvchi';

  void _rebuild() => setState(() {});

  @override
  void initState() {
    super.initState();
    appLocale.addListener(_rebuild);
    appThemeMode.addListener(_rebuild);
  }

  @override
  void dispose() {
    appLocale.removeListener(_rebuild);
    appThemeMode.removeListener(_rebuild);
    super.dispose();
  }

  String _t(String k) => L10n.t(k, appLocale.value);

  void _openPostJob({Job? editJob}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostJobScreen(initialJob: editJob),
      ),
    );
  }

  void _openDetail(Job job) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
    );
  }

  Future<void> _deleteJob(Job job) async {
    final isDark = appThemeMode.value == ThemeMode.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _t('delete_job'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(_t('confirm_delete_job')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t('delete_job')),
          ),
        ],
      ),
    );
    if (confirmed == true && job.id.isNotEmpty) {
      await FirestoreService.deleteJobAndCleanup(job.id, job.postedByUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appThemeMode.value == ThemeMode.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final textPri = isDark ? Colors.white : const Color(0xFF111827);
    final textSec = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    Widget body;
    if (_navIndex == 0) {
      body = _MyJobsTab(
        uid: _uid,
        displayName: _displayName,
        isDark: isDark,
        bg: bg,
        surface: surface,
        border: border,
        textPri: textPri,
        textSec: textSec,
        t: _t,
        onAdd: () => _openPostJob(),
        onTap: _openDetail,
        onEdit: (j) => _openPostJob(editJob: j),
        onDelete: _deleteJob,
      );
    } else if (_navIndex == 1) {
      body = _IncomingChatsTab(
        uid: _uid,
        isDark: isDark,
        bg: bg,
        surface: surface,
        border: border,
        textPri: textPri,
        textSec: textSec,
        t: _t,
      );
    } else {
      body = _EmployerProfileTab(
        displayName: _displayName,
        isDark: isDark,
        bg: bg,
        surface: surface,
        border: border,
        textPri: textPri,
        textSec: textSec,
        t: _t,
        onSettings: () => Navigator.pushNamed(context, '/settings'),
        onRoleChange: () =>
            Navigator.pushReplacementNamed(context, '/role-select'),
        onSignOut: () async {
          await AuthService.signOut();
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        },
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: ResponsiveBody(child: body),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surface,
          border: Border(
            top: BorderSide(color: border, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _navIndex,
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFF16A34A).withValues(alpha: 0.13),
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) => setState(() => _navIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.work_outline_rounded),
              selectedIcon: Icon(Icons.work_rounded, color: Color(0xFF16A34A)),
              label: "E'lonlarim",
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon:
                  Icon(Icons.chat_bubble_rounded, color: Color(0xFF16A34A)),
              label: 'Arizalar',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon:
                  Icon(Icons.person_rounded, color: Color(0xFF16A34A)),
              label: 'Profil',
            ),
          ],
        ),
      ),
      floatingActionButton: _navIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _openPostJob(),
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text(
                "Yangi e'lon",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MY JOBS TAB
// ─────────────────────────────────────────────────────────────────────────────

class _MyJobsTab extends StatelessWidget {
  final String uid;
  final String displayName;
  final bool isDark;
  final Color bg;
  final Color surface;
  final Color border;
  final Color textPri;
  final Color textSec;
  final String Function(String) t;
  final VoidCallback onAdd;
  final void Function(Job) onTap;
  final void Function(Job) onEdit;
  final Future<void> Function(Job) onDelete;

  const _MyJobsTab({
    required this.uid,
    required this.displayName,
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.border,
    required this.textPri,
    required this.textSec,
    required this.t,
    required this.onAdd,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── App bar ─────────────────────────────────────────────────────
        SliverAppBar(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          floating: true,
          snap: true,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              const Text(
                'Ishbor',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF16A34A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Ish beruvchi',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings_outlined, color: textSec),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: border),
          ),
        ),

        // ── Greeting ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salom, $displayName 👋',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textPri,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Sizning faol e'lonlaringiz",
                  style: TextStyle(
                    fontSize: 15,
                    color: textSec,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Stats row ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: StreamBuilder<List<Job>>(
            stream: FirestoreService.myJobsStream(uid),
            builder: (ctx, snap) {
              final jobs = snap.data ?? [];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    _StatCard(
                      value: jobs.length.toString(),
                      label: "Jami e'lonlar",
                      icon: Icons.list_alt_rounded,
                      color: const Color(0xFF2563EB),
                      isDark: isDark,
                      surface: surface,
                      border: border,
                      textPri: textPri,
                      textSec: textSec,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      value: jobs.length.toString(),
                      label: 'Faol e\'lonlar',
                      icon: Icons.check_circle_outline_rounded,
                      color: const Color(0xFF16A34A),
                      isDark: isDark,
                      surface: surface,
                      border: border,
                      textPri: textPri,
                      textSec: textSec,
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // ── Add button ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text(
                  "Yangi ish e'loni qo'shish",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ),

        // ── Job list ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Mening e'lonlarim",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textPri,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),

        if (uid.isNotEmpty)
          StreamBuilder<List<Job>>(
            stream: FirestoreService.myJobsStream(uid),
            builder: (ctx, snap) {
              if (snap.hasError) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        t('error_load'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textSec, fontSize: 13),
                      ),
                    ),
                  ),
                );
              }
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                          color: Color(0xFF16A34A), strokeWidth: 2),
                    ),
                  ),
                );
              }
              final jobs = snap.data ?? [];
              if (jobs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF16A34A).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.work_off_outlined,
                            color: Color(0xFF16A34A),
                            size: 42,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t('no_my_jobs'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textSec,
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _EmployerJobCard(
                      job: jobs[i],
                      isDark: isDark,
                      surface: surface,
                      border: border,
                      textPri: textPri,
                      textSec: textSec,
                      t: t,
                      onTap: () => onTap(jobs[i]),
                      onEdit: () => onEdit(jobs[i]),
                      onDelete: () => onDelete(jobs[i]),
                    ),
                  ),
                  childCount: jobs.length,
                ),
              );
            },
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 110)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INCOMING CHATS TAB (applications from workers)
// ─────────────────────────────────────────────────────────────────────────────

class _IncomingChatsTab extends StatelessWidget {
  final String uid;
  final bool isDark;
  final Color bg;
  final Color surface;
  final Color border;
  final Color textPri;
  final Color textSec;
  final String Function(String) t;

  const _IncomingChatsTab({
    required this.uid,
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.border,
    required this.textPri,
    required this.textSec,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          color: surface,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    children: [
                      Text(
                        'Kelgan arizalar',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: textPri,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: border),
              ],
            ),
          ),
        ),

        // Chat list
        Expanded(
          child: StreamBuilder<List<ChatMeta>>(
            stream: FirestoreService.incomingChatsStream(uid),
            builder: (ctx, snap) {
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      t('error_load'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textSec, fontSize: 13),
                    ),
                  ),
                );
              }
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF16A34A), strokeWidth: 2),
                );
              }
              final chats = snap.data ?? [];
              if (chats.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF16A34A).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Color(0xFF16A34A),
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Hali hech qanday ariza kelmagan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textSec,
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: chats.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final c = chats[i];
                  return _ChatTile(
                    chat: c,
                    isDark: isDark,
                    surface: surface,
                    border: border,
                    textPri: textPri,
                    textSec: textSec,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          jobId: c.jobId,
                          jobTitle: c.jobTitle,
                          posterUid: c.posterUid,
                          seekerUid: c.seekerUid,
                          opponentName: c.seekerName,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPLOYER PROFILE TAB
// ─────────────────────────────────────────────────────────────────────────────

class _EmployerProfileTab extends StatelessWidget {
  final String displayName;
  final bool isDark;
  final Color bg;
  final Color surface;
  final Color border;
  final Color textPri;
  final Color textSec;
  final String Function(String) t;
  final VoidCallback onSettings;
  final VoidCallback onRoleChange;
  final VoidCallback onSignOut;

  const _EmployerProfileTab({
    required this.displayName,
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.border,
    required this.textPri,
    required this.textSec,
    required this.t,
    required this.onSettings,
    required this.onRoleChange,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Profil',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: textPri,
              ),
            ),
            const SizedBox(height: 24),

            // Avatar + name
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor:
                        const Color(0xFF16A34A).withValues(alpha: 0.15),
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textPri,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Ish beruvchi',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Actions
            _ProfileTile(
              icon: Icons.settings_outlined,
              label: t('settings'),
              iconColor: const Color(0xFF6B7280),
              isDark: isDark,
              surface: surface,
              border: border,
              textPri: textPri,
              onTap: onSettings,
            ),
            const SizedBox(height: 10),
            _ProfileTile(
              icon: Icons.swap_horiz_rounded,
              label: "Rolni o'zgartirish",
              iconColor: const Color(0xFF2563EB),
              isDark: isDark,
              surface: surface,
              border: border,
              textPri: textPri,
              onTap: onRoleChange,
            ),
            const SizedBox(height: 10),
            _ProfileTile(
              icon: Icons.logout_rounded,
              label: t('sign_out'),
              iconColor: const Color(0xFFDC2626),
              labelColor: const Color(0xFFDC2626),
              isDark: isDark,
              surface: surface,
              border: border,
              textPri: textPri,
              onTap: onSignOut,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final Color surface;
  final Color border;
  final Color textPri;
  final Color textSec;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textPri,
    required this.textSec,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textPri,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSec,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployerJobCard extends StatelessWidget {
  final Job job;
  final bool isDark;
  final Color surface;
  final Color border;
  final Color textPri;
  final Color textSec;
  final String Function(String) t;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EmployerJobCard({
    required this.job,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textPri,
    required this.textSec,
    required this.t,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final accent = kCategoryColors[job.category] ?? const Color(0xFF16A34A);
    final catIcon = kCategoryIcons[job.category] ?? Icons.work_outline_rounded;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(catIcon, size: 26, color: accent),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPri,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      L10n.t(job.category, appLocale.value),
                      style: TextStyle(
                        fontSize: 12,
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.payments_outlined, size: 14, color: textSec),
                        const SizedBox(width: 4),
                        Text(
                          job.salary,
                          style: TextStyle(
                            fontSize: 14,
                            color: textSec,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (job.region.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.location_on_rounded,
                              size: 14, color: textSec),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              L10n.t(job.region, appLocale.value),
                              style: TextStyle(
                                fontSize: 13,
                                color: textSec,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Edit / Delete
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: textSec, size: 22),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: surface,
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_rounded,
                            size: 18, color: Color(0xFF2563EB)),
                        const SizedBox(width: 10),
                        Text(
                          t('edit_job'),
                          style: TextStyle(
                              color: textPri, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded,
                            size: 18, color: Color(0xFFDC2626)),
                        const SizedBox(width: 10),
                        Text(
                          t('delete_job'),
                          style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatMeta chat;
  final bool isDark;
  final Color surface;
  final Color border;
  final Color textPri;
  final Color textSec;
  final VoidCallback onTap;

  const _ChatTile({
    required this.chat,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textPri,
    required this.textSec,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    const Color(0xFF16A34A).withValues(alpha: 0.12),
                child: Text(
                  chat.seekerName.isNotEmpty
                      ? chat.seekerName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16A34A),
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.seekerName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPri,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      chat.jobTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (chat.lastMsg.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        chat.lastMsg,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSec,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: textSec, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color? labelColor;
  final bool isDark;
  final Color surface;
  final Color border;
  final Color textPri;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textPri,
    required this.onTap,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: labelColor ?? textPri,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: border, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
