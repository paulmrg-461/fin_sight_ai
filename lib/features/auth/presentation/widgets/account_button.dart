import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/routing/app_routes.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// App-bar account control: opens login or signs out.
class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return IconButton(
            onPressed: null,
            tooltip: context.l10n.loading,
            icon: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (state is AuthAuthenticated) {
          return IconButton(
            onPressed: () =>
                context.read<AuthBloc>().add(const SignOutRequested()),
            tooltip: context.l10n.signOutEmail(state.session.email),
            icon: const Icon(Icons.logout),
          );
        }

        return IconButton(
          onPressed: () => context.pushNamed(AppRoutes.loginName),
          tooltip: context.l10n.signIn,
          icon: const Icon(Icons.person_outline),
        );
      },
    );
  }
}
