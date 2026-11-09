import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/kom_button.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phone;

  const OtpVerificationScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validateCode(String? value) {
    if (value == null || value.length != 6) return 'Enter the 6-digit code';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'Digits only';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      await ref
          .read(authProvider.notifier)
          .verifyOtp(widget.phone, _controller.text.trim());
      // Router redirect handles navigation to /browse on success
    } catch (_) {
      // Error is in auth state
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(authProvider.notifier).requestOtp(widget.phone);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code resent')),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Verify phone'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text('Enter the 6-digit code',
                    style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Sent to ${widget.phone}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Verification code',
                    hintText: '000000',
                    counterText: '',
                  ),
                  validator: _validateCode,
                ),
                if (authState.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    authState.error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.riskHighFg,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                KomButton(
                  label: 'Verify',
                  onPressed: authState.isLoading ? null : _submit,
                  isLoading: authState.isLoading,
                  fullWidth: true,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: authState.isLoading ? null : _resend,
                    child: const Text('Resend code'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
