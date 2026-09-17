import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alias/providers/auth_provider.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
const _kCream = Color(0xFFF0E8D8);
const _kParchment = Color(0xFFE8DCC4);
const _kSage = Color(0xFF8DA399);
const _kDarkText = Color(0xFF2C3E35);
const _kMutedText = Color(0xFF8A9080);
const _kWhite = Color(0xFFFFFFFF);

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _termsAccepted = false;
  Timer? _debounce;
  bool? _isUsernameAvailable;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (value.length >= 3 &&
        value.length <= 20 &&
        RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      _debounce = Timer(const Duration(milliseconds: 600), () async {
        setState(() => _isUsernameAvailable = true);
      });
    } else {
      setState(() => _isUsernameAvailable = false);
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate() && _termsAccepted) {
      await ref.read(authNotifierProvider.notifier).register(
            _emailController.text.trim(),
            _passwordController.text,
            _usernameController.text.trim(),
          );
      final hasError = ref.read(authNotifierProvider).hasError;
      if (!hasError && mounted) {
        context.go('/home');
      }
    } else if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept Terms & Conditions')),
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon,
      {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _kMutedText, fontSize: 14),
      prefixIcon: Icon(icon, color: _kMutedText, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: _kWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0D8C8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0D8C8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kSage, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final error = ref.read(authNotifierProvider.notifier).errorMessage;

    return Scaffold(
      backgroundColor: _kCream,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Top Panel ─────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(28, 48, 28, 32),
                    decoration: const BoxDecoration(
                      color: _kParchment,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _kWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFE0D8C8)),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new,
                                size: 16, color: _kDarkText),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Create\nAccount ✨',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: _kDarkText,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Join Alias — private, simple messaging',
                          style: TextStyle(
                              color: _kMutedText,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  // ── Form ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(error,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 13),
                                  textAlign: TextAlign.center),
                            ),

                          // Username
                          TextFormField(
                            controller: _usernameController,
                            onChanged: _onUsernameChanged,
                            decoration: _inputDecoration(
                              'Username',
                              Icons.alternate_email,
                              suffix: _isUsernameAvailable == null
                                  ? null
                                  : Icon(
                                      _isUsernameAvailable!
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: _isUsernameAvailable!
                                          ? Colors.green
                                          : Colors.red,
                                      size: 20,
                                    ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Please enter username';
                              }
                              if (v.length < 3 || v.length > 20) {
                                return 'Username must be 3–20 characters';
                              }
                              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
                                return 'Only letters, numbers, underscore';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration(
                                'Email', Icons.email_outlined),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Please enter email'
                                : null,
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration:
                                _inputDecoration('Password', Icons.lock_outline,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: _kMutedText,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() =>
                                          _obscurePassword =
                                              !_obscurePassword),
                                    )),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Please enter password'
                                : null,
                          ),
                          const SizedBox(height: 14),

                          // Confirm Password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            decoration: _inputDecoration(
                              'Confirm Password',
                              Icons.lock_outline,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: _kMutedText,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Please confirm password';
                              }
                              if (v != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Terms
                          InkWell(
                            onTap: () => setState(
                                () => _termsAccepted = !_termsAccepted),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: _termsAccepted
                                          ? _kSage
                                          : _kWhite,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      border: Border.all(
                                          color: _termsAccepted
                                              ? _kSage
                                              : const Color(0xFFE0D8C8),
                                          width: 1.5),
                                    ),
                                    child: _termsAccepted
                                        ? const Icon(Icons.check,
                                            size: 14,
                                            color: _kWhite)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'I agree to the Terms & Conditions',
                                      style: TextStyle(
                                          color: _kDarkText,
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Create Account button
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kSage,
                                disabledBackgroundColor:
                                    _kSage.withValues(alpha: 0.6),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          color: _kWhite, strokeWidth: 2.5),
                                    )
                                  : const Text(
                                      'Create Account',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: _kWhite),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Sign in link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account?',
                                  style: TextStyle(
                                      color: _kMutedText, fontSize: 14)),
                              TextButton(
                                onPressed: () => context.go('/login'),
                                style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8)),
                                child: const Text('Sign In',
                                    style: TextStyle(
                                        color: _kSage,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (isLoading)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(color: _kSage),
              ),
            ),
        ],
      ),
    );
  }
}
