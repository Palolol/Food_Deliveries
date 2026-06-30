import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../providers/app_state.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey                   = GlobalKey<FormState>();
  final _nameController            = TextEditingController();
  final _emailController           = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService               = AuthService();

  bool _isLoading              = false;
  bool _obscurePassword        = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        context.read<AppState>().notifyLogin();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context),
              _buildForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            left: 4,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add_rounded,
                      size: 38, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  'Create Account',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Join us today!',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Fill in your details to get started',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // ── Full Name ───────────────────────────────────────────────────
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outlined),
                hintText: 'John Doe',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your name';
                if (v.trim().length < 2) return 'Name is too short';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── Email ───────────────────────────────────────────────────────
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
                hintText: 'you@example.com',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your email';
                final reg = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
                if (!reg.hasMatch(v)) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── Password ────────────────────────────────────────────────────
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined),
                hintText: 'Min. 6 characters',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please create a password';
                if (v.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── Confirm Password ────────────────────────────────────────────
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleSignup(),
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outlined),
                hintText: 'Re-enter password',
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm your password';
                if (v != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 28),

            // ── Sign Up button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        'Create Account',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // ── JWT security badge ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text(
                  'Secured with JWT Authentication',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Login link ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'Login',
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
