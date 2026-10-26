import 'package:material_ui/material_ui.dart';

import 'l10n.dart';

/// Translates the user-facing failures emitted by the domain layer.
///
/// The domain stays Flutter-free and keeps stable English messages; this
/// presentation helper maps them to the active language and falls back to the
/// original text for anything not covered yet.
extension FailureText on BuildContext {
  String failureText(String message) {
    final l10n = this.l10n;
    final trimmed = message.trim();

    final exact = switch (trimmed) {
      'Amount must be greater than zero.' => l10n.errAmountPositive,
      'Amount lent must be greater than zero.' => l10n.errAmountLentPositive,
      'Payment amount must be greater than zero.' =>
        l10n.errPaymentAmountPositive,
      'Monthly limit must be greater than zero.' =>
        l10n.errMonthlyLimitPositive,
      'Monthly payment must be greater than zero.' =>
        l10n.errMonthlyPaymentPositive,
      'Total amount must be greater than zero.' => l10n.errTotalPositive,
      'Transfer amount must be greater than zero.' => l10n.errTransferPositive,
      'Receipt total must be greater than zero.' =>
        l10n.errReceiptTotalPositive,
      'Item quantity must be greater than zero.' => l10n.errQuantityPositive,
      'Category is required.' => l10n.errCategoryRequired,
      'Category name is required.' => l10n.errCategoryNameRequired,
      'Category not found.' => l10n.errCategoryNotFound,
      'A category with that name already exists.' => l10n.errCategoryDuplicate,
      'Transaction not found.' => l10n.errTransactionNotFound,
      'Debt not found.' => l10n.errDebtNotFound,
      'Receivable not found.' => l10n.errReceivableNotFound,
      'Scheduled payment not found.' => l10n.errScheduledNotFound,
      'Wallet not found.' => l10n.errWalletNotFound,
      'The start date must be before the end date.' => l10n.errStartBeforeEnd,
      'The due date cannot be before the date lent.' => l10n.errDueAfterLent,
      'The amount cannot change after payments were received.' =>
        l10n.errAmountLocked,
      'This debt is already paid off.' => l10n.errDebtPaid,
      'This receivable is already paid.' => l10n.errReceivablePaid,
      'Insufficient funds in the source wallet.' => l10n.errInsufficientFunds,
      'Choose two different wallets.' => l10n.errChooseDifferentWallets,
      'Choose both wallets.' => l10n.errChooseWallets,
      'Notes must be 500 characters or fewer.' => l10n.errNotesTooLong,
      'Notes are too long.' => l10n.errNotesTooLong,
      'Description must be 500 characters or fewer.' =>
        l10n.errDescriptionTooLong,
      'Creditor name is required.' => l10n.errCreditorRequired,
      'Debtor name is required.' => l10n.errDebtorRequired,
      'Debtor name is too long.' => l10n.errDebtorTooLong,
      'Payment name is required.' => l10n.errPaymentNameRequired,
      'Merchant name is required.' => l10n.errMerchantRequired,
      'Every receipt item needs a name.' => l10n.errReceiptItemName,
      'No text was detected in the receipt image.' => l10n.errReceiptNoText,
      'Receipt image path is required.' => l10n.errReceiptImage,
      'Enter a valid email address.' => l10n.errInvalidEmail,
      'Password must be at least 6 characters.' => l10n.errWeakPassword,
      'Authentication failed.' => l10n.errAuthFailed,
      'Could not create the account.' => l10n.errSignupFailed,
      'Could not restore the session.' => l10n.errRestoreFailed,
      'Synchronization failed. Pending changes were kept.' =>
        l10n.errSyncFailedQueueKept,
      'Synchronization failed.' => l10n.errSyncFailed,
      'Synchronization received invalid data.' => l10n.errSyncInvalidData,
      'The AI coach returned an empty response.' => l10n.errAiEmpty,
      'Unable to reach the AI coach. Please try again.' =>
        l10n.errAiUnreachable,
      _ => null,
    };
    if (exact != null) {
      return exact;
    }

    if (trimmed.startsWith('Unable to read ')) {
      return l10n.errReadLocal;
    }
    if (trimmed.startsWith('Unable to save ')) {
      return l10n.errSaveLocal;
    }
    if (trimmed.startsWith('Unable to delete ')) {
      return l10n.errDeleteLocal;
    }
    if (trimmed.startsWith('Unable to update ')) {
      return l10n.errUpdateLocal;
    }
    if (trimmed.startsWith('Unable to calculate ')) {
      return l10n.errCalculate;
    }
    if (trimmed.startsWith('Unable to record ')) {
      return l10n.errRecord;
    }
    if (trimmed.startsWith('Unable to rename ')) {
      return l10n.errRename;
    }
    if (trimmed.startsWith('Unable to process ')) {
      return l10n.errProcess;
    }
    if (trimmed.startsWith('Unable to scan ')) {
      return l10n.errScan;
    }
    if (trimmed.startsWith('Unable to transfer ')) {
      return l10n.errTransfer;
    }
    if (trimmed.startsWith('Could not ')) {
      return l10n.errGeneric;
    }
    return message;
  }
}
