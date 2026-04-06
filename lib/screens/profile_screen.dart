import 'package:flutter/material.dart';
import '../core/app_locale.dart';
import '../core/app_theme.dart';
import '../core/responsive.dart';
import '../core/categories.dart';
import '../core/l10n.dart';
import '../models/job.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/role_service.dart';
import '../services/user_service.dart';
import 'chat_screen.dart';
import 'job_detail_screen.dart';
import 'post_job_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;
  int _postCount = 0;

  String _t(String k) => L10n.t(k, appLocale.value);

  @override
  void initState() {
    super.initState();
    appLocale.addListener(_rebuild);
    appThemeMode.addListener(_rebuild);
    final user = AuthService.currentUser;
    _nameCtrl.text = user?.displayName ?? '';
    _loadPostCount();
  }

  void _rebuild() => setState(() {});

  Future<void> _loadPostCount() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    FirestoreService.myJobsStream(uid).first.then((jobs) {
      if (mounted) setState(() => _postCount = jobs.length);
    });
  }

  @override
  void dispose() {
    appLocale.removeListener(_rebuild);
    appThemeMode.removeListener(_rebuild);
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await AuthService.currentUser?.updateDisplayName(name);
      final user = AuthService.currentUser;
      if (user != null) {
        await UserService.saveUser(user, displayName: name);
      }
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t('profile_updated')),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  void _openDetail(Job job) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
    );
  }

  void _openEditJob(Job job) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PostJobScreen(initialJob: job),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  Future<void> _deleteJob(Job job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('delete_job')),
        content: Text(_t('confirm_delete_job')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: Text(_t('delete')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirestoreService.deleteJobAndCleanup(job.id, job.postedByUid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_t('job_deleted')),
          backgroundColor: const Color(0xFF6B7280),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  Future<void> _linkGoogle() async {
    setState(() => _saving = true);
    try {
      final cred = await AuthService.linkWithGoogle();
      if (cred == null) return; // user cancelled
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_t('link_google_success')),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showChangePasswordSheet() {
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool visible = false;
    bool loading = false;

    final isDark = appThemeMode.value == ThemeMode.dark;
    const accent = Color(0xFF7C3AED);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.lock_outline_rounded,
                        color: accent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    _t('change_password'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                // New password
                TextField(
                  controller: newPassCtrl,
                  obscureText: !visible,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: _t('new_password'),
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: accent, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                          visible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF9CA3AF),
                          size: 20),
                      onPressed: () => setSheet(() => visible = !visible),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFFE5E7EB), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: accent, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                // Confirm
                TextField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: _t('confirm_password'),
                    prefixIcon: const Icon(Icons.lock_reset_rounded,
                        color: accent, size: 20),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFFE5E7EB), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: accent, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            if (newPassCtrl.text.length < 6) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                content: Text(_t('pass_error')),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.all(16),
                              ));
                              return;
                            }
                            if (newPassCtrl.text != confirmCtrl.text) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                content: Text(_t('confirm_error')),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.all(16),
                              ));
                              return;
                            }
                            setSheet(() => loading = true);
                            try {
                              await AuthService.changePassword(
                                  newPassCtrl.text);
                              if (ctx.mounted) {
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(_t('password_changed')),
                                  backgroundColor: const Color(0xFF16A34A),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.all(16),
                                ));
                              }
                            } catch (e) {
                              setSheet(() => loading = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: const Color(0xFFEF4444),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.all(16),
                                ));
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      disabledBackgroundColor: accent.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : Text(_t('save'),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isEmpty ? 'U' : name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appThemeMode.value == ThemeMode.dark;
    final user = AuthService.currentUser;
    final name = user?.displayName ?? '';
    final initials = _getInitials(
        name.isNotEmpty ? name : (user?.email ?? user?.phoneNumber ?? 'U'));
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFF);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bgColor,
      body: ResponsiveBody(
          child: CustomScrollView(
        slivers: [
          // ── Gradient header ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF1E3A8A),
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _editing ? Icons.close_rounded : Icons.edit_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () => setState(() => _editing = !_editing),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F2167),
                      Color(0xFF1E3A8A),
                      Color(0xFF2563EB)
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      // Avatar
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF60A5FA), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name.isNotEmpty
                            ? name
                            : (user?.email ?? user?.phoneNumber ?? ''),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? user?.phoneNumber ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Stats row ─────────────────────────────────────────
                  _StatsRow(
                    postCount: _postCount,
                    t: _t,
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: 20),

                  // ── My Jobs section ───────────────────────────────────
                  _MyJobsSection(
                    uid: AuthService.currentUser?.uid ?? '',
                    t: _t,
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: _openDetail,
                    onEdit: _openEditJob,
                    onDelete: _deleteJob,
                  ),
                  const SizedBox(height: 20),

                  // ── Incoming questions section ─────────────────────────
                  _IncomingChatsSection(
                    uid: AuthService.currentUser?.uid ?? '',
                    t: _t,
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 20),

                  // ── Edit name section ─────────────────────────────────
                  if (_editing) ...[
                    _SectionCard(
                      title: _t('edit_profile'),
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            style: TextStyle(color: textPrimary),
                            decoration: InputDecoration(
                              labelText: _t('display_name'),
                              hintText: _t('display_name_hint'),
                              prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 20),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: borderColor, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF2563EB), width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      setState(() => _editing = false),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: borderColor),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                  child: Text(_t('cancel'),
                                      style: TextStyle(color: textSecondary)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: _saving ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                  child: _saving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        )
                                      : Text(_t('save')),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Account info ──────────────────────────────────────
                  _SectionCard(
                    title: _t('account'),
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    child: Column(
                      children: [
                        if (user?.phoneNumber != null)
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            label: _t('phone_number'),
                            value: user!.phoneNumber!,
                            isDark: isDark,
                          ),
                        if (user?.email != null)
                          _InfoRow(
                            icon: Icons.email_outlined,
                            label: _t('email_address'),
                            value: user!.email!,
                            isDark: isDark,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Security section ──────────────────────────────────
                  _SectionCard(
                    title: _t('security'),
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    child: Column(
                      children: [
                        // Link Google — only if not already linked
                        if (!AuthService.linkedProviders.contains('google.com'))
                          _ActionTile(
                            icon: Icons.g_mobiledata_rounded,
                            label: _t('link_google'),
                            iconColor: const Color(0xFF4285F4),
                            isDark: isDark,
                            surfaceColor: surfaceColor,
                            borderColor: borderColor,
                            onTap: _saving ? () {} : _linkGoogle,
                          )
                        else
                          _ActionTile(
                            icon: Icons.g_mobiledata_rounded,
                            label: _t('google_linked'),
                            iconColor: const Color(0xFF16A34A),
                            isDark: isDark,
                            surfaceColor: surfaceColor,
                            borderColor: borderColor,
                            onTap: () {},
                          ),
                        // Change password — only for email/password users
                        if (AuthService.linkedProviders
                            .contains('password')) ...[
                          const SizedBox(height: 8),
                          _ActionTile(
                            icon: Icons.lock_outline_rounded,
                            label: _t('change_password'),
                            iconColor: const Color(0xFF7C3AED),
                            isDark: isDark,
                            surfaceColor: surfaceColor,
                            borderColor: borderColor,
                            onTap: _showChangePasswordSheet,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Settings shortcut ─────────────────────────────────
                  _ActionTile(
                    icon: Icons.settings_outlined,
                    label: _t('settings'),
                    iconColor: const Color(0xFF6B7280),
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),
                  const SizedBox(height: 8),

                  // ── Change role ───────────────────────────────────────
                  _ActionTile(
                    icon: Icons.swap_horiz_rounded,
                    label: "Rolni o'zgartirish",
                    iconColor: const Color(0xFF2563EB),
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    onTap: () async {
                      await RoleService.clearRole();
                      if (!mounted) return;
                      Navigator.pushReplacementNamed(context, '/role-select');
                    },
                  ),
                  const SizedBox(height: 8),

                  // ── Sign out ──────────────────────────────────────────
                  _ActionTile(
                    icon: Icons.logout_rounded,
                    label: _t('sign_out'),
                    iconColor: const Color(0xFFEF4444),
                    labelColor: const Color(0xFFEF4444),
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    onTap: _logout,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      )),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int postCount;
  final String Function(String) t;
  final bool isDark;
  final Color surfaceColor;
  final Color borderColor;

  const _StatsRow({
    required this.postCount,
    required this.t,
    required this.isDark,
    required this.surfaceColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StatItem(
            value: postCount.toString(),
            label: t('posts_count'),
            icon: Icons.campaign_outlined,
            color: const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;
  final Color surfaceColor;
  final Color borderColor;

  const _SectionCard({
    required this.title,
    required this.child,
    required this.isDark,
    required this.surfaceColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500)),
                Text(value,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.white : const Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action tile ───────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color? labelColor;
  final bool isDark;
  final Color surfaceColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.isDark,
    required this.surfaceColor,
    required this.borderColor,
    required this.onTap,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        labelColor ?? (isDark ? Colors.white : const Color(0xFF0F172A));

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: textColor),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFD1D5DB),
                  size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── My Jobs section ───────────────────────────────────────────────────────────

class _MyJobsSection extends StatelessWidget {
  final String uid;
  final String Function(String) t;
  final bool isDark;
  final Color surfaceColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final void Function(Job) onTap;
  final void Function(Job) onEdit;
  final Future<void> Function(Job) onDelete;

  const _MyJobsSection({
    required this.uid,
    required this.t,
    required this.isDark,
    required this.surfaceColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            t('my_jobs'),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: textPrimary,
            ),
          ),
        ),
        StreamBuilder<List<Job>>(
          stream: FirestoreService.myJobsStream(uid),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Color(0xFF2563EB),
                    strokeWidth: 2,
                  ),
                ),
              );
            }
            final jobs = snapshot.data ?? [];
            if (jobs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Center(
                  child: Text(
                    t('no_my_jobs'),
                    style: TextStyle(color: textSecondary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return Column(
              children: jobs
                  .map((job) => _MyJobCard(
                        job: job,
                        t: t,
                        isDark: isDark,
                        surfaceColor: surfaceColor,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onTap: () => onTap(job),
                        onEdit: () => onEdit(job),
                        onDelete: () => onDelete(job),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _MyJobCard extends StatelessWidget {
  final Job job;
  final String Function(String) t;
  final bool isDark;
  final Color surfaceColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MyJobCard({
    required this.job,
    required this.t,
    required this.isDark,
    required this.surfaceColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final accent = kCategoryColors[job.category] ?? const Color(0xFF2563EB);
    final catIcon = kCategoryIcons[job.category] ?? Icons.work_outline_rounded;
    final dateStr =
        '${job.createdAt.day.toString().padLeft(2, '0')}.${job.createdAt.month.toString().padLeft(2, '0')}.${job.createdAt.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(catIcon, color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.payments_outlined,
                              size: 13, color: Color(0xFF16A34A)),
                          const SizedBox(width: 4),
                          Text(
                            job.salary,
                            style: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t('posted_at')}: $dateStr',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Column(
                  children: [
                    _IconBtn(
                      icon: Icons.edit_rounded,
                      color: const Color(0xFF7C3AED),
                      onTap: onEdit,
                    ),
                    const SizedBox(height: 6),
                    _IconBtn(
                      icon: Icons.delete_outline_rounded,
                      color: const Color(0xFFEF4444),
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

// ── Incoming chats section ────────────────────────────────────────────────────

class _IncomingChatsSection extends StatelessWidget {
  final String uid;
  final String Function(String) t;
  final bool isDark;
  final Color surfaceColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const _IncomingChatsSection({
    required this.uid,
    required this.t,
    required this.isDark,
    required this.surfaceColor,
    required this.borderColor,
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
    if (uid.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  size: 18, color: Color(0xFF059669)),
              const SizedBox(width: 8),
              Text(
                t('incoming_questions'),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
        StreamBuilder<List<ChatMeta>>(
          stream: FirestoreService.incomingChatsStream(uid),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Color(0xFF059669),
                    strokeWidth: 2,
                  ),
                ),
              );
            }
            final chats = snapshot.data ?? [];
            if (chats.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Center(
                  child: Text(
                    t('no_incoming'),
                    style: TextStyle(color: textSecondary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return Column(
              children: chats
                  .map((chat) => _ChatMetaCard(
                        chat: chat,
                        isDark: isDark,
                        surfaceColor: surfaceColor,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        timeLabel: _timeLabel(chat.lastAt),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                jobId: chat.jobId,
                                jobTitle: chat.jobTitle,
                                seekerUid: chat.seekerUid,
                                posterUid: chat.posterUid,
                                opponentName: chat.seekerName,
                              ),
                            ),
                          );
                        },
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ChatMetaCard extends StatelessWidget {
  final ChatMeta chat;
  final bool isDark;
  final Color surfaceColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final String timeLabel;
  final VoidCallback onTap;

  const _ChatMetaCard({
    required this.chat,
    required this.isDark,
    required this.surfaceColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.timeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_outline_rounded,
                  color: Color(0xFF059669), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.seekerName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chat.jobTitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.w500,
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
                        color: textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeLabel,
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: Color(0xFF059669)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
