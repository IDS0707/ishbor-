import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_locale.dart';
import '../core/app_theme.dart';
import '../core/responsive.dart';
import '../core/categories.dart';
import '../core/l10n.dart';
import '../models/job.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import '../services/firestore_service.dart';
import 'chat_screen.dart';
import 'post_job_screen.dart';

/// Full job detail screen with all info, call/telegram buttons, and edit support.
class JobDetailScreen extends StatefulWidget {
  final Job job;

  const JobDetailScreen({required this.job, super.key});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late Job _job;
  bool _isSaved = false;

  String _t(String k) => L10n.t(k, appLocale.value);
  void _rebuild() => setState(() {});

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    _checkSaved();
    appLocale.addListener(_rebuild);
    appThemeMode.addListener(_rebuild);
  }

  @override
  void dispose() {
    appLocale.removeListener(_rebuild);
    appThemeMode.removeListener(_rebuild);
    super.dispose();
  }

  Future<void> _checkSaved() async {
    final saved = await FavoritesService.isFavorite(_job.id);
    if (mounted) setState(() => _isSaved = saved);
  }

  Future<void> _toggleSaved() async {
    await FavoritesService.toggle(_job.id);
    await _checkSaved();
  }

  // ── Deep-link helpers ──────────────────────────────────────────────────────

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: _job.phone);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('contact_phone'))),
        );
      }
    }
  }

  Future<void> _openTelegram() async {
    // Strip everything except digits and leading +
    final digits = _job.phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://t.me/$digits');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Telegram is not installed.")),
        );
      }
    }
  }

  Future<void> _openChat() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    await FirestoreService.initChat(
      jobId: _job.id,
      jobTitle: _job.title,
      posterUid: _job.postedByUid,
      seekerUid: user.uid,
      seekerName: user.displayName ?? user.phoneNumber ?? user.email ?? '?',
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          jobId: _job.id,
          jobTitle: _job.title,
          seekerUid: user.uid,
          posterUid: _job.postedByUid,
          opponentName: _job.title,
        ),
      ),
    );
  }

  void _openEdit() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PostJobScreen(initialJob: _job),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ).then((updated) {
      if (updated == true) Navigator.pop(context, true);
    });
  }

  bool get _isOwner =>
      AuthService.currentUser?.uid != null &&
      AuthService.currentUser!.uid == _job.postedByUid;

  // ── UI ────────────────────────────────────────────────────────────────────

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

    final accent = kCategoryColors[_job.category] ?? const Color(0xFF2563EB);
    final catIcon = kCategoryIcons[_job.category] ?? Icons.work_outline_rounded;

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
        actions: [
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isSaved ? const Color(0xFF2563EB) : textSecondary,
            ),
            onPressed: _toggleSaved,
          ),
          if (_isOwner)
            IconButton(
              icon: Icon(Icons.edit_rounded, color: textSecondary, size: 20),
              tooltip: _t('edit_job'),
              onPressed: _openEdit,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: ResponsiveBody(
          child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Category icon + title ──────────────────────────────────
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(catIcon, color: accent, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _job.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),

            // ── Salary chip ─────────────────────────────────────────────
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.payments_outlined,
                        color: Color(0xFF16A34A), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      _job.salary,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Details card ────────────────────────────────────────────
            _InfoCard(
              isDark: isDark,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              children: [
                _DetailRow(
                  icon: catIcon,
                  iconColor: accent,
                  label: _t('category'),
                  value: _t(_job.category),
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                if (_job.employmentType.isNotEmpty) ...[
                  _RowDivider(borderColor: borderColor),
                  _DetailRow(
                    icon: kEmpTypeIcons[_job.employmentType] ??
                        Icons.work_outline_rounded,
                    iconColor: kEmpTypeColors[_job.employmentType] ??
                        const Color(0xFF2563EB),
                    label: _t('employment_type'),
                    value: _t(_job.employmentType),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ],
                if (_job.region.isNotEmpty) ...[
                  _RowDivider(borderColor: borderColor),
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    iconColor: const Color(0xFF059669),
                    label: _t('region'),
                    value: _t(_job.region),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ],
                if (_job.workAddress.isNotEmpty) ...[
                  _RowDivider(borderColor: borderColor),
                  _DetailRow(
                    icon: Icons.place_outlined,
                    iconColor: const Color(0xFF7C3AED),
                    label: _t('work_address'),
                    value: _job.workAddress,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ],
                if (_job.workStart.isNotEmpty || _job.workEnd.isNotEmpty) ...[
                  _RowDivider(borderColor: borderColor),
                  _DetailRow(
                    icon: Icons.access_time_rounded,
                    iconColor: const Color(0xFFF97316),
                    label: _t('work_hours'),
                    value: [
                      if (_job.workStart.isNotEmpty)
                        '${_t('work_start')}: ${_job.workStart}',
                      if (_job.workEnd.isNotEmpty)
                        '${_t('work_end')}: ${_job.workEnd}',
                    ].join('   •   '),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // ── Description ─────────────────────────────────────────────
            if (_job.description.isNotEmpty) ...[
              _InfoCard(
                isDark: isDark,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                children: [
                  Text(
                    _t('description'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _job.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: textPrimary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // ── Contact + date card ─────────────────────────────────────
            _InfoCard(
              isDark: isDark,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              children: [
                _DetailRow(
                  icon: Icons.phone_outlined,
                  iconColor: const Color(0xFF2563EB),
                  label: _t('contact_phone'),
                  value: _job.phone,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                _RowDivider(borderColor: borderColor),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  iconColor: textSecondary,
                  label: _t('posted_at'),
                  value:
                      '${_job.createdAt.day.toString().padLeft(2, '0')}.${_job.createdAt.month.toString().padLeft(2, '0')}.${_job.createdAt.year}',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Map card (if location is set) ───────────────────────────
            if (_job.latitude != 0.0 || _job.longitude != 0.0) ...[
              Text(
                _t('location_on_map'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(_job.latitude, _job.longitude),
                      initialZoom: 15,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'job_finder_app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(_job.latitude, _job.longitude),
                            child: const Icon(
                              Icons.location_pin,
                              color: Color(0xFFEF4444),
                              size: 44,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Call button ─────────────────────────────────────────────
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _call,
                icon: const Icon(Icons.phone_rounded, size: 20),
                label: Text(
                  _job.phone,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Telegram button ─────────────────────────────────────────
            SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                onPressed: _openTelegram,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text(
                  'Telegram',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            // ── Edit button (owner only) ─────────────────────────────
            if (_isOwner) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _openEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: Text(
                    _t('edit_job'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],

            // ── Ask question button (non-owner) ────────────────────────
            if (!_isOwner && AuthService.currentUser != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _openChat,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                  label: Text(
                    _t('ask_question'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      )),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  final Color surfaceColor;
  final Color borderColor;

  const _InfoCard({
    required this.children,
    required this.isDark,
    required this.surfaceColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// ── Detail row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Row divider ───────────────────────────────────────────────────────────────

class _RowDivider extends StatelessWidget {
  final Color borderColor;
  const _RowDivider({required this.borderColor});

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        color: borderColor,
      );
}
