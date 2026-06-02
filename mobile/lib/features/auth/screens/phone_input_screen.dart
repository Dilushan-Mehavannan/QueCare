import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:mobile/config/theme.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/features/auth/screens/otp_verify_screen.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _phoneNumber = '';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Navigate to OTP verify screen when code gets sent
    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.codeSent) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const OtpVerifyScreen(),
          ),
        );
      } else if (next.status == AuthStatus.failure && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF1F5F9), // Slate 100
              Color(0xFFE2E8F0), // Slate 200
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon Glowing Logo
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryTeal.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_hospital_rounded,
                        size: 54,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // App Title Headers
                  Center(
                    child: Text(
                      'QueueCare',
                      style: GoogleFonts.outfit(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryTeal,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Smart Queue & Appointment System',
                      style: AppTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Phone input card
                  Card(
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.04),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Verify Your Phone',
                              style: AppTheme.heading2,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'We will send a 6-digit confirmation code.',
                              style: AppTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            IntlPhoneField(
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                hintText: 'Enter number',
                                counterText: '',
                              ),
                              initialCountryCode: 'US',
                              onChanged: (phone) {
                                _phoneNumber = phone.completeNumber;
                              },
                              onSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tip: Enter +1 555-555-5555 for Demo/Bypass Mode',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.primaryLightTeal,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            ElevatedButton(
                              onPressed: authState.status == AuthStatus.loading
                                  ? null
                                  : _submit,
                              child: authState.status == AuthStatus.loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Send OTP Code'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_phoneNumber.trim().isNotEmpty) {
        ref.read(authProvider.notifier).sendOtp(_phoneNumber);
      }
    }
  }
}
