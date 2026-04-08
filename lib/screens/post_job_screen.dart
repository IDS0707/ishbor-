import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../core/app_locale.dart';
import '../core/app_theme.dart';
import '../core/responsive.dart';
import '../core/categories.dart';
import '../core/l10n.dart';
import '../models/job.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'map_picker_screen.dart';

class PostJobScreen extends StatefulWidget {
  /// Pass an existing [Job] to enter edit mode.
  final Job? initialJob;
  const PostJobScreen({super.key, this.initialJob});
  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _workStartCtrl = TextEditingController();
  final _workEndCtrl = TextEditingController();
  final _ageMinCtrl = TextEditingController();
  final _ageMaxCtrl = TextEditingController();
  String _selectedCategory = kCategories.first;
  String _customCategory = ''; // user-typed custom category name
  String _selectedRegion = kRegions.first;
  String _selectedEmpType = 'emp_fulltime';
  String _selectedGender = ''; // '' = any, 'male', 'female'
  bool _loading = false;
  double _lat = 0.0;
  double _lng = 0.0;

  bool get _isEditMode => widget.initialJob != null;

  String _t(String k) => L10n.t(k, appLocale.value);

  @override
  void initState() {
    super.initState();
    appLocale.addListener(_rebuild);
    appThemeMode.addListener(_rebuild);
    final job = widget.initialJob;
    if (job != null) {
      _titleCtrl.text = job.title;
      _salaryCtrl.text = job.salary;
      _phoneCtrl.text = job.phone;
      _descCtrl.text = job.description;
      _addressCtrl.text = job.workAddress;
      _workStartCtrl.text = job.workStart;
      _workEndCtrl.text = job.workEnd;
      if (job.ageMin > 0) _ageMinCtrl.text = '${job.ageMin}';
      if (job.ageMax > 0) _ageMaxCtrl.text = '${job.ageMax}';
      _selectedGender = job.gender;
      if (kCategories.contains(job.category)) {
        _selectedCategory = job.category;
      } else if (job.category.isNotEmpty) {
        _selectedCategory = '__custom__';
        _customCategory = job.category;
      }
      if (kRegions.contains(job.region)) _selectedRegion = job.region;
      if (kEmploymentTypes.contains(job.employmentType) &&
          job.employmentType.isNotEmpty) {
        _selectedEmpType = job.employmentType;
      }
      _lat = job.latitude;
      _lng = job.longitude;
    } else {
      final phone = AuthService.currentUser?.phoneNumber;
      if (phone != null) _phoneCtrl.text = phone;
    }
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    appLocale.removeListener(_rebuild);
    appThemeMode.removeListener(_rebuild);
    _titleCtrl.dispose();
    _salaryCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _workStartCtrl.dispose();
    _workEndCtrl.dispose();
    _ageMinCtrl.dispose();
    _ageMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      // ── Anti-spam check (only for new jobs, not edits) ────────────────
      if (!_isEditMode) {
        final uid = AuthService.currentUser?.uid ?? '';
        if (uid.isNotEmpty) {
          try {
            const maxJobsPer60Min = 5;
            final recent = await FirestoreService.recentJobCount(uid);
            if (recent >= maxJobsPer60Min) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_t('rate_limit_jobs')),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
              setState(() => _loading = false);
              return;
            }
          } catch (_) {
            // Anti-spam tekshiruvi ishlamasa ham yuborishga ruxsat
          }
        }
      }
      // ─────────────────────────────────────────────────────────────────
      final job = Job(
        id: widget.initialJob?.id ?? '',
        title: _titleCtrl.text.trim(),
        salary: _salaryCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        category: _selectedCategory == '__custom__'
            ? _customCategory.trim()
            : _selectedCategory,
        description: _descCtrl.text.trim(),
        postedByUid: widget.initialJob?.postedByUid ??
            AuthService.currentUser?.uid ??
            '',
        createdAt: widget.initialJob?.createdAt ?? DateTime.now(),
        region: _selectedRegion,
        workAddress: _addressCtrl.text.trim(),
        workStart: _workStartCtrl.text.trim(),
        workEnd: _workEndCtrl.text.trim(),
        latitude: _lat,
        longitude: _lng,
        employmentType: _selectedEmpType,
        ageMin: int.tryParse(_ageMinCtrl.text.trim()) ?? 0,
        ageMax: int.tryParse(_ageMaxCtrl.text.trim()) ?? 0,
        gender: _selectedGender,
      );
      if (_isEditMode) {
        await FirestoreService.updateJob(widget.initialJob!.id, job);
      } else {
        await FirestoreService.addJob(job);
        // Notify the poster themselves — non-critical, ignore failures
        try {
          final posterUid = AuthService.currentUser?.uid ?? '';
          if (posterUid.isNotEmpty) {
            await FirestoreService.createNotification(
              uid: posterUid,
              type: 'new_job',
              title: job.title,
              body: _t('job_posted'),
            );
          }
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? _t('job_updated') : _t('job_posted')),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context, true); // true = data changed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().length > 120
                ? e.toString().substring(0, 120)
                : e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, size: 24, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? _t('edit_job') : _t('post_job_title'),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: textPrimary,
          ),
        ),
      ),
      body: ResponsiveBody(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFF2563EB), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _t('post_job_subtitle'),
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFF1D4ED8),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Category grid ────────────────────────────────────────
              _FieldLabel(_t('category'), textSecondary),
              const SizedBox(height: 10),
              _CategoryGrid(
                selected: _selectedCategory,
                customCategory: _customCategory,
                onSelect: (cat) => setState(() => _selectedCategory = cat),
                onCustomCategory: (name) => setState(() {
                  _customCategory = name;
                  _selectedCategory = '__custom__';
                }),
                isDark: isDark,
                t: _t,
              ),
              const SizedBox(height: 20),

              // ── Employment type ───────────────────────────────────────
              _FieldLabel(_t('employment_type'), textSecondary),
              const SizedBox(height: 10),
              _EmpTypeSelector(
                selected: _selectedEmpType,
                onSelect: (e) => setState(() => _selectedEmpType = e),
                isDark: isDark,
                t: _t,
              ),
              const SizedBox(height: 20),

              // ── Job title ────────────────────────────────────────────
              _FieldLabel(_t('job_title'), textSecondary),
              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: textPrimary),
                decoration: _dec(
                  hint: _t('job_title_hint'),
                  icon: Icons.work_outline_rounded,
                  isDark: isDark,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? _t('required') : null,
              ),
              const SizedBox(height: 16),

              // ── Salary ───────────────────────────────────────────────
              _FieldLabel(_t('salary'), textSecondary),
              TextFormField(
                controller: _salaryCtrl,
                style: TextStyle(color: textPrimary),
                decoration: _dec(
                  hint: _t('salary_hint'),
                  icon: Icons.payments_outlined,
                  isDark: isDark,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? _t('required') : null,
              ),
              const SizedBox(height: 16),

              // ── Phone ────────────────────────────────────────────────
              _FieldLabel(_t('contact_phone'), textSecondary),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: textPrimary),
                decoration: _dec(
                  hint: '+998 90 123 45 67',
                  icon: Icons.phone_outlined,
                  isDark: isDark,
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 7) {
                    return _t('valid_phone');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Region ──────────────────────────────────────────────
              _FieldLabel(_t('region'), textSecondary),
              const SizedBox(height: 6),
              _RegionDropdown(
                selected: _selectedRegion,
                onSelect: (r) => setState(() => _selectedRegion = r),
                isDark: isDark,
                t: _t,
              ),
              const SizedBox(height: 16),

              // ── Work address ─────────────────────────────────────────
              _FieldLabel(_t('work_address'), textSecondary),
              TextFormField(
                controller: _addressCtrl,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: textPrimary),
                decoration: _dec(
                  hint: _t('work_address_hint'),
                  icon: Icons.location_on_outlined,
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: 10),
              // ── Map picker button ────────────────────────────────────
              _MapPickerButton(
                lat: _lat,
                lng: _lng,
                isDark: isDark,
                t: _t,
                onPick: (LatLng pos) => setState(() {
                  _lat = pos.latitude;
                  _lng = pos.longitude;
                }),
                onOpen: () async {
                  final result = await Navigator.push<LatLng>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapPickerScreen(
                        initialLat: _lat,
                        initialLng: _lng,
                        regionCode: _selectedRegion,
                      ),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _lat = result.latitude;
                      _lng = result.longitude;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // ── Work hours ───────────────────────────────────────────
              _FieldLabel(_t('work_hours'), textSecondary),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _TimeField(
                      controller: _workStartCtrl,
                      hint: _t('work_start'),
                      placeholder: '08:00',
                      isDark: isDark,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 36, left: 8, right: 8),
                    child: Text('—',
                        style: TextStyle(
                            color: textSecondary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700)),
                  ),
                  Expanded(
                    child: _TimeField(
                      controller: _workEndCtrl,
                      hint: _t('work_end'),
                      placeholder: '20:00',
                      isDark: isDark,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Description (optional) ───────────────────────────────
              _FieldLabel(_t('description'), textSecondary),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: _t('description_hint'),
                  hintStyle: TextStyle(color: textSecondary, fontSize: 14),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Color(0xFF2563EB), width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),

              // ── Age range ─────────────────────────────────────────────
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cake_rounded,
                            color: Color(0xFFF59E0B), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _t('age_range_section'),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _t('age_range_subtitle'),
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageMinCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            style: TextStyle(color: textPrimary),
                            decoration: InputDecoration(
                              labelText: _t('age_min'),
                              hintText: _t('age_min_hint'),
                              hintStyle: TextStyle(color: textSecondary),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
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
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFFEF4444), width: 1.5),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFFEF4444), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              final n = int.tryParse(v);
                              if (n == null || n < 14 || n > 80) {
                                return _t('age_invalid');
                              }
                              final maxVal =
                                  int.tryParse(_ageMaxCtrl.text.trim()) ?? 0;
                              if (maxVal > 0 && n > maxVal) {
                                return _t('age_min_max_invalid');
                              }
                              return null;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('—',
                              style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700)),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _ageMaxCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            style: TextStyle(color: textPrimary),
                            decoration: InputDecoration(
                              labelText: _t('age_max'),
                              hintText: _t('age_max_hint'),
                              hintStyle: TextStyle(color: textSecondary),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
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
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFFEF4444), width: 1.5),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFFEF4444), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              final n = int.tryParse(v);
                              if (n == null || n < 14 || n > 80) {
                                return _t('age_invalid');
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Preferred gender ─────────────────────────────────────
              Container(
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
                        const Icon(Icons.wc_rounded,
                            size: 18, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        Text(
                          _t('preferred_gender'),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final opt in [
                          ('', 'gender_any'),
                          ('male', 'gender_male'),
                          ('female', 'gender_female'),
                        ])
                          ChoiceChip(
                            label: Text(_t(opt.$2)),
                            selected: _selectedGender == opt.$1,
                            onSelected: (_) =>
                                setState(() => _selectedGender = opt.$1),
                            selectedColor: const Color(0xFF2563EB),
                            labelStyle: TextStyle(
                              color: _selectedGender == opt.$1
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.white70
                                      : const Color(0xFF374151)),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Security warning ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFB45309), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _t('employer_data_warning'),
                        style: const TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Submit button ────────────────────────────────────────
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    disabledBackgroundColor: const Color(0xFF93C5FD),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          _isEditMode ? _t('save') : _t('post_job_title'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      )),
    );
  }

  InputDecoration _dec(
          {required String hint,
          required IconData icon,
          required bool isDark}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF),
            fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
              width: 1.5),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );
}

// ── Category grid ─────────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  final String selected;
  final String customCategory;
  final void Function(String) onSelect;
  final void Function(String) onCustomCategory;
  final bool isDark;
  final String Function(String) t;

  const _CategoryGrid({
    required this.selected,
    required this.customCategory,
    required this.onSelect,
    required this.onCustomCategory,
    required this.isDark,
    required this.t,
  });

  void _showCustomDialog(BuildContext context) {
    final ctrl = TextEditingController(
      text: selected == '__custom__' ? customCategory : '',
    );
    showDialog(
      context: context,
      builder: (ctx) {
        final isDarkCtx = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDarkCtx ? const Color(0xFF1E293B) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            t('custom_category_title'),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDarkCtx ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(
                color: isDarkCtx ? Colors.white : const Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: t('custom_category_hint'),
              hintStyle: TextStyle(
                  color: isDarkCtx
                      ? const Color(0xFF64748B)
                      : const Color(0xFF9CA3AF)),
              prefixIcon: const Icon(Icons.add_circle_outline_rounded,
                  color: Color(0xFF2563EB)),
              filled: true,
              fillColor:
                  isDarkCtx ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isDarkCtx
                        ? const Color(0xFF334155)
                        : const Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF2563EB), width: 2),
              ),
            ),
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) {
                onCustomCategory(v.trim());
                Navigator.pop(ctx);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t('cancel'),
                  style: const TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final v = ctrl.text.trim();
                if (v.isNotEmpty) {
                  onCustomCategory(v);
                  Navigator.pop(ctx);
                }
              },
              child: Text(t('save')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // All items = standard categories + 1 extra "add custom" tile
    final totalCount = kCategories.length + 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: totalCount,
      itemBuilder: (ctx, i) {
        final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
        final borderColor =
            isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);

        // Last tile = "Add custom category"
        if (i == kCategories.length) {
          final isCustomSelected = selected == '__custom__';
          return GestureDetector(
            onTap: () => _showCustomDialog(ctx),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isCustomSelected
                    ? const Color(0xFF2563EB).withValues(alpha: 0.12)
                    : cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCustomSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF2563EB).withValues(alpha: 0.4),
                  width: isCustomSelected ? 2 : 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCustomSelected
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_outline_rounded,
                    size: 14,
                    color: const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      isCustomSelected && customCategory.isNotEmpty
                          ? customCategory
                          : t('custom_category'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isCustomSelected
                            ? const Color(0xFF2563EB)
                            : (isDark
                                ? const Color(0xFF93C5FD)
                                : const Color(0xFF2563EB)),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final key = kCategories[i];
        final isSelected = selected == key;
        final accent = kCategoryColors[key] ?? const Color(0xFF2563EB);
        final icon = kCategoryIcons[key] ?? Icons.work_outline;

        return GestureDetector(
          onTap: () => onSelect(key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? accent : cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? accent : borderColor,
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFF94A3B8) : accent),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    t(key),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF374151)),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Field label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _FieldLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: color,
          ),
        ),
      );
}

// ── Time input field ──────────────────────────────────────────────────────────

/// Auto-formatting HH:MM text field — no time picker, numeric keyboard only.
class _TimeField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String placeholder;
  final bool isDark;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const _TimeField({
    required this.controller,
    required this.hint,
    required this.placeholder,
    required this.isDark,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  State<_TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<_TimeField> {
  String? _error;

  // Formats a raw digit string into HH:MM
  String _autoFormat(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length <= 2) return digits;
    return '${digits.substring(0, 2)}:${digits.substring(2, digits.length.clamp(2, 4))}';
  }

  bool _isValidTime(String value) {
    final pattern = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    return pattern.hasMatch(value);
  }

  void _onChanged(String value) {
    final formatted = _autoFormat(value);
    if (formatted != value) {
      widget.controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() {
      _error =
          (formatted.isNotEmpty && !_isValidTime(formatted)) ? 'HH:MM' : null;
    });
  }

  void _onEditingComplete() {
    final v = widget.controller.text.trim();
    if (v.isEmpty) {
      setState(() => _error = null);
      return;
    }
    setState(() {
      _error = _isValidTime(v) ? null : 'HH:MM';
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label above the field
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            widget.hint,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: widget.textSecondary,
            ),
          ),
        ),
        SizedBox(
          height: 54,
          child: TextFormField(
            controller: widget.controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
              LengthLimitingTextInputFormatter(5),
            ],
            style: TextStyle(
              color: widget.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: TextStyle(
                color: widget.textSecondary.withValues(alpha: 0.5),
                fontSize: 20,
                fontWeight: FontWeight.w400,
                letterSpacing: 2,
              ),
              filled: true,
              fillColor: widget.isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF9FAFB),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color:
                        hasError ? const Color(0xFFDC2626) : widget.borderColor,
                    width: hasError ? 2 : 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: hasError
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF2563EB),
                    width: 2),
              ),
              contentPadding: EdgeInsets.zero,
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFDC2626), width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFDC2626), width: 2),
              ),
            ),
            onChanged: _onChanged,
            onEditingComplete: _onEditingComplete,
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              _error!,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

// ── Map picker button ─────────────────────────────────────────────────────────

class _MapPickerButton extends StatelessWidget {
  final double lat;
  final double lng;
  final bool isDark;
  final String Function(String) t;
  final void Function(LatLng) onPick;
  final VoidCallback onOpen;

  const _MapPickerButton({
    required this.lat,
    required this.lng,
    required this.isDark,
    required this.t,
    required this.onPick,
    required this.onOpen,
  });

  bool get _hasPicked => lat != 0.0 || lng != 0.0;

  @override
  Widget build(BuildContext context) {
    final surfaceColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB);
    final borderColor = _hasPicked
        ? const Color(0xFF16A34A)
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB));

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(
              _hasPicked
                  ? Icons.location_on_rounded
                  : Icons.add_location_alt_outlined,
              color: _hasPicked
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF2563EB),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _hasPicked
                    ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
                    : t('pick_on_map'),
                style: TextStyle(
                  fontSize: 14,
                  color: _hasPicked
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF9CA3AF),
                  fontWeight: _hasPicked ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Region dropdown ───────────────────────────────────────────────────────────

class _RegionDropdown extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  final bool isDark;
  final String Function(String) t;

  const _RegionDropdown({
    required this.selected,
    required this.onSelect,
    required this.isDark,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB);
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF2563EB)),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(color: textPrimary, fontSize: 14),
          items: kRegions.map((reg) {
            return DropdownMenuItem<String>(
              value: reg,
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(t(reg),
                      style: TextStyle(color: textPrimary, fontSize: 14)),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) onSelect(v);
          },
        ),
      ),
    );
  }
}

// ── Employment-type selector ──────────────────────────────────────────────────

class _EmpTypeSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  final bool isDark;
  final String Function(String) t;

  const _EmpTypeSelector({
    required this.selected,
    required this.onSelect,
    required this.isDark,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    const types = ['emp_fulltime', 'emp_parttime', 'emp_onetime'];
    return Row(
      children: types.map((emp) {
        final isSelected = selected == emp;
        final accent = kEmpTypeColors[emp] ?? const Color(0xFF2563EB);
        final icon = kEmpTypeIcons[emp] ?? Icons.work_outline;
        final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
        final borderColor =
            isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(emp),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? accent.withValues(alpha: 0.1) : cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? accent : borderColor,
                    width: isSelected ? 2 : 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: isSelected
                          ? accent
                          : (isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t(emp),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? accent
                            : (isDark ? Colors.white : const Color(0xFF374151)),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
