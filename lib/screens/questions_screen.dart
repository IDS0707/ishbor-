import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_locale.dart';
import '../core/app_theme.dart';
import '../core/l10n.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  final Set<int> _expanded = {};
  final _questionCtrl = TextEditingController();
  bool _sending = false;

  String _t(String k) => L10n.t(k, appLocale.value);

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
    _questionCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendQuestion() async {
    final text = _questionCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final uid = AuthService.currentUser?.uid ?? 'anonymous';
      await FirestoreService.createSupportQuestion(uid: uid, question: text);
      _questionCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t('question_sent')),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (_) {
      // fallback: open Telegram support
      final url = Uri.parse('https://t.me/ishbor_support');
      if (await canLaunchUrl(url)) await launchUrl(url);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  List<Map<String, String>> _faqs() => [
        {
          'q': _t('faq_q1'),
          'a': _t('faq_a1'),
        },
        {
          'q': _t('faq_q2'),
          'a': _t('faq_a2'),
        },
        {
          'q': _t('faq_q3'),
          'a': _t('faq_a3'),
        },
        {
          'q': _t('faq_q4'),
          'a': _t('faq_a4'),
        },
        {
          'q': _t('faq_q5'),
          'a': _t('faq_a5'),
        },
        {
          'q': _t('faq_q6'),
          'a': _t('faq_a6'),
        },
        {
          'q': _t('faq_q7'),
          'a': _t('faq_a7'),
        },
        {
          'q': _t('faq_q8'),
          'a': _t('faq_a8'),
        },
      ];

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

    final faqs = _faqs();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: dividerColor,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('questions'),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.help_outline_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('faq_title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _t('faq_subtitle'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // FAQ items
          ...List.generate(faqs.length, (i) {
            final isOpen = _expanded.contains(i);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isOpen ? const Color(0xFF2563EB) : dividerColor,
                    width: isOpen ? 1.5 : 1,
                  ),
                  boxShadow: isOpen
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2563EB)
                                .withValues(alpha: isDark ? 0.1 : 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() {
                        if (isOpen) {
                          _expanded.remove(i);
                        } else {
                          _expanded.add(i);
                        }
                      }),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isOpen
                                        ? const Color(0xFF2563EB)
                                        : (isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          isOpen ? Colors.white : textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    faqs[i]['q']!,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isOpen
                                          ? const Color(0xFF2563EB)
                                          : textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AnimatedRotation(
                                  turns: isOpen ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: isOpen
                                        ? const Color(0xFF2563EB)
                                        : textSecondary,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                            if (isOpen) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                height: 1,
                                color: dividerColor,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                faqs[i]['a']!,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // "Ask a question" form card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.support_agent_rounded,
                          color: Color(0xFF059669), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t('faq_support_title'),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _t('faq_support_sub'),
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _questionCtrl,
                  minLines: 3,
                  maxLines: 6,
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _t('type_your_question'),
                    hintStyle: TextStyle(color: textSecondary, fontSize: 14),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF059669), width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _sendQuestion,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _t('send_question'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
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
