import 'package:flutter/material.dart';
import '../core/responsive.dart';
import '../core/app_theme.dart';
import '../services/role_service.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _loading = false;

  Future<void> _selectRole(String role) async {
    setState(() => _loading = true);
    await RoleService.setRole(role);
    if (!mounted) return;
    if (role == 'employer') {
      Navigator.pushReplacementNamed(context, '/employer-home');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appThemeMode.value == ThemeMode.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
    final textPri = isDark ? Colors.white : const Color(0xFF111827);
    final textSec = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bg,
      body: ResponsiveBody(
          maxWidth: 480,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.work_rounded,
                        color: Color(0xFF2563EB),
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Title
                    Text(
                      'Xush kelibsiz!',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: textPri,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Siz qanday foydalanmoqchisiz?',
                      style: TextStyle(
                        fontSize: 17,
                        color: textSec,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 44),

                    // Employer card
                    _RoleCard(
                      icon: Icons.business_center_rounded,
                      iconBg: const Color(0xFF16A34A),
                      title: 'Ish joylayman',
                      description:
                          'Vakansiya yoki ish e\'loni joylashtirmoqchiman',
                      isDark: isDark,
                      disabled: _loading,
                      onTap: () => _selectRole('employer'),
                    ),
                    const SizedBox(height: 16),

                    // Worker card
                    _RoleCard(
                      icon: Icons.search_rounded,
                      iconBg: const Color(0xFF7C3AED),
                      title: 'Ish izlayapman',
                      description:
                          'Ish qidiraman va e\'lonlarni ko\'rmoqchiman',
                      isDark: isDark,
                      disabled: _loading,
                      onTap: () => _selectRole('worker'),
                    ),

                    if (_loading) ...[
                      const SizedBox(height: 32),
                      const CircularProgressIndicator(
                        color: Color(0xFF2563EB),
                        strokeWidth: 2.5,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          )),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String description;
  final bool isDark;
  final bool disabled;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.description,
    required this.isDark,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final textPri = isDark ? Colors.white : const Color(0xFF111827);
    final textSec = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconBg.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: iconBg, size: 32),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: textPri,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: textSec,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: textSec,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
