import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:job_finder_app/core/providers.dart';
import 'package:job_finder_app/services/index.dart';
import 'package:job_finder_app/ui/theme/index.dart';
import 'package:job_finder_app/ui/widgets/index.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _verificationId;
  bool _showOTPInput = false;
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendOTP() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final firebase = ref.read(firebaseServiceProvider);
      final phone = '+${_phoneController.text.replaceAll(RegExp(r'\D'), '')}';
      final verificationId = await firebase.verifyPhoneNumber(phone);

      setState(() {
        _verificationId = verificationId;
        _showOTPInput = true;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP sent to your phone')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _verifyOTP() async {
    if (_otpController.text.isEmpty || _verificationId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter OTP')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final firebase = ref.read(firebaseServiceProvider);
      await firebase.verifyOTP(_verificationId!, _otpController.text);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/role-selection');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invalid OTP: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Text(
                  '🚀 Job Finder',
                  style: Theme.of(context).textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Find work in under 10 seconds',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                if (!_showOTPInput)
                  Column(
                    children: [
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'Enter phone number (+1234567890)',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: 'Send OTP',
                        onPressed: _sendOTP,
                        isLoading: _isLoading,
                        width: double.infinity,
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Text(
                        'Enter 6-digit OTP sent to ${_phoneController.text}',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: '000000',
                          counterText: '',
                        ),
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: 'Verify OTP',
                        onPressed: _verifyOTP,
                        isLoading: _isLoading,
                        width: double.infinity,
                      ),
                      const SizedBox(height: 12),
                      SecondaryButton(
                        label: 'Change Phone',
                        onPressed: () {
                          setState(() {
                            _showOTPInput = false;
                            _otpController.clear();
                            _verificationId = null;
                          });
                        },
                        width: double.infinity,
                      ),
                    ],
                  ),
                const SizedBox(height: 40),
                Text(
                  '🔐 Privacy First\nWe only collect: Name, Phone, Skills',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
