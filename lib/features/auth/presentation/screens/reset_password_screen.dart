// lib/password_reset_request_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:email_validator/email_validator.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/auth_exception_handler.dart';


class ResetPasswordRequestPage extends StatefulWidget {
  const ResetPasswordRequestPage({super.key});

  @override
  State<ResetPasswordRequestPage> createState() =>
      _ResetPasswordRequestPageState();
}

class _ResetPasswordRequestPageState extends State<ResetPasswordRequestPage> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  /// Sends a password reset link to the provided email address.
  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailCtrl.text.trim(),
        redirectTo: 'com.login.app://reset-password',
      );
      if (mounted) {
        _showSuccessDialog();
      }
    } on AuthException catch (e) {
      if (mounted) {
        // MODIFIED: Use the AuthExceptionHandler for better messages.
        _showErrorDialog(AuthExceptionHandler.getErrorMessage(e));
      }
    } catch (_) {
      if (mounted) {
        _showErrorDialog("unexpected_error".tr());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// Shows a success dialog and navigates back on dismissal.
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:  Text("link_sent".tr()),
        content:  Text(
            "reset_link_message".tr()),
        actions: [
          TextButton(
            child:  Text("ok".tr()),
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss dialog
              Navigator.of(context).pop(); // Go back from this page
            },
          ),
        ],
      ),
    );
  }

  /// Shows an error dialog with a specific message.
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:  Text("error".tr()),
        content: Text(message),
        actions: [
          TextButton(
            child:  Text("ok".tr()),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Helper method for creating styled input decorations.
  InputDecoration _inputDecoration(String label, IconData prefixIcon) {
    return InputDecoration(
      filled: true,
      //fillColor: Colors.grey.shade100,
      labelText: label,
      prefixIcon: Icon(prefixIcon, color: Theme.of(context).primaryColorDark),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text("reset_password".tr()),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColorLight,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(28.0),
              decoration: BoxDecoration(
                //color: Colors.white,
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_reset, size: 60, color: Colors.deepPurple),
                    const SizedBox(height: 16),
                    Text(
                      "forgot_password".tr(),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                     Text(
                      "reset_instructions".tr(),
                      textAlign: TextAlign.center,
                      //style: TextStyle(color: Colors.black54, fontSize: 16),
                       style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),

                     ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: _inputDecoration("email".tr(), Icons.email_outlined),
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_loading,
                      validator: (val) {
                        if (val == null || !EmailValidator.validate(val)) {
                          return 'invalid_email'.tr();
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _loading ? null : _sendResetLink,
                        child: _loading
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                            :  Text(
                          'send_reset_link'.tr(),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),

                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}