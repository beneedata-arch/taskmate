import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../utils/ui.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  bool _hidePassword = true;
  bool _termsAccepted = false;
  int _passwordScore = 0;
  bool _isEduEmail = false;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_evaluatePasswordStrength);
    _emailCtrl.addListener(_evaluateEmail);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _evaluateEmail() {
    final email = _emailCtrl.text.trim().toLowerCase();
    setState(() {
      _isEduEmail = email.endsWith('.edu') || email.contains('.edu.');
    });
  }

  void _evaluatePasswordStrength() {
    final val = _passwordCtrl.text;
    int score = 0;
    if (val.length >= 8) score++;
    if (RegExp(r'[0-9]').hasMatch(val)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(val)) score++;
    if (val.length >= 12 || (score == 3 && RegExp(r'[A-Z]').hasMatch(val))) score++;

    setState(() {
      _passwordScore = val.isEmpty ? 0 : score;
    });
  }

  String get _strengthLabel {
    if (_passwordCtrl.text.isEmpty) return 'Too weak';
    switch (_passwordScore) {
      case 1:
        return 'Weak';
      case 2:
        return 'Moderate';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return 'Too weak';
    }
  }

  Color get _strengthColor {
    if (_passwordCtrl.text.isEmpty) return TaskMateColors.outline;
    switch (_passwordScore) {
      case 1:
        return TaskMateColors.error;
      case 2:
        return TaskMateColors.amber;
      case 3:
        return TaskMateColors.secondary;
      case 4:
        return TaskMateColors.primary;
      default:
        return TaskMateColors.outline;
    }
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_termsAccepted) {
      showMessage('Please agree to the Honor Code and Campus Privacy Policy.');
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.register(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
      if (mounted) {
        showMessage('Welcome to TaskMate!', isSuccess: true);
        Navigator.of(context).pop();
      }
    } catch (e) {
      showMessage(AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p1 = _passwordCtrl.text;
    final p2 = _confirmCtrl.text;
    final hasConfirm = p2.isNotEmpty;
    final passwordsMatch = hasConfirm && p1 == p2;

    return Scaffold(
      backgroundColor: TaskMateColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: TaskMateColors.secondaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.local_library_rounded,
                                size: 28,
                                color: TaskMateColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: TaskMateColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: TaskMateColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'FALL TERM PREP',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: TaskMateColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Create Account',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: TaskMateColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start organizing your semester today with calm, focused clarity.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: TaskMateColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Card Form
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: TaskMateColors.surfaceCard,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: TaskMateColors.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Full Name
                          Text(
                            'Student Name',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TaskMateColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.plusJakartaSans(fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Alex Student',
                              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                            ),
                            validator: (v) {
                              if ((v ?? '').trim().isEmpty) {
                                return 'Please enter your name.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Email
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Student Email',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: TaskMateColors.onSurfaceVariant,
                                ),
                              ),
                              if (_isEduEmail)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: TaskMateColors.secondaryContainer,
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: Text(
                                    '.edu verified',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: TaskMateColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.plusJakartaSans(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'name@university.edu',
                              prefixIcon: const Icon(Icons.school_outlined, size: 20),
                              suffixIcon: _isEduEmail
                                  ? const Icon(
                                      Icons.verified_rounded,
                                      color: TaskMateColors.primary,
                                      size: 18,
                                    )
                                  : null,
                            ),
                            validator: (v) {
                              final text = (v ?? '').trim();
                              if (text.isEmpty) return 'Enter your email.';
                              if (!text.contains('@') || !text.contains('.')) {
                                return 'Enter a valid university email address.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password
                          Text(
                            'Password',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TaskMateColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _hidePassword,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.plusJakartaSans(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Create master passcode',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: TaskMateColors.outline,
                                ),
                                onPressed: () {
                                  setState(() => _hidePassword = !_hidePassword);
                                },
                              ),
                            ),
                            validator: (v) {
                              if ((v ?? '').length < 6) {
                                return 'Password must be at least 6 characters.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // Password Strength Meter
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: TaskMateColors.surfaceLow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Security Strength',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: TaskMateColors.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      _strengthLabel.toUpperCase(),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _strengthColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: List.generate(4, (index) {
                                    final active = index < _passwordScore;
                                    return Expanded(
                                      child: Container(
                                        margin: EdgeInsets.only(
                                          right: index < 3 ? 4 : 0,
                                        ),
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: active
                                              ? _strengthColor
                                              : TaskMateColors.surfaceHighest,
                                          borderRadius: BorderRadius.circular(9999),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Must be 8+ characters with at least one number & symbol.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: TaskMateColors.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Confirm Password
                          Text(
                            'Confirm Password',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TaskMateColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confirmCtrl,
                            obscureText: _hidePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _register(),
                            onChanged: (_) => setState(() {}),
                            style: GoogleFonts.plusJakartaSans(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Repeat master passcode',
                              prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                              suffixIcon: hasConfirm
                                  ? Icon(
                                      passwordsMatch
                                          ? Icons.check_circle_rounded
                                          : Icons.cancel_rounded,
                                      color: passwordsMatch
                                          ? TaskMateColors.primary
                                          : TaskMateColors.error,
                                      size: 18,
                                    )
                                  : null,
                            ),
                            validator: (v) {
                              if ((v ?? '') != _passwordCtrl.text) {
                                return 'Passwords do not match.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Terms agreement checkbox
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  value: _termsAccepted,
                                  activeColor: TaskMateColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (val) {
                                    setState(() => _termsAccepted = val ?? false);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'I agree to the Honor Code and acknowledge the Campus Privacy Policy.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: TaskMateColors.onSurfaceVariant,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Submit Button
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TaskMateColors.primaryContainer,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                              ),
                              onPressed: _loading ? null : _register,
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.assignment_turned_in_rounded,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Create Account',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Security Notice
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: TaskMateColors.surfaceLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.verified_user_rounded,
                                  size: 14,
                                  color: TaskMateColors.secondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Secured Student Account',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: TaskMateColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Switch to login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: TaskMateColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            'Log In',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: TaskMateColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
