// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'FinSight AI';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get mainMenu => 'Main menu';

  @override
  String get more => 'More';

  @override
  String get preferences => 'Preferences';

  @override
  String get openMenu => 'Open menu';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get retry => 'Retry';

  @override
  String get add => 'Add';

  @override
  String get settings => 'Settings';

  @override
  String get loading => 'Loading…';

  @override
  String get somethingWentWrong => 'Something went wrong.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get createAccountTitle => 'Create your account';

  @override
  String get signInSubtitle =>
      'Sign in to sync transactions and debts with Supabase.';

  @override
  String get createAccount => 'Create an account';

  @override
  String get alreadyHaveAccount => 'I already have an account';

  @override
  String get signInToSync => 'Sign in to sync';

  @override
  String get invalidEmail => 'Enter a valid email address.';

  @override
  String get weakPassword => 'Password must be at least 6 characters.';

  @override
  String get checkEmailConfirmation =>
      'Check your email to confirm the account.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String signOutEmail(String email) {
    return 'Sign out ($email)';
  }

  @override
  String get signOutQuestion => 'Sign out and erase local data?';

  @override
  String get signOutEraseBody =>
      'Local transactions and pending changes on this device will be deleted. Sync first if you need them.';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get transactions => 'Transactions';

  @override
  String get debts => 'Debts';

  @override
  String get budgets => 'Budgets';

  @override
  String get money => 'Money';

  @override
  String get scanReceipt => 'Scan receipt';

  @override
  String get aiCoach => 'AI coach';

  @override
  String get addTransaction => 'Add transaction';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get noTransactionsBody =>
      'Add your first income or expense to unlock spending insights.';

  @override
  String get addFirstTransaction => 'Add a transaction';

  @override
  String get changePeriod => 'Change period';

  @override
  String get switchToLight => 'Switch to light mode';

  @override
  String get switchToDark => 'Switch to dark mode';

  @override
  String get income => 'Income';

  @override
  String get expenses => 'Expenses';

  @override
  String get balance => 'Balance';

  @override
  String get savingsRate => 'Savings rate';

  @override
  String get spendingByCategory => 'Spending by category';

  @override
  String get noExpensesPeriod => 'No expenses in this period.';

  @override
  String get monthlyExpenses => 'Monthly expenses';

  @override
  String get recentActivity => 'Recent activity';

  @override
  String get syncOfflineNotConfigured =>
      'Sync offline: Supabase is not configured';

  @override
  String get syncFailedRetry => 'Sync failed. Tap to retry';

  @override
  String syncNowPending(int count) {
    return 'Sync now ($count pending)';
  }

  @override
  String get allChangesSynced => 'All changes synced';

  @override
  String get synchronizing => 'Synchronizing…';

  @override
  String get newTransaction => 'New transaction';

  @override
  String get expense => 'Expense';

  @override
  String get incomeShort => 'Income';

  @override
  String get amount => 'Amount';

  @override
  String get category => 'Category';

  @override
  String get description => 'Description';

  @override
  String get date => 'Date';

  @override
  String get receiptPathOptional => 'Receipt image path (optional)';

  @override
  String get saveTransaction => 'Save transaction';

  @override
  String get filterByDate => 'Filter by date';

  @override
  String get noTransactionsInRange => 'No transactions in this range.';

  @override
  String get noTransactionsRangeBody =>
      'Try a different date range or clear the filter.';

  @override
  String get clearFilter => 'Clear';

  @override
  String get noTransactionsCategory => 'No transactions in this category.';

  @override
  String get deleteTransaction => 'Delete transaction';

  @override
  String get loadingTransactions => 'Loading transactions';

  @override
  String get enterAmountGreaterThanZero => 'Enter an amount greater than zero.';

  @override
  String get categoryRequired => 'Category is required.';

  @override
  String get sync => 'Sync';

  @override
  String get addDebt => 'Add debt';

  @override
  String get creditorName => 'Creditor name';

  @override
  String get totalAmount => 'Total amount';

  @override
  String get annualInterestRate => 'Annual interest rate';

  @override
  String get minimumMonthlyPayment => 'Minimum monthly payment';

  @override
  String get dueDate => 'Due date';

  @override
  String get saveDebt => 'Save debt';

  @override
  String get active => 'Active';

  @override
  String get paid => 'Paid';

  @override
  String get remaining => 'remaining';

  @override
  String get ofLabel => 'of';

  @override
  String get total => 'total';

  @override
  String get minimum => 'Minimum';

  @override
  String get debtDetails => 'Debt details';

  @override
  String get makePayment => 'Make a payment';

  @override
  String get paymentAmount => 'Payment amount';

  @override
  String get pay => 'Pay';

  @override
  String get deleteDebt => 'Delete debt';

  @override
  String get deleteDebtQuestion => 'Delete debt?';

  @override
  String get deleteDebtBody => 'This removes the debt and its payment history.';

  @override
  String get payoffCalculator => 'Payoff calculator';

  @override
  String get monthlyPayment => 'Monthly payment';

  @override
  String get calculate => 'Calculate';

  @override
  String projectedPayoff(String date) {
    return 'Projected payoff: $date';
  }

  @override
  String get paymentNotCoverInterest =>
      'This payment does not cover the monthly interest.';

  @override
  String get paymentHistory => 'Payment history';

  @override
  String get noPaymentsYet => 'No payments recorded yet.';

  @override
  String get creditorRequired => 'Creditor name is required.';

  @override
  String get rateRange => 'Enter a rate between 0 and 100.';

  @override
  String get minPaymentGreaterThanZero => 'Enter a value greater than zero.';

  @override
  String get newBudget => 'New budget';

  @override
  String get addBudget => 'Add budget';

  @override
  String get addAnotherBudget => 'Add another budget';

  @override
  String get monthlyLimit => 'Monthly limit';

  @override
  String get saveBudget => 'Save budget';

  @override
  String get noBudgetsYet => 'No budgets yet';

  @override
  String get noBudgetsBody =>
      'Set a monthly limit per category and track your progress.';

  @override
  String get limitGreaterThanZero => 'Enter a limit greater than zero.';

  @override
  String get overBudgetBy => 'Over budget by ';

  @override
  String get scanReceipts => 'Scan receipts';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get noReceiptsYet => 'No receipts yet';

  @override
  String get noReceiptsBody =>
      'Scan a receipt to extract the merchant, total, and line items.';

  @override
  String get scanAReceipt => 'Scan a receipt';

  @override
  String get loadingReceipts => 'Loading receipts';

  @override
  String get extractingData => 'Extracting receipt data…';

  @override
  String get savingReceipt => 'Saving receipt…';

  @override
  String get finishingUp => 'Finishing up…';

  @override
  String get receiptSavedExpenseFailed =>
      'Receipt saved, but the expense could not be recorded.';

  @override
  String get receiptPreview => 'Receipt preview';

  @override
  String get merchant => 'Merchant';

  @override
  String get currency => 'Currency';

  @override
  String get items => 'Items';

  @override
  String get addItem => 'Add item';

  @override
  String get noItemsExtracted =>
      'No items extracted. Add them manually if needed.';

  @override
  String get itemName => 'Name';

  @override
  String get quantity => 'Quantity';

  @override
  String get unitPrice => 'Unit price';

  @override
  String get saveReceipt => 'Save receipt';

  @override
  String get editItem => 'Edit item';

  @override
  String get removeItem => 'Remove item';

  @override
  String get nameRequired => 'Name is required.';

  @override
  String get enterValidPrice => 'Enter a valid price.';

  @override
  String get totalGreaterThanZero => 'Enter an amount greater than zero.';

  @override
  String get moneyTitle => 'Money';

  @override
  String get totalAvailable => 'Total available';

  @override
  String get bankPlusCash => 'Bank account + cash';

  @override
  String get bankAccount => 'Bank account';

  @override
  String get cash => 'Cash';

  @override
  String get setBalance => 'Set balance';

  @override
  String get actualBalance => 'Actual balance';

  @override
  String get currentBalance => 'Current balance';

  @override
  String get transfer => 'Transfer';

  @override
  String get transferMoney => 'Transfer money';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get transferBetweenWallets => 'Transfer between wallets';

  @override
  String get enterValidBalance => 'Enter a valid balance.';

  @override
  String get chooseDifferentWallets => 'Choose two different wallets.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get currencyDescription =>
      'Changing the currency updates labels and formatting. Amounts are not converted with exchange rates.';

  @override
  String get language => 'Language';

  @override
  String get languageDescription =>
      'Choose the app language. System follows your device.';

  @override
  String get systemLanguage => 'System';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Español';

  @override
  String get yourFinancialCoach => 'Your financial coach';

  @override
  String get insightsDisclaimer =>
      'Insights are generated from your recent activity and are not financial advice.';

  @override
  String get analyzeSpending => 'Analyze spending';

  @override
  String get savingsTips => 'Savings tips';

  @override
  String get refresh => 'Refresh';

  @override
  String get thinking => 'Thinking about your finances…';

  @override
  String get coachReady => 'Your coach is ready';

  @override
  String get coachReadyBody =>
      'Ask for spending analysis or personalized savings suggestions.';

  @override
  String get getInsights => 'Get insights';

  @override
  String get insightsError => 'Unable to reach the AI coach. Please try again.';

  @override
  String get noReceiptText => 'No text was detected in the receipt image.';

  @override
  String get receiptImageError => 'Unable to prepare the receipt image.';

  @override
  String itemsCount(int count) {
    return '$count items';
  }

  @override
  String get viewAll => 'View all';

  @override
  String get search => 'Search';

  @override
  String get period => 'Period';

  @override
  String get copCurrencyLabel => 'COP — Colombian peso';

  @override
  String get usdCurrencyLabel => 'USD — US dollar';

  @override
  String get suggestion => 'Suggestion';

  @override
  String get alert => 'Alert';

  @override
  String get analysis => 'Analysis';

  @override
  String setBalanceTitle(String name) {
    return 'Set $name balance';
  }

  @override
  String budgetUsage(String category) {
    return 'Budget usage for $category';
  }

  @override
  String get debtPayment => 'Debt payment';

  @override
  String get transferAmount => 'Amount';

  @override
  String get all => 'All';

  @override
  String get accountOrCash => 'Account / cash';

  @override
  String get noDebtsYet => 'No debts tracked.';

  @override
  String get noDebtsBody =>
      'Add a debt to track balances and project your payoff date.';

  @override
  String get loadingDebts => 'Loading debts';

  @override
  String get updatingDebt => 'Updating debt';

  @override
  String get debtNotFound => 'Debt not found.';

  @override
  String get enterValidMonthlyPayment => 'Enter a valid monthly payment.';

  @override
  String get debtRepaymentProgress => 'Debt repayment progress';

  @override
  String aprDue(String rate, String date) {
    return '$rate% APR • Due $date';
  }

  @override
  String minPerMonth(String amount) {
    return 'Minimum $amount/mo';
  }

  @override
  String dueOn(String date) {
    return 'Due $date';
  }

  @override
  String get deleteBudget => 'Delete budget';

  @override
  String get isoCode => 'ISO';

  @override
  String get receiptImage => 'Receipt image';

  @override
  String transactionRef(String id) {
    return 'Transaction $id';
  }

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoriesDescription =>
      'Manage the categories used by transactions, budgets, and scheduled payments.';

  @override
  String get addCategory => 'Add category';

  @override
  String get newCategory => 'New category';

  @override
  String get renameCategory => 'Rename category';

  @override
  String get categoryName => 'Category name';

  @override
  String get categoryNameRequired => 'Enter a category name.';

  @override
  String get categoryExists => 'That category already exists.';

  @override
  String get archiveCategory => 'Archive';

  @override
  String get archiveCategoryQuestion => 'Archive category?';

  @override
  String get archiveCategoryBody =>
      'It will be hidden from pickers but kept in existing records.';

  @override
  String get archived => 'Archived';

  @override
  String get showArchived => 'Show archived';

  @override
  String get restoreCategory => 'Restore';

  @override
  String get noCategories => 'No categories yet';

  @override
  String get noCategoriesBody =>
      'Add a category to organize your transactions.';

  @override
  String get manageCategories => 'Manage categories';

  @override
  String get scheduledPayments => 'Scheduled payments';

  @override
  String get scheduledPaymentsDescription =>
      'Recurring expenses like rent, credits, subscriptions, or your phone plan.';

  @override
  String get incomeType => 'Type';

  @override
  String get incomeSchedule => 'Income schedule';

  @override
  String get expectedMonthlyIncome => 'Expected monthly income';

  @override
  String nextIncome(String date) {
    return 'Next income: $date';
  }

  @override
  String get addScheduledPayment => 'Add payment';

  @override
  String get addFirstScheduledPayment => 'Add a scheduled payment';

  @override
  String get newScheduledPayment => 'New scheduled payment';

  @override
  String get paymentName => 'Payment name';

  @override
  String get paymentNameRequired => 'Enter a payment name.';

  @override
  String get frequency => 'Frequency';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get nextDueDate => 'Next due date';

  @override
  String get payNow => 'Pay now';

  @override
  String get pausePayment => 'Pause';

  @override
  String get resumePayment => 'Resume';

  @override
  String get paused => 'Paused';

  @override
  String get dueToday => 'Due today';

  @override
  String get overdue => 'Overdue';

  @override
  String get noScheduledPayments => 'No scheduled payments';

  @override
  String get noScheduledPaymentsBody =>
      'Add rent, credits, subscriptions, or your phone plan and the expense will be recorded automatically when due.';

  @override
  String autoCreatedPayments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scheduled entries were added.',
      one: '1 scheduled entry was added.',
    );
    return '$_temp0';
  }

  @override
  String get deleteScheduledPayment => 'Delete scheduled payment';

  @override
  String get deleteScheduledPaymentQuestion => 'Delete scheduled payment?';

  @override
  String get deleteScheduledPaymentBody =>
      'The schedule is removed. Expenses already recorded are kept.';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String scheduledFor(String date) {
    return 'Next: $date';
  }

  @override
  String get paidToday => 'Paid today';

  @override
  String get quickActionsSubtitle => 'Shortcuts to what you do most.';

  @override
  String get loginFooter => 'Your data stays on your device first.';

  @override
  String get accounts => 'Accounts';

  @override
  String get settingsFooter => 'FinSight AI · Your finances, in sight.';

  @override
  String get scheduledTab => 'Scheduled';

  @override
  String get previousPeriod => 'Previous';

  @override
  String get currentPeriod => 'Current';

  @override
  String get cardLabel => 'Card';

  @override
  String get receivablesTitle => 'Owed to me';

  @override
  String get owedToMe => 'Owed to me';

  @override
  String get owedToMeBody => 'Money you lent and are waiting to get back.';

  @override
  String get addReceivable => 'Add money lent';

  @override
  String get saveReceivable => 'Save receivable';

  @override
  String get debtorName => 'Who owes you';

  @override
  String get amountLent => 'Amount lent';

  @override
  String get dateLent => 'Date lent';

  @override
  String get dueDateOptional => 'Due date (optional)';

  @override
  String get remainingAmount => 'Remaining';

  @override
  String get received => 'Received';

  @override
  String get addPayment => 'Add payment';

  @override
  String get receivableDetails => 'Receivable details';

  @override
  String get noReceivables => 'No money lent yet';

  @override
  String get noReceivablesBody =>
      'Add money you lent and track payments until it is paid back.';

  @override
  String peopleOweYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people owe you',
      one: '1 person owes you',
      zero: 'No one owes you',
    );
    return '$_temp0';
  }

  @override
  String get markPaid => 'Mark as paid';

  @override
  String get receivablePaid => 'Paid back';

  @override
  String get deleteReceivable => 'Delete receivable';

  @override
  String get deleteReceivableQuestion => 'Delete receivable?';

  @override
  String get deleteReceivableBody =>
      'This removes the receivable and its payment history.';

  @override
  String get debtorRequired => 'Enter who owes you.';

  @override
  String get invalidLentAmount => 'Enter an amount greater than zero.';

  @override
  String get paymentTooHigh => 'Payment cannot exceed the remaining amount.';

  @override
  String get noPaymentsReceived => 'No payments received yet.';

  @override
  String lentOn(String date) {
    return 'Lent on $date';
  }

  @override
  String get loadingReceivables => 'Loading receivables';

  @override
  String get updatingReceivable => 'Updating receivable';

  @override
  String get receivableNotFound => 'Receivable not found.';

  @override
  String get receivableProgress => 'Receivable repayment progress';

  @override
  String get noDueDate => 'No due date';

  @override
  String get notes => 'Notes';

  @override
  String get monthlyBudgetSummary => 'Monthly budget';

  @override
  String get spentLabel => 'Spent';

  @override
  String get limitLabel => 'Limit';

  @override
  String budgetCategoriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories',
      one: '1 category',
      zero: 'No categories',
    );
    return '$_temp0';
  }

  @override
  String get totalDebt => 'Total debt';

  @override
  String activeDebts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active debts',
      one: '1 active debt',
      zero: 'No active debts',
    );
    return '$_temp0';
  }

  @override
  String get editReceivable => 'Edit receivable';

  @override
  String get amountLockedAfterPayments =>
      'The amount cannot change after receiving payments.';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get editTransaction => 'Edit transaction';

  @override
  String get transactionDeleted => 'Transaction deleted.';

  @override
  String get undo => 'Undo';

  @override
  String get deleteTransactionQuestion => 'Delete transaction?';

  @override
  String get deleteTransactionBody =>
      'This removes the transaction from your records.';

  @override
  String get editBudget => 'Edit budget';

  @override
  String get budgetDeleted => 'Budget deleted.';

  @override
  String get deleteBudgetQuestion => 'Delete budget?';

  @override
  String get deleteBudgetBody =>
      'This removes the monthly limit for this category.';
}
