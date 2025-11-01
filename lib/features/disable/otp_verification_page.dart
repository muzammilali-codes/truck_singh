import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'otp_activation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/theme.dart';
import 'otp_activation_service.dart';
import 'package:logistics_toolkit/features/disable/otp_activation_service.dart';


class OtpVerificationPage extends StatefulWidget {
  final String email;
  final String phoneNumber;
  final String customUserId;
  final bool isEmail;

  const OtpVerificationPage({
    super.key,
    required this.email,
    required this.phoneNumber,
    required this.customUserId,
    required this.isEmail,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
        (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String get _otpCode {
    return _otpControllers.map((controller) => controller.text).join();
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    // If all fields are filled, automatically verify
    if (_otpCode.length == 6) {
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6 || _isVerifying) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      // Use our OTP activation service
      final result = await OtpActivationService.verifyOtpAndActivate(
        email: widget.email,
        otpCode: _otpCode,
        customUserId: widget.customUserId, // Pass the custom user ID
      );

      if (!mounted) return;

      //if (result['ok'] == true) {
      // Show success message and redirect to login
      // _showSuccessAndRedirect();
      //await reactivateAccountAfterOtp(context, widget.customUserId);
      //}
      if (result['ok'] == true) {
        // ✅ First, update Supabase to re-enable the account via your RPC
        await toggleAccountStatusRpc(
          customUserId: widget.customUserId,
          disabled: false,
          changedBy: widget.customUserId,
          changedByRole: 'user',
        );

        // ✅ Then show success and redirect
        _showSuccessAndRedirect();
      }
      else {
        String errorMessage = result['error'] ?? 'Verification failed';
        _showError(errorMessage);
        _clearOtpFields();
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to verify OTP: ${e.toString()}');
      _clearOtpFields();
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  void _clearOtpFields() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _resendOtp() async {
    if (_isResending || _resendCountdown > 0) return;

    setState(() {
      _isResending = true;
    });

    try {
      final result = await OtpActivationService.sendActivationOtp(
        email: widget.email,
      );

      if (!mounted) return;

      if (result['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New OTP sent to your email'),
            backgroundColor: Colors.green,
          ),
        );

        _startResendCountdown();
        _clearOtpFields();
      } else {
        _showError(result['error'] ?? 'Failed to resend OTP');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to resend OTP: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessAndRedirect() async {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Account activated! Redirecting to dashboard...'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Small delay to show the success message, then let auth state listener handle navigation
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    // The user is now activated and still signed in
    // The auth state listener in main.dart will automatically redirect to the appropriate dashboard
    // No need to manually sign out or navigate
    print(
      '✅ Account activated successfully, auth state listener will handle navigation',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Verify OTP'),
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isEmail ? Icons.email : Icons.phone,
                        size: 40,
                        color: AppColors.teal,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'Enter Verification Code',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Subtitle
                    Text(
                      widget.isEmail
                          ? 'We\'ve sent a 6-digit code to\n${widget.email}'
                          : 'We\'ve sent a 6-digit code to\n${widget.phoneNumber}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    // OTP Input Fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return Container(
                          width: 45,
                          height: 55,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _otpControllers[index].text.isNotEmpty
                                  ? AppColors.teal
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: TextField(
                            controller: _otpControllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                            ),
                            onChanged: (value) => _onOtpChanged(value, index),
                            onTap: () {
                              _otpControllers[index]
                                  .selection = TextSelection.fromPosition(
                                TextPosition(
                                  offset: _otpControllers[index].text.length,
                                ),
                              );
                            },
                            onSubmitted: (value) {
                              if (index < 5 && value.isNotEmpty) {
                                _focusNodes[index + 1].requestFocus();
                              } else if (index == 5 && _otpCode.length == 6) {
                                _verifyOtp();
                              }
                            },
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 32),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_otpCode.length == 6 && !_isVerifying)
                            ? _verifyOtp
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isVerifying
                            ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Verifying...'),
                          ],
                        )
                            : const Text(
                          'Verify & Activate Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Resend OTP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Didn\'t receive the code? ',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        if (_resendCountdown > 0)
                          Text(
                            'Resend in ${_resendCountdown}s',
                            style: TextStyle(color: Colors.grey.shade500),
                          )
                        else
                          GestureDetector(
                            onTap: _isResending ? null : _resendOtp,
                            child: Text(
                              _isResending ? 'Sending...' : 'Resend',
                              style: TextStyle(
                                color: _isResending
                                    ? Colors.grey.shade500
                                    : AppColors.teal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> reactivateAccountAfterOtp(BuildContext context, String userId) async {
    final supabase = Supabase.instance.client;

    try {
      final profile = await supabase
          .from('user_profiles')
          .select('account_disable, account_status_logs')
          .eq('user_id', userId)
          .single();

      if (profile['account_disable'] == true) {
        final logs = (profile['account_status_logs'] ?? []) as List;
        final lastChange = logs.isNotEmpty ? logs.last : null;

        if (lastChange != null && lastChange['changed_by'] == 'admin') {
          // Disabled by admin → no self-enable
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('Account Disabled by Admin'),
              content: Text('Please contact support for reactivation.'),
            ),
          );
          return;
        }

        // ✅ If disabled by user, allow reactivation
        await updateAccountStatus(
          userId: userId,
          disabled: false,
          changedBy: 'user_via_otp',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account reactivated successfully!')),
        );
      }
    } catch (e) {
      print('Error reactivating account: $e');
    }
  }
  Future<void> updateAccountStatus({
    required String userId,
    required bool disabled,
    required String changedBy,
  }) async {
    final supabase = Supabase.instance.client;

    try {
      // Update the user_profiles table directly
      await supabase
          .from('user_profiles')
          .update({
        'account_disable': disabled,
        'last_changed_by': changedBy,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('user_id', userId);

      print('✅ Account status updated for $userId');
    } catch (e) {
      print('❌ Error updating account status: $e');
    }
  }

}
