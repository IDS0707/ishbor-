import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_locale.dart';
import '../core/app_theme.dart'; // also exports persistTheme
import '../core/responsive.dart';
import '../core/l10n.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _t(String k) => L10n.t(k, appLocale.value);

  @override
  void initState() {
    super.initState();
    appLocale.addListener(_rebuild);
    appThemeMode.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    appLocale.removeListener(_rebuild);
    appThemeMode.removeListener(_rebuild);
    super.dispose();
  }

  Future<void> _logout() async {
    await AuthService.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _showDeleteConfirm() async {
    final isDark = appThemeMode.value == ThemeMode.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_t('delete_account'),
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700)),
        content: Text(_t('confirm_delete'),
            style: const TextStyle(color: Color(0xFF6B7280), height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(_t('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _doDeleteAccount();
  }

  Future<void> _doDeleteAccount() async {
    try {
      await AuthService.currentUser?.delete();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        await _handleRecentLoginRequired();
      } else {
        _showErrorSnack(_t('error_generic'));
      }
    } catch (e) {
      _showErrorSnack(_t('error_generic'));
    }
  }

  Future<void> _handleRecentLoginRequired() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    final providers = user.providerData.map((p) => p.providerId).toSet();

    // ── Google user ────────────────────────────────────────────────────────
    if (providers.contains('google.com')) {
      try {
        final reauthed = await AuthService.reauthenticateCurrentUser();
        if (reauthed) {
          await _retryDelete();
          return;
        }
      } catch (_) {}
      _showErrorSnack(_t('reauth_failed'));
      return;
    }

    // ── Email / password user ──────────────────────────────────────────────
    if (providers.contains('password')) {
      await _showPasswordReauthDialog(user.email ?? '');
      return;
    }

    // ── Phone (or unknown) user → sign out and re-login ────────────────────
    await _showSignOutReloginDialog();
  }

  /// Password re-auth dialog for email/password users.
  Future<void> _showPasswordReauthDialog(String email) async {
    final isDark = appThemeMode.value == ThemeMode.dark;
    final passCtrl = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool loading = false;
        bool obscure = true;
        String? errorMsg;

        return StatefulBuilder(
          builder: (ctx, setDlg) {
            final surfaceColor =
                isDark ? const Color(0xFF1E293B) : Colors.white;
            final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
            final borderColor =
                isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
            final fillColor =
                isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);

            return AlertDialog(
              backgroundColor: surfaceColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_outline_rounded,
                        color: Color(0xFFEF4444), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _t('confirm_identity'),
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('enter_password_to_delete'),
                    style: const TextStyle(
                        color: Color(0xFF6B7280), height: 1.5, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passCtrl,
                    obscureText: obscure,
                    enabled: !loading,
                    autofocus: true,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      hintText: _t('password'),
                      hintStyle: const TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 14),
                      filled: true,
                      fillColor: fillColor,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFEF4444), width: 2),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF9CA3AF),
                          size: 20,
                        ),
                        onPressed: () => setDlg(() => obscure = !obscure),
                      ),
                    ),
                  ),
                  if (errorMsg != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Color(0xFFEF4444), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMsg!,
                              style: const TextStyle(
                                  color: Color(0xFFEF4444), fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                ],
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: loading ? null : () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_t('cancel'),
                              style:
                                  TextStyle(color: textPrimary, fontSize: 15)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: loading
                              ? null
                              : () async {
                                  final pw = passCtrl.text.trim();
                                  if (pw.isEmpty) {
                                    setDlg(() =>
                                        errorMsg = _t('password_required'));
                                    return;
                                  }
                                  setDlg(() {
                                    loading = true;
                                    errorMsg = null;
                                  });
                                  try {
                                    await AuthService.reauthenticateWithEmail(
                                        email, pw);
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    await _retryDelete();
                                  } on FirebaseAuthException catch (e) {
                                    setDlg(() {
                                      loading = false;
                                      errorMsg = (e.code == 'wrong-password' ||
                                              e.code == 'invalid-credential')
                                          ? _t('wrong_password')
                                          : (e.message ?? _t('reauth_failed'));
                                    });
                                  } catch (e) {
                                    setDlg(() {
                                      loading = false;
                                      errorMsg = e.toString();
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_t('confirm_delete_action'),
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    passCtrl.dispose();
  }

  Future<void> _retryDelete() async {
    try {
      await AuthService.currentUser?.delete();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException {
      _showErrorSnack(_t('error_generic'));
    } catch (e) {
      _showErrorSnack(_t('error_generic'));
    }
  }

  Future<void> _showSignOutReloginDialog() async {
    if (!mounted) return;
    final isDark = appThemeMode.value == ThemeMode.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    final shouldReLogin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _t('relogin_required'),
          style: TextStyle(
              color: textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          _t('relogin_to_delete'),
          style: const TextStyle(color: Color(0xFF6B7280), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(_t('sign_out_and_relogin')),
          ),
        ],
      ),
    );

    if (shouldReLogin == true && mounted) {
      await AuthService.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showErrorSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
    final dividerColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('settings'),
          style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 18, color: textPrimary),
        ),
      ),
      body: ResponsiveBody(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Appearance ────────────────────────────────────────────
            _SectionHeader(title: _t('appearance'), color: textSecondary),
            _SettingsCard(
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              children: [
                _SwitchTile(
                  icon: Icons.dark_mode_rounded,
                  iconBg: const Color(0xFF1E293B),
                  iconColor: const Color(0xFF60A5FA),
                  title: _t('dark_mode'),
                  subtitle: isDark ? _t('dark_mode') : _t('light_mode'),
                  value: isDark,
                  onChanged: (v) async {
                    appThemeMode.value = v ? ThemeMode.dark : ThemeMode.light;
                    await persistTheme(v);
                  },
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Language ──────────────────────────────────────────────
            _SectionHeader(title: _t('language'), color: textSecondary),
            _SettingsCard(
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              children: [
                _LangTile(
                  code: 'uz',
                  flag: '🇺🇿',
                  label: "O'zbekcha (lotin)",
                  isDark: isDark,
                  dividerColor: dividerColor,
                ),
                _LangTile(
                  code: 'uz_kr',
                  flag: '🇺🇿',
                  label: 'Ўзбекча (кирилл)',
                  isDark: isDark,
                  dividerColor: dividerColor,
                ),
                _LangTile(
                  code: 'ru',
                  flag: '🇷🇺',
                  label: 'Русский',
                  isDark: isDark,
                  dividerColor: dividerColor,
                ),
                _LangTile(
                  code: 'en',
                  flag: '🇬🇧',
                  label: 'English',
                  isDark: isDark,
                  showDivider: false,
                  dividerColor: dividerColor,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Account ────────────────────────────────────────────────
            _SectionHeader(title: _t('account'), color: textSecondary),
            _SettingsCard(
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              children: [
                _ActionTile(
                  icon: Icons.logout_rounded,
                  iconBg: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  iconColor: const Color(0xFFEF4444),
                  title: _t('sign_out'),
                  titleColor: const Color(0xFFEF4444),
                  isDark: isDark,
                  dividerColor: dividerColor,
                  onTap: _logout,
                ),
                _ActionTile(
                  icon: Icons.delete_outline_rounded,
                  iconBg: const Color(0xFFEF4444).withValues(alpha: 0.08),
                  iconColor: const Color(0xFFEF4444),
                  title: _t('delete_account'),
                  titleColor: const Color(0xFFEF4444),
                  isDark: isDark,
                  showDivider: false,
                  dividerColor: dividerColor,
                  onTap: _showDeleteConfirm,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── About ──────────────────────────────────────────────────
            _SectionHeader(title: _t('about'), color: textSecondary),
            _SettingsCard(
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              children: [
                _InfoTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0xFF2563EB),
                  title: _t('version'),
                  value: '1.0.0',
                  isDark: isDark,
                  dividerColor: dividerColor,
                ),
                _InfoTile(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: const Color(0xFF7C3AED),
                  title: _t('privacy_policy'),
                  value: '',
                  isDark: isDark,
                  dividerColor: dividerColor,
                  onTap: () async {
                    final uri = Uri.parse('https://ishbor.uz/privacy');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                _InfoTile(
                  icon: Icons.gavel_rounded,
                  iconColor: const Color(0xFF059669),
                  title: _t('terms_of_service'),
                  value: '',
                  isDark: isDark,
                  showDivider: false,
                  dividerColor: dividerColor,
                  onTap: () async {
                    final uri = Uri.parse('https://ishbor.uz/terms');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Footer
            Text(
              'Ishbor © 2026',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
          ],
        ),
      )),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.8,
          ),
        ),
      );
}

// ── Settings card (container with children) ───────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final Color surfaceColor;
  final Color borderColor;
  final List<Widget> children;

  const _SettingsCard({
    required this.surfaceColor,
    required this.borderColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(children: children),
      );
}

// ── Switch tile (dark mode) ───────────────────────────────────────────────────

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;
  final bool isDark;

  const _SwitchTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: textPrimary)),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: textSecondary)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }
}

// ── Language tile ─────────────────────────────────────────────────────────────

class _LangTile extends StatelessWidget {
  final String code;
  final String flag;
  final String label;
  final bool isDark;
  final Color dividerColor;
  final bool showDivider;

  const _LangTile({
    required this.code,
    required this.flag,
    required this.label,
    required this.isDark,
    required this.dividerColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = appLocale.value == code;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    return Column(
      children: [
        InkWell(
          onTap: () => appLocale.value = code,
          borderRadius: BorderRadius.vertical(
            top: showDivider ? Radius.zero : const Radius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: textPrimary),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF2563EB), size: 22)
                else
                  Icon(Icons.circle_outlined,
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFD1D5DB),
                      size: 22),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
              height: 1,
              thickness: 1,
              color: dividerColor,
              indent: 16,
              endIndent: 16),
      ],
    );
  }
}

// ── Action tile (sign out, delete) ────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final Color titleColor;
  final bool isDark;
  final Color dividerColor;
  final bool showDivider;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.titleColor,
    required this.isDark,
    required this.dividerColor,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: titleColor),
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
        if (showDivider)
          Divider(
              height: 1,
              thickness: 1,
              color: dividerColor,
              indent: 16,
              endIndent: 16),
      ],
    );
  }
}

// ── Info tile (version, links) ────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final bool isDark;
  final Color dividerColor;
  final bool showDivider;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.isDark,
    required this.dividerColor,
    this.showDivider = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF);

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: showDivider
              ? BorderRadius.zero
              : const BorderRadius.vertical(bottom: Radius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: textPrimary),
                  ),
                ),
                if (value.isNotEmpty)
                  Text(value,
                      style: TextStyle(fontSize: 13, color: textSecondary)),
                if (onTap != null)
                  Icon(Icons.chevron_right_rounded,
                      size: 20, color: textSecondary),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
              height: 1,
              thickness: 1,
              color: dividerColor,
              indent: 16,
              endIndent: 16),
      ],
    );
  }
}
