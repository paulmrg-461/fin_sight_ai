import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/routing/app_routes.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Drawer account row: opens login or signs out with confirmation.
class AccountTile extends StatelessWidget {
  const AccountTile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return ListTile(
            leading: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text(context.l10n.loading),
          );
        }

        if (state is AuthAuthenticated) {
          return ListTile(
            leading: const Icon(Icons.logout),
            title: Text(context.l10n.signOut),
            onTap: () => confirmSignOut(context),
          );
        }

        return ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(context.l10n.signIn),
          subtitle: Text(context.l10n.signInToSync),
          onTap: () => context.pushNamed(AppRoutes.loginName),
        );
      },
    );
  }
}

/// Confirms and dispatches sign-out. Shared by the drawer entry point.
Future<void> confirmSignOut(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        title: Text(dialogContext.l10n.signOutQuestion),
        content: Text(dialogContext.l10n.signOutEraseBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(dialogContext.l10n.signOut),
          ),
        ],
      );
    },
  );

  if ((confirmed ?? false) && context.mounted) {
    Scaffold.maybeOf(context)?.closeDrawer();
    context.read<AuthBloc>().add(const SignOutRequested());
  }
}
