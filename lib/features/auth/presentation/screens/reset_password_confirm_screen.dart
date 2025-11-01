import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/password_validator.dart';
import '../../utils/auth_exception_handler.dart';
import 'package:easy_localization/easy_localization.dart';
class ResetPasswordPageDeepLink extends StatefulWidget {
  final Uri? uri;
  const ResetPasswordPageDeepLink({this.uri, super.key});

  @override
  State<ResetPasswordPageDeepLink> createState() =>
      _ResetPasswordPageDeepLinkState();
}

class _ResetPasswordPageDeepLinkState extends State<ResetPasswordPageDeepLink> {
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;

  /// Updates the user's password with the new value.
  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordCtrl.text.trim()),
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

  /// Shows a success dialog and navigates to the login page.
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close
      builder: (context) => AlertDialog(
        title:  Text("success".tr()),
        content:  Text("password_updated".tr()),
        actions: [
          TextButton(
            child:  Text("go_to_login".tr()),
            onPressed: () {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (route) => false);
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

  InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade100,
      labelText: label,
      prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).primaryColorDark),
      suffixIcon: suffixIcon,
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
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text("set_new_password".tr()),
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
                    const Icon(Icons.lock_person, size: 60, color: Colors.deepPurple),
                    const SizedBox(height: 16),
                    Text(
                      "create_new_password".tr(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration(
                        "new_password".tr(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      enabled: !_loading,
                      // MODIFIED: Use the dedicated password validator.
                      validator: PasswordValidator.validatePassword,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordCtrl,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration("confirm_new_password".tr()),
                      enabled: !_loading,
                      validator: (val) {
                        if (val != _passwordCtrl.text) {
                          return 'passwords_do_not_match'.tr();
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
                        onPressed: _loading ? null : _updatePassword,
                        child: _loading
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3),
                        )
                            :  Text(
                          'update_password'.tr(),
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
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
