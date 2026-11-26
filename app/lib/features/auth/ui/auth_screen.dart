import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_app/app_theme.dart';
import 'package:pantry_app/features/auth/state/auth_provider.dart';

/// Single authentication screen supporting both Login and Sign up modes
/// with a soothing sage-and-forest-green Stockora design.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _identifierController = TextEditingController();
  final _secretController = TextEditingController();
  final _confirmSecretController = TextEditingController();

  bool _isLogin = true;
  bool _obscureSecret = true;
  bool _obscureConfirmSecret = true;

  @override
  void dispose() {
    _nameController.dispose();
    _identifierController.dispose();
    _secretController.dispose();
    _confirmSecretController.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _isLogin = !_isLogin;
      _confirmSecretController.clear();
      _formKey.currentState?.reset();
    });
    context.read<AuthProvider>().clearError();
  }

  Future<void> _submit() async {
    context.read<AuthProvider>().clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    if (auth.isSubmitting) return;

    final identifier = _identifierController.text.trim();
    final secret = _secretController.text.trim();

    if (_isLogin) {
      await auth.login(identifier, secret);
    } else {
      final name = _nameController.text.trim();
      await auth.signup(name, identifier, secret);
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 15,
        color: AppTheme.textSecondary,
      ),
      prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD2DBD4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD2DBD4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.statusExpired),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.statusExpired, width: 1.6),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.softMintTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBD8C3)),
              ),
              child: const Icon(
                Icons.kitchen_rounded,
                color: AppTheme.primaryGreen,
                size: 26,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Stockora',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.eco_rounded,
              color: AppTheme.primaryGreenLight,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 18, height: 1.5, color: AppTheme.primaryGreenLight),
            const SizedBox(width: 8),
            const Text(
              'PANTRY  •  TRACK  •  NO WASTE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 18, height: 1.5, color: AppTheme.primaryGreenLight),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroIllustration() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.softMintTint,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!_isLogin) ...[
            const Text('🪴', style: TextStyle(fontSize: 34)),
            const SizedBox(width: 10),
          ],
          _jarCard('🌾', const Color(0xFFFFF4D6), 48),
          const SizedBox(width: 10),
          _jarCard('🫘', const Color(0xFFFFEBD6), 42),
          const SizedBox(width: 10),
          _jarCard('🍯', const Color(0xFFFDE5D4), 38),
          if (_isLogin) ...[
            const SizedBox(width: 10),
            const Text('🌿', style: TextStyle(fontSize: 28)),
          ],
        ],
      ),
    );
  }

  Widget _jarCard(String emoji, Color bg, double size) {
    return Container(
      width: size,
      height: size + 8,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD5B48A), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: size * 0.52)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isSubmitting = authProvider.isSubmitting;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBF9),
      body: Stack(
        children: [
          // Soft sage decorative background shapes
          Positioned(
            top: -70,
            left: -60,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBrandHeader(),
                        const SizedBox(height: 18),
                        Center(child: _buildHeroIllustration()),
                        const SizedBox(height: 20),

                        // Heading & Subtitle
                        Text(
                          _isLogin ? 'Welcome Back!' : 'Create Your Account',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isLogin
                              ? 'Login to continue managing your pantry.'
                              : 'Start managing your pantry smarter.',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 22),

                        // Backend error banner
                        if (authProvider.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                              vertical: 12.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.statusExpiredContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFF3B4B4),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppTheme.statusExpired,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    authProvider.errorMessage!,
                                    style: const TextStyle(
                                      color: AppTheme.statusExpired,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Name Field (Sign Up only)
                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 16),
                            decoration: _inputDecoration(
                              hint: 'Name',
                              icon: Icons.person_outline_rounded,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Phone or Email Field
                        TextFormField(
                          controller: _identifierController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(fontSize: 16),
                          decoration: _inputDecoration(
                            hint: 'Phone or Email',
                            icon: Icons.mail_outline_rounded,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your phone number or email.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // PIN or Password Field
                        TextFormField(
                          controller: _secretController,
                          obscureText: _obscureSecret,
                          textInputAction: _isLogin
                              ? TextInputAction.done
                              : TextInputAction.next,
                          onFieldSubmitted: _isLogin ? (_) => _submit() : null,
                          style: const TextStyle(fontSize: 16),
                          decoration: _inputDecoration(
                            hint: 'PIN or Password',
                            icon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureSecret
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppTheme.textSecondary,
                              ),
                              tooltip: _obscureSecret
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () {
                                setState(() {
                                  _obscureSecret = !_obscureSecret;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your PIN or password.';
                            }
                            final cleaned = value.trim();
                            final isNumeric = cleaned.split('').every(
                                  (ch) => '0123456789'.contains(ch),
                                );

                            if (isNumeric) {
                              if (cleaned.length < 4) {
                                return 'Numeric PIN must be at least 4 digits.';
                              }
                            } else {
                              if (cleaned.length < 6) {
                                return 'Password must be at least 6 characters.';
                              }
                            }
                            return null;
                          },
                        ),

                        // Confirm Password (Sign Up only)
                        if (!_isLogin) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmSecretController,
                            obscureText: _obscureConfirmSecret,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            style: const TextStyle(fontSize: 16),
                            decoration: _inputDecoration(
                              hint: 'Confirm Password',
                              icon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmSecret
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppTheme.textSecondary,
                                ),
                                tooltip: _obscureConfirmSecret
                                    ? 'Show password'
                                    : 'Hide password',
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmSecret =
                                        !_obscureConfirmSecret;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please confirm your PIN or password.';
                              }
                              if (value.trim() !=
                                  _secretController.text.trim()) {
                                return 'Passwords do not match.';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 22),

                        // Primary Action Button
                        FilledButton(
                          onPressed: isSubmitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isLogin ? 'Log In' : 'Create Account',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Mode Toggle Footer
                        Center(
                          child: TextButton(
                            onPressed: isSubmitting ? null : _switchMode,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                            child: Text.rich(
                              TextSpan(
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.textSecondary,
                                ),
                                children: [
                                  TextSpan(
                                    text: _isLogin
                                        ? "Don't have an account? "
                                        : 'Already have an account? ',
                                  ),
                                  TextSpan(
                                    text: _isLogin ? 'Sign Up' : 'Log In',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryGreen,
                                    ),
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
          ),
        ],
      ),
    );
  }
}
