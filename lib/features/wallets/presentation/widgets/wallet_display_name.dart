import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/wallet_entity.dart';

const String _bankWalletId = 'wallet-bank';
const String _cashWalletId = 'wallet-cash';

/// Localized label for a wallet, mapping the seeded defaults by id.
///
/// Persisted wallet names are never rewritten: custom names are returned
/// unchanged and the default ids are translated only for display.
String walletDisplayName(BuildContext context, WalletEntity wallet) {
  return switch (wallet.id) {
    _bankWalletId => context.l10n.bankAccount,
    _cashWalletId => context.l10n.cash,
    _ => wallet.name,
  };
}
