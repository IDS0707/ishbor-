import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_locale.dart';
import '../core/app_theme.dart';
import '../core/categories.dart';
import '../core/l10n.dart';
import '../models/worker_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class WorkerProfileSetupScreen extends StatefulWidget {
  final bool isFirstSetup;

  const WorkerProfileSetupScreen({super.key, this.isFirstSetup = false});

  @override
  State<WorkerProfileSetupScreen> createState() =>
      _WorkerProfileSetupScreenState();
}

class _WorkerProfileSetupScreenState extends State<WorkerProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();

  Set<String> _selectedCategories = {};
  String _gender = '';
  bool _genderError = false;
  bool _loading = true;
  bool _saving = false;

  String _t(String key) => L10n.t(key, appLocale.value);

  @override
  void initState() {
    super.initState();
    appLocale.addListener(_rebuild);
    appThemeMode.addListener(_rebuild);
    _nameCtrl.text = AuthService.currentUser?.displayName ?? '';
    _loadExisting();
  }

  @override
  void dispose() {
    appLocale.removeListener(_rebuild);
    appThemeMode.removeListener(_rebuild);
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _skillsCtrl.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  Future<void> _loadExisting() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final profile = await FirestoreService.getWorkerProfile(uid);
    if (profile != null && mounted) {
      setState(() {
        if (profile.name.isNotEmpty) _nameCtrl.text = profile.name;
        _selectedCategories = Set<String>.from(profile.categories);
        _ageCtrl.text = profile.age > 0 ? profile.age.toString() : '';
        _skillsCtrl.text = profile.skills;
        _gender = profile.gender;
      });
      // isFirstSetup = true amma profil allaqachon to'liq → /home ga o'tish
      if (widget.isFirstSetup && profile.isComplete && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pushReplacementNamed(context, '/home');
        });
        return;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender.isEmpty) {
      setState(() => _genderError = true);
      _showError(_t('gender_required'));
      return;
    }
    if (_selectedCategories.isEmpty) {
      _showError(_t('categories_required'));
      return;
    }
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      final user = AuthService.currentUser!;
      final name = _nameCtrl.text.trim();
      if (name.isNotEmpty) await user.updateDisplayName(name);
      final profile = WorkerProfile(
        uid: uid,
        name: name.isNotEmpty ? name : (user.displayName ?? ''),
        phone: user.phoneNumber ?? '',
        categories: _selectedCategories.toList(),
        skills: _skillsCtrl.text.trim(),
        age: int.parse(_ageCtrl.text.trim()),
        gender: _gender,
        updatedAt: DateTime.now(),
      );
      await FirestoreService.saveWorkerProfile(profile);
      if (mounted) {
        _showSuccess(_t('profile_save_success'));
        if (widget.isFirstSetup) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pop(context, true);
        }
      }
    } catch (_) {
      if (mounted) _showError(_t('error_generic'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showSuccess(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── completion progress ─────────────────────────────────────────
  double get _progress {
    int done = 0;
    if (_nameCtrl.text.trim().isNotEmpty) done++;
    if (_gender.isNotEmpty) done++;
    if (_ageCtrl.text.trim().isNotEmpty) done++;
    if (_skillsCtrl.text.trim().isNotEmpty) done++;
    if (_selectedCategories.isNotEmpty) done++;
    return done / 5;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appThemeMode.value == ThemeMode.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFF);
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final textPri = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSec = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final fillColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    InputDecoration fieldDec({
      required String label,
      required String hint,
      required IconData icon,
      Color? iconColor,
      Widget? suffix,
    }) {
      final ic = iconColor ?? const Color(0xFF2563EB);
      return InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: textSec, fontSize: 13),
        hintStyle: TextStyle(color: textSec.withValues(alpha: 0.6)),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: ic.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: ic, size: 18),
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: fillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                  color: const Color(0xFF2563EB),
                  backgroundColor:
                      const Color(0xFF2563EB).withValues(alpha: 0.1)))
          : CustomScrollView(
              slivers: [
                // ── Gradient Header ──────────────────────────────────
                SliverAppBar(
                  expandedHeight: 160,
                  pinned: true,
                  backgroundColor: const Color(0xFF1E3A8A),
                  surfaceTintColor: Colors.transparent,
                  automaticallyImplyLeading: !widget.isFirstSetup,
                  leading: widget.isFirstSetup
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0F2167),
                            Color(0xFF1E3A8A),
                            Color(0xFF2563EB),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 8),
                              // Progress bar
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: _progress,
                                        backgroundColor:
                                            Colors.white.withValues(alpha: 0.2),
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                                Colors.white),
                                        minHeight: 5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${(_progress * 100).round()}%',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _t('my_worker_profile'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _t('worker_profile_subtitle'),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Form body ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Section: Personal info ──────────────
                          _SectionHeader(
                            icon: Icons.person_rounded,
                            title: _t('display_name'),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),

                          // Name field
                          TextFormField(
                            controller: _nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            style: TextStyle(color: textPri),
                            onChanged: (_) => setState(() {}),
                            decoration: fieldDec(
                              label: _t('display_name'),
                              hint: _t('display_name_hint'),
                              icon: Icons.badge_outlined,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return _t('name_required');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Age field
                          TextFormField(
                            controller: _ageCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: textPri),
                            onChanged: (_) => setState(() {}),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            decoration: fieldDec(
                              label: _t('worker_age'),
                              hint: _t('worker_age_hint'),
                              icon: Icons.cake_outlined,
                              iconColor: const Color(0xFF0891B2),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return _t('age_required');
                              }
                              final n = int.tryParse(v.trim());
                              if (n == null || n < 14 || n > 80) {
                                return _t('age_invalid');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // ── Section: Gender ─────────────────────
                          _SectionHeader(
                            icon: Icons.wc_rounded,
                            title: _t('gender'),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _GenderBtn(
                                  label: _t('gender_male'),
                                  icon: Icons.male_rounded,
                                  selected: _gender == 'male',
                                  color: const Color(0xFF2563EB),
                                  isDark: isDark,
                                  border: border,
                                  surface: surface,
                                  onTap: () => setState(() {
                                    _gender = 'male';
                                    _genderError = false;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _GenderBtn(
                                  label: _t('gender_female'),
                                  icon: Icons.female_rounded,
                                  selected: _gender == 'female',
                                  color: const Color(0xFFDB2777),
                                  isDark: isDark,
                                  border: border,
                                  surface: surface,
                                  onTap: () => setState(() {
                                    _gender = 'female';
                                    _genderError = false;
                                  }),
                                ),
                              ),
                            ],
                          ),
                          if (_genderError)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                _t('gender_required'),
                                style: const TextStyle(
                                    color: Color(0xFFEF4444), fontSize: 12),
                              ),
                            ),
                          const SizedBox(height: 20),

                          // ── Section: Skills ─────────────────────
                          _SectionHeader(
                            icon: Icons.star_rounded,
                            title: _t('worker_skills'),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _skillsCtrl,
                            maxLines: 3,
                            style: TextStyle(color: textPri),
                            onChanged: (_) => setState(() {}),
                            decoration: fieldDec(
                              label: _t('worker_skills'),
                              hint: _t('worker_skills_hint'),
                              icon: Icons.star_outline_rounded,
                              iconColor: const Color(0xFFF59E0B),
                            ).copyWith(
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(
                                    left: 10, right: 10, top: 10),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.star_outline_rounded,
                                      color: Color(0xFFF59E0B), size: 18),
                                ),
                              ),
                              alignLabelWithHint: true,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return _t('skills_required');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // ── Section: Categories ─────────────────
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.apps_rounded,
                                    color: Color(0xFF7C3AED), size: 17),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _t('worker_categories'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: textPri,
                                      ),
                                    ),
                                    Text(
                                      _t('worker_categories_hint'),
                                      style: TextStyle(
                                          fontSize: 11, color: textSec),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _selectedCategories.isNotEmpty
                                      ? const Color(0xFF7C3AED)
                                          .withValues(alpha: 0.12)
                                      : border.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_selectedCategories.length}/${kCategories.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _selectedCategories.isNotEmpty
                                        ? const Color(0xFF7C3AED)
                                        : textSec,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Category grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2.2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: kCategories.length,
                            itemBuilder: (ctx, i) {
                              final key = kCategories[i];
                              final isSelected =
                                  _selectedCategories.contains(key);
                              final color = kCategoryColors[key] ??
                                  const Color(0xFF2563EB);
                              final icon =
                                  kCategoryIcons[key] ?? Icons.work_outline;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  if (isSelected) {
                                    _selectedCategories.remove(key);
                                  } else {
                                    _selectedCategories.add(key);
                                  }
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.withValues(alpha: 0.13)
                                        : surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? color : border,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color:
                                                  color.withValues(alpha: 0.18),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  child: Row(
                                    children: [
                                      Icon(icon,
                                          size: 15,
                                          color: isSelected ? color : textSec),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          _t(key),
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isSelected ? color : textPri,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 28),

                          // ── Save button ─────────────────────────
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                disabledBackgroundColor: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.5),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.check_circle_rounded,
                                            size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          _t('save'),
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF2563EB);
    final textPri = isDark ? Colors.white : const Color(0xFF0F172A);
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: textPri,
          ),
        ),
      ],
    );
  }
}

// ── Gender button ─────────────────────────────────────────────────────────────
class _GenderBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final bool isDark;
  final Color border;
  final Color surface;
  final VoidCallback onTap;

  const _GenderBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.isDark,
    required this.border,
    required this.surface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPri = isDark ? Colors.white : const Color(0xFF0F172A);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 58,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : border,
            width: selected ? 2 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 22, color: selected ? color : const Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : textPri,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle_rounded, size: 16, color: color),
            ],
          ],
        ),
      ),
    );
  }
}
