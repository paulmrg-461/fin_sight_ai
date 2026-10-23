import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/utils/clock.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/auth/presentation/bloc/auth_state.dart';

/// How long before the access token expires a renewal is attempted.
const Duration sessionRenewalLeadTime = Duration(minutes: 5);

/// Delay until the next renewal attempt for a session expiring at [expiresAt].
///
/// The timer fires [leadTime] before expiry, but never sooner than [leadTime]
/// from [now]: an already-expired or offline session would otherwise schedule
/// an immediate refresh and spin in a tight retry loop.
Duration sessionRenewalDelay({
  required DateTime expiresAt,
  required DateTime now,
  Duration leadTime = sessionRenewalLeadTime,
}) {
  final remaining = expiresAt.difference(now) - leadTime;
  return remaining < leadTime ? leadTime : remaining;
}

/// Keeps an authenticated session alive while the app is running.
///
/// Refreshes when the app returns to the foreground and shortly before the
/// access token expires, so a signed-in user stays signed in across restarts
/// and offline launches. Refresh failures never clear local data; that stays
/// reserved for explicit sign-out.
class SessionKeeper extends StatefulWidget {
  const SessionKeeper({
    super.key,
    required this.authBloc,
    required this.child,
    this.clock = const Clock(),
  });

  final AuthBloc authBloc;
  final Widget child;
  final Clock clock;

  @override
  State<SessionKeeper> createState() => _SessionKeeperState();
}

class _SessionKeeperState extends State<SessionKeeper>
    with WidgetsBindingObserver {
  Timer? _renewalTimer;
  late final StreamSubscription<AuthState> _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = widget.authBloc.stream.listen(_onStateChanged);
    _scheduleRenewal(widget.authBloc.state);
  }

  @override
  void dispose() {
    _subscription.cancel();
    _renewalTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        widget.authBloc.state is AuthAuthenticated) {
      widget.authBloc.add(const RestoreAuthSession());
    }
  }

  void _onStateChanged(AuthState state) {
    if (mounted) {
      _scheduleRenewal(state);
    }
  }

  void _scheduleRenewal(AuthState state) {
    _renewalTimer?.cancel();
    _renewalTimer = null;

    if (state is! AuthAuthenticated) {
      return;
    }

    _renewalTimer = Timer(
      sessionRenewalDelay(
        expiresAt: state.session.expiresAt,
        now: widget.clock.now(),
      ),
      _renew,
    );
  }

  void _renew() {
    _renewalTimer = null;
    widget.authBloc.add(const RestoreAuthSession());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
