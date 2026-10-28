import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../bloc/security_cubit.dart';
import '../bloc/security_state.dart';

/// Covers the app until biometric authentication succeeds.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _locked = false;
  bool _authenticating = false;
  StreamSubscription<SecurityState>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final cubit = context.read<SecurityCubit>();
    _subscription = cubit.stream.listen(_onSecurityState);
    cubit.load();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final security = context.read<SecurityCubit>().state;
      if (security.enabled) {
        setState(() => _locked = true);
      }
    }
  }

  void _onSecurityState(SecurityState state) {
    if (state.loading) {
      return;
    }
    if (state.enabled && !_locked) {
      setState(() => _locked = true);
      _unlock();
    } else if (!state.enabled && _locked) {
      setState(() => _locked = false);
    }
  }

  Future<void> _unlock() async {
    if (_authenticating) {
      return;
    }
    setState(() => _authenticating = true);
    final success = await context.read<SecurityCubit>().authenticate();
    if (mounted) {
      setState(() {
        _authenticating = false;
        _locked = !success;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityCubit>().state;
    if (security.loading || !security.enabled || !_locked) {
      return widget.child;
    }
    return _LockScreen(authenticating: _authenticating, onUnlock: _unlock);
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.authenticating, required this.onUnlock});

  final bool authenticating;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.fingerprint_rounded,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.appLockedTitle,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.appLockedBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: authenticating ? null : onUnlock,
                  icon: authenticating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_open_rounded),
                  label: Text(l10n.unlockApp),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
