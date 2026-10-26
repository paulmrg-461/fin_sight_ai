import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'FinSight AI'**
  String get appName;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @mainMenu.
  ///
  /// In en, this message translates to:
  /// **'Main menu'**
  String get mainMenu;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @openMenu.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get openMenu;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get somethingWentWrong;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createAccountTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync transactions and debts with Supabase.'**
  String get signInSubtitle;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get alreadyHaveAccount;

  /// No description provided for @signInToSync.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync'**
  String get signInToSync;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get weakPassword;

  /// No description provided for @checkEmailConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Check your email to confirm the account.'**
  String get checkEmailConfirmation;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @signOutEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign out ({email})'**
  String signOutEmail(String email);

  /// No description provided for @signOutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Sign out and erase local data?'**
  String get signOutQuestion;

  /// No description provided for @signOutEraseBody.
  ///
  /// In en, this message translates to:
  /// **'Local transactions and pending changes on this device will be deleted. Sync first if you need them.'**
  String get signOutEraseBody;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @debts.
  ///
  /// In en, this message translates to:
  /// **'Debts'**
  String get debts;

  /// No description provided for @budgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgets;

  /// No description provided for @money.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get money;

  /// No description provided for @scanReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt'**
  String get scanReceipt;

  /// No description provided for @aiCoach.
  ///
  /// In en, this message translates to:
  /// **'AI coach'**
  String get aiCoach;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get addTransaction;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @noTransactionsBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first income or expense to unlock spending insights.'**
  String get noTransactionsBody;

  /// No description provided for @addFirstTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add a transaction'**
  String get addFirstTransaction;

  /// No description provided for @changePeriod.
  ///
  /// In en, this message translates to:
  /// **'Change period'**
  String get changePeriod;

  /// No description provided for @switchToLight.
  ///
  /// In en, this message translates to:
  /// **'Switch to light mode'**
  String get switchToLight;

  /// No description provided for @switchToDark.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get switchToDark;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @savingsRate.
  ///
  /// In en, this message translates to:
  /// **'Savings rate'**
  String get savingsRate;

  /// No description provided for @spendingByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by category'**
  String get spendingByCategory;

  /// No description provided for @noExpensesPeriod.
  ///
  /// In en, this message translates to:
  /// **'No expenses in this period.'**
  String get noExpensesPeriod;

  /// No description provided for @monthlyExpenses.
  ///
  /// In en, this message translates to:
  /// **'Monthly expenses'**
  String get monthlyExpenses;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivity;

  /// No description provided for @syncOfflineNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Sync offline: Supabase is not configured'**
  String get syncOfflineNotConfigured;

  /// No description provided for @syncFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Tap to retry'**
  String get syncFailedRetry;

  /// No description provided for @syncNowPending.
  ///
  /// In en, this message translates to:
  /// **'Sync now ({count} pending)'**
  String syncNowPending(int count);

  /// No description provided for @allChangesSynced.
  ///
  /// In en, this message translates to:
  /// **'All changes synced'**
  String get allChangesSynced;

  /// No description provided for @synchronizing.
  ///
  /// In en, this message translates to:
  /// **'Synchronizing…'**
  String get synchronizing;

  /// No description provided for @newTransaction.
  ///
  /// In en, this message translates to:
  /// **'New transaction'**
  String get newTransaction;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @incomeShort.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomeShort;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @receiptPathOptional.
  ///
  /// In en, this message translates to:
  /// **'Receipt image path (optional)'**
  String get receiptPathOptional;

  /// No description provided for @saveTransaction.
  ///
  /// In en, this message translates to:
  /// **'Save transaction'**
  String get saveTransaction;

  /// No description provided for @filterByDate.
  ///
  /// In en, this message translates to:
  /// **'Filter by date'**
  String get filterByDate;

  /// No description provided for @noTransactionsInRange.
  ///
  /// In en, this message translates to:
  /// **'No transactions in this range.'**
  String get noTransactionsInRange;

  /// No description provided for @noTransactionsRangeBody.
  ///
  /// In en, this message translates to:
  /// **'Try a different date range or clear the filter.'**
  String get noTransactionsRangeBody;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearFilter;

  /// No description provided for @noTransactionsCategory.
  ///
  /// In en, this message translates to:
  /// **'No transactions in this category.'**
  String get noTransactionsCategory;

  /// No description provided for @deleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction'**
  String get deleteTransaction;

  /// No description provided for @loadingTransactions.
  ///
  /// In en, this message translates to:
  /// **'Loading transactions'**
  String get loadingTransactions;

  /// No description provided for @enterAmountGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero.'**
  String get enterAmountGreaterThanZero;

  /// No description provided for @categoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Category is required.'**
  String get categoryRequired;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @addDebt.
  ///
  /// In en, this message translates to:
  /// **'Add debt'**
  String get addDebt;

  /// No description provided for @creditorName.
  ///
  /// In en, this message translates to:
  /// **'Creditor name'**
  String get creditorName;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get totalAmount;

  /// No description provided for @annualInterestRate.
  ///
  /// In en, this message translates to:
  /// **'Annual interest rate'**
  String get annualInterestRate;

  /// No description provided for @minimumMonthlyPayment.
  ///
  /// In en, this message translates to:
  /// **'Minimum monthly payment'**
  String get minimumMonthlyPayment;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @saveDebt.
  ///
  /// In en, this message translates to:
  /// **'Save debt'**
  String get saveDebt;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get remaining;

  /// No description provided for @ofLabel.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get ofLabel;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get total;

  /// No description provided for @minimum.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get minimum;

  /// No description provided for @debtDetails.
  ///
  /// In en, this message translates to:
  /// **'Debt details'**
  String get debtDetails;

  /// No description provided for @makePayment.
  ///
  /// In en, this message translates to:
  /// **'Make a payment'**
  String get makePayment;

  /// No description provided for @paymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Payment amount'**
  String get paymentAmount;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @deleteDebt.
  ///
  /// In en, this message translates to:
  /// **'Delete debt'**
  String get deleteDebt;

  /// No description provided for @deleteDebtQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete debt?'**
  String get deleteDebtQuestion;

  /// No description provided for @deleteDebtBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the debt and its payment history.'**
  String get deleteDebtBody;

  /// No description provided for @payoffCalculator.
  ///
  /// In en, this message translates to:
  /// **'Payoff calculator'**
  String get payoffCalculator;

  /// No description provided for @monthlyPayment.
  ///
  /// In en, this message translates to:
  /// **'Monthly payment'**
  String get monthlyPayment;

  /// No description provided for @calculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculate;

  /// No description provided for @projectedPayoff.
  ///
  /// In en, this message translates to:
  /// **'Projected payoff: {date}'**
  String projectedPayoff(String date);

  /// No description provided for @paymentNotCoverInterest.
  ///
  /// In en, this message translates to:
  /// **'This payment does not cover the monthly interest.'**
  String get paymentNotCoverInterest;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get paymentHistory;

  /// No description provided for @noPaymentsYet.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded yet.'**
  String get noPaymentsYet;

  /// No description provided for @creditorRequired.
  ///
  /// In en, this message translates to:
  /// **'Creditor name is required.'**
  String get creditorRequired;

  /// No description provided for @rateRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a rate between 0 and 100.'**
  String get rateRange;

  /// No description provided for @minPaymentGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Enter a value greater than zero.'**
  String get minPaymentGreaterThanZero;

  /// No description provided for @newBudget.
  ///
  /// In en, this message translates to:
  /// **'New budget'**
  String get newBudget;

  /// No description provided for @addBudget.
  ///
  /// In en, this message translates to:
  /// **'Add budget'**
  String get addBudget;

  /// No description provided for @addAnotherBudget.
  ///
  /// In en, this message translates to:
  /// **'Add another budget'**
  String get addAnotherBudget;

  /// No description provided for @monthlyLimit.
  ///
  /// In en, this message translates to:
  /// **'Monthly limit'**
  String get monthlyLimit;

  /// No description provided for @saveBudget.
  ///
  /// In en, this message translates to:
  /// **'Save budget'**
  String get saveBudget;

  /// No description provided for @noBudgetsYet.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet'**
  String get noBudgetsYet;

  /// No description provided for @noBudgetsBody.
  ///
  /// In en, this message translates to:
  /// **'Set a monthly limit per category and track your progress.'**
  String get noBudgetsBody;

  /// No description provided for @limitGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Enter a limit greater than zero.'**
  String get limitGreaterThanZero;

  /// No description provided for @overBudgetBy.
  ///
  /// In en, this message translates to:
  /// **'Over budget by '**
  String get overBudgetBy;

  /// No description provided for @scanReceipts.
  ///
  /// In en, this message translates to:
  /// **'Scan receipts'**
  String get scanReceipts;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @noReceiptsYet.
  ///
  /// In en, this message translates to:
  /// **'No receipts yet'**
  String get noReceiptsYet;

  /// No description provided for @noReceiptsBody.
  ///
  /// In en, this message translates to:
  /// **'Scan a receipt to extract the merchant, total, and line items.'**
  String get noReceiptsBody;

  /// No description provided for @scanAReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scan a receipt'**
  String get scanAReceipt;

  /// No description provided for @loadingReceipts.
  ///
  /// In en, this message translates to:
  /// **'Loading receipts'**
  String get loadingReceipts;

  /// No description provided for @extractingData.
  ///
  /// In en, this message translates to:
  /// **'Extracting receipt data…'**
  String get extractingData;

  /// No description provided for @savingReceipt.
  ///
  /// In en, this message translates to:
  /// **'Saving receipt…'**
  String get savingReceipt;

  /// No description provided for @finishingUp.
  ///
  /// In en, this message translates to:
  /// **'Finishing up…'**
  String get finishingUp;

  /// No description provided for @receiptSavedExpenseFailed.
  ///
  /// In en, this message translates to:
  /// **'Receipt saved, but the expense could not be recorded.'**
  String get receiptSavedExpenseFailed;

  /// No description provided for @receiptPreview.
  ///
  /// In en, this message translates to:
  /// **'Receipt preview'**
  String get receiptPreview;

  /// No description provided for @merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get merchant;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @noItemsExtracted.
  ///
  /// In en, this message translates to:
  /// **'No items extracted. Add them manually if needed.'**
  String get noItemsExtracted;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get itemName;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get unitPrice;

  /// No description provided for @saveReceipt.
  ///
  /// In en, this message translates to:
  /// **'Save receipt'**
  String get saveReceipt;

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get editItem;

  /// No description provided for @removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get removeItem;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get nameRequired;

  /// No description provided for @enterValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price.'**
  String get enterValidPrice;

  /// No description provided for @totalGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero.'**
  String get totalGreaterThanZero;

  /// No description provided for @moneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get moneyTitle;

  /// No description provided for @totalAvailable.
  ///
  /// In en, this message translates to:
  /// **'Total available'**
  String get totalAvailable;

  /// No description provided for @bankPlusCash.
  ///
  /// In en, this message translates to:
  /// **'Bank account + cash'**
  String get bankPlusCash;

  /// No description provided for @bankAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get bankAccount;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @setBalance.
  ///
  /// In en, this message translates to:
  /// **'Set balance'**
  String get setBalance;

  /// No description provided for @actualBalance.
  ///
  /// In en, this message translates to:
  /// **'Actual balance'**
  String get actualBalance;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get currentBalance;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @transferMoney.
  ///
  /// In en, this message translates to:
  /// **'Transfer money'**
  String get transferMoney;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @transferBetweenWallets.
  ///
  /// In en, this message translates to:
  /// **'Transfer between wallets'**
  String get transferBetweenWallets;

  /// No description provided for @enterValidBalance.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid balance.'**
  String get enterValidBalance;

  /// No description provided for @chooseDifferentWallets.
  ///
  /// In en, this message translates to:
  /// **'Choose two different wallets.'**
  String get chooseDifferentWallets;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @currencyDescription.
  ///
  /// In en, this message translates to:
  /// **'Changing the currency updates labels and formatting. Amounts are not converted with exchange rates.'**
  String get currencyDescription;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the app language. System follows your device.'**
  String get languageDescription;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get spanish;

  /// No description provided for @yourFinancialCoach.
  ///
  /// In en, this message translates to:
  /// **'Your financial coach'**
  String get yourFinancialCoach;

  /// No description provided for @insightsDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Insights are generated from your recent activity and are not financial advice.'**
  String get insightsDisclaimer;

  /// No description provided for @analyzeSpending.
  ///
  /// In en, this message translates to:
  /// **'Analyze spending'**
  String get analyzeSpending;

  /// No description provided for @savingsTips.
  ///
  /// In en, this message translates to:
  /// **'Savings tips'**
  String get savingsTips;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @thinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking about your finances…'**
  String get thinking;

  /// No description provided for @coachReady.
  ///
  /// In en, this message translates to:
  /// **'Your coach is ready'**
  String get coachReady;

  /// No description provided for @coachReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Ask for spending analysis or personalized savings suggestions.'**
  String get coachReadyBody;

  /// No description provided for @getInsights.
  ///
  /// In en, this message translates to:
  /// **'Get insights'**
  String get getInsights;

  /// No description provided for @insightsError.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach the AI coach. Please try again.'**
  String get insightsError;

  /// No description provided for @noReceiptText.
  ///
  /// In en, this message translates to:
  /// **'No text was detected in the receipt image.'**
  String get noReceiptText;

  /// No description provided for @receiptImageError.
  ///
  /// In en, this message translates to:
  /// **'Unable to prepare the receipt image.'**
  String get receiptImageError;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(int count);

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @copCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'COP — Colombian peso'**
  String get copCurrencyLabel;

  /// No description provided for @usdCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'USD — US dollar'**
  String get usdCurrencyLabel;

  /// No description provided for @suggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get suggestion;

  /// No description provided for @alert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get alert;

  /// No description provided for @analysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysis;

  /// No description provided for @setBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Set {name} balance'**
  String setBalanceTitle(String name);

  /// No description provided for @budgetUsage.
  ///
  /// In en, this message translates to:
  /// **'Budget usage for {category}'**
  String budgetUsage(String category);

  /// No description provided for @debtPayment.
  ///
  /// In en, this message translates to:
  /// **'Debt payment'**
  String get debtPayment;

  /// No description provided for @transferAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get transferAmount;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @accountOrCash.
  ///
  /// In en, this message translates to:
  /// **'Account / cash'**
  String get accountOrCash;

  /// No description provided for @noDebtsYet.
  ///
  /// In en, this message translates to:
  /// **'No debts tracked.'**
  String get noDebtsYet;

  /// No description provided for @noDebtsBody.
  ///
  /// In en, this message translates to:
  /// **'Add a debt to track balances and project your payoff date.'**
  String get noDebtsBody;

  /// No description provided for @loadingDebts.
  ///
  /// In en, this message translates to:
  /// **'Loading debts'**
  String get loadingDebts;

  /// No description provided for @updatingDebt.
  ///
  /// In en, this message translates to:
  /// **'Updating debt'**
  String get updatingDebt;

  /// No description provided for @debtNotFound.
  ///
  /// In en, this message translates to:
  /// **'Debt not found.'**
  String get debtNotFound;

  /// No description provided for @enterValidMonthlyPayment.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid monthly payment.'**
  String get enterValidMonthlyPayment;

  /// No description provided for @debtRepaymentProgress.
  ///
  /// In en, this message translates to:
  /// **'Debt repayment progress'**
  String get debtRepaymentProgress;

  /// No description provided for @aprDue.
  ///
  /// In en, this message translates to:
  /// **'{rate}% APR • Due {date}'**
  String aprDue(String rate, String date);

  /// No description provided for @minPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Minimum {amount}/mo'**
  String minPerMonth(String amount);

  /// No description provided for @dueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueOn(String date);

  /// No description provided for @deleteBudget.
  ///
  /// In en, this message translates to:
  /// **'Delete budget'**
  String get deleteBudget;

  /// No description provided for @isoCode.
  ///
  /// In en, this message translates to:
  /// **'ISO'**
  String get isoCode;

  /// No description provided for @receiptImage.
  ///
  /// In en, this message translates to:
  /// **'Receipt image'**
  String get receiptImage;

  /// No description provided for @transactionRef.
  ///
  /// In en, this message translates to:
  /// **'Transaction {id}'**
  String transactionRef(String id);

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @categoriesDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage the categories used by transactions, budgets, and scheduled payments.'**
  String get categoriesDescription;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @renameCategory.
  ///
  /// In en, this message translates to:
  /// **'Rename category'**
  String get renameCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @categoryNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a category name.'**
  String get categoryNameRequired;

  /// No description provided for @categoryExists.
  ///
  /// In en, this message translates to:
  /// **'That category already exists.'**
  String get categoryExists;

  /// No description provided for @archiveCategory.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveCategory;

  /// No description provided for @archiveCategoryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Archive category?'**
  String get archiveCategoryQuestion;

  /// No description provided for @archiveCategoryBody.
  ///
  /// In en, this message translates to:
  /// **'It will be hidden from pickers but kept in existing records.'**
  String get archiveCategoryBody;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @showArchived.
  ///
  /// In en, this message translates to:
  /// **'Show archived'**
  String get showArchived;

  /// No description provided for @restoreCategory.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreCategory;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get noCategories;

  /// No description provided for @noCategoriesBody.
  ///
  /// In en, this message translates to:
  /// **'Add a category to organize your transactions.'**
  String get noCategoriesBody;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage categories'**
  String get manageCategories;

  /// No description provided for @scheduledPayments.
  ///
  /// In en, this message translates to:
  /// **'Scheduled payments'**
  String get scheduledPayments;

  /// No description provided for @scheduledPaymentsDescription.
  ///
  /// In en, this message translates to:
  /// **'Recurring expenses like rent, credits, subscriptions, or your phone plan.'**
  String get scheduledPaymentsDescription;

  /// No description provided for @incomeType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get incomeType;

  /// No description provided for @incomeSchedule.
  ///
  /// In en, this message translates to:
  /// **'Income schedule'**
  String get incomeSchedule;

  /// No description provided for @expectedMonthlyIncome.
  ///
  /// In en, this message translates to:
  /// **'Expected monthly income'**
  String get expectedMonthlyIncome;

  /// No description provided for @nextIncome.
  ///
  /// In en, this message translates to:
  /// **'Next income: {date}'**
  String nextIncome(String date);

  /// No description provided for @addScheduledPayment.
  ///
  /// In en, this message translates to:
  /// **'Add payment'**
  String get addScheduledPayment;

  /// No description provided for @addFirstScheduledPayment.
  ///
  /// In en, this message translates to:
  /// **'Add a scheduled payment'**
  String get addFirstScheduledPayment;

  /// No description provided for @newScheduledPayment.
  ///
  /// In en, this message translates to:
  /// **'New scheduled payment'**
  String get newScheduledPayment;

  /// No description provided for @paymentName.
  ///
  /// In en, this message translates to:
  /// **'Payment name'**
  String get paymentName;

  /// No description provided for @paymentNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a payment name.'**
  String get paymentNameRequired;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @nextDueDate.
  ///
  /// In en, this message translates to:
  /// **'Next due date'**
  String get nextDueDate;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get payNow;

  /// No description provided for @pausePayment.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pausePayment;

  /// No description provided for @resumePayment.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumePayment;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @noScheduledPayments.
  ///
  /// In en, this message translates to:
  /// **'No scheduled payments'**
  String get noScheduledPayments;

  /// No description provided for @noScheduledPaymentsBody.
  ///
  /// In en, this message translates to:
  /// **'Add rent, credits, subscriptions, or your phone plan and the expense will be recorded automatically when due.'**
  String get noScheduledPaymentsBody;

  /// No description provided for @autoCreatedPayments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 scheduled entry was added.} other{{count} scheduled entries were added.}}'**
  String autoCreatedPayments(int count);

  /// No description provided for @deleteScheduledPayment.
  ///
  /// In en, this message translates to:
  /// **'Delete scheduled payment'**
  String get deleteScheduledPayment;

  /// No description provided for @deleteScheduledPaymentQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete scheduled payment?'**
  String get deleteScheduledPaymentQuestion;

  /// No description provided for @deleteScheduledPaymentBody.
  ///
  /// In en, this message translates to:
  /// **'The schedule is removed. Expenses already recorded are kept.'**
  String get deleteScheduledPaymentBody;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @scheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String scheduledFor(String date);

  /// No description provided for @paidToday.
  ///
  /// In en, this message translates to:
  /// **'Paid today'**
  String get paidToday;

  /// No description provided for @quickActionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts to what you do most.'**
  String get quickActionsSubtitle;

  /// No description provided for @loginFooter.
  ///
  /// In en, this message translates to:
  /// **'Your data stays on your device first.'**
  String get loginFooter;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @settingsFooter.
  ///
  /// In en, this message translates to:
  /// **'FinSight AI · Your finances, in sight.'**
  String get settingsFooter;

  /// No description provided for @scheduledTab.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduledTab;

  /// No description provided for @previousPeriod.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousPeriod;

  /// No description provided for @currentPeriod.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentPeriod;

  /// No description provided for @cardLabel.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get cardLabel;

  /// No description provided for @receivablesTitle.
  ///
  /// In en, this message translates to:
  /// **'Owed to me'**
  String get receivablesTitle;

  /// No description provided for @owedToMe.
  ///
  /// In en, this message translates to:
  /// **'Owed to me'**
  String get owedToMe;

  /// No description provided for @owedToMeBody.
  ///
  /// In en, this message translates to:
  /// **'Money you lent and are waiting to get back.'**
  String get owedToMeBody;

  /// No description provided for @addReceivable.
  ///
  /// In en, this message translates to:
  /// **'Add money lent'**
  String get addReceivable;

  /// No description provided for @saveReceivable.
  ///
  /// In en, this message translates to:
  /// **'Save receivable'**
  String get saveReceivable;

  /// No description provided for @debtorName.
  ///
  /// In en, this message translates to:
  /// **'Who owes you'**
  String get debtorName;

  /// No description provided for @amountLent.
  ///
  /// In en, this message translates to:
  /// **'Amount lent'**
  String get amountLent;

  /// No description provided for @dateLent.
  ///
  /// In en, this message translates to:
  /// **'Date lent'**
  String get dateLent;

  /// No description provided for @dueDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Due date (optional)'**
  String get dueDateOptional;

  /// No description provided for @remainingAmount.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remainingAmount;

  /// No description provided for @received.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get received;

  /// No description provided for @addPayment.
  ///
  /// In en, this message translates to:
  /// **'Add payment'**
  String get addPayment;

  /// No description provided for @receivableDetails.
  ///
  /// In en, this message translates to:
  /// **'Receivable details'**
  String get receivableDetails;

  /// No description provided for @noReceivables.
  ///
  /// In en, this message translates to:
  /// **'No money lent yet'**
  String get noReceivables;

  /// No description provided for @noReceivablesBody.
  ///
  /// In en, this message translates to:
  /// **'Add money you lent and track payments until it is paid back.'**
  String get noReceivablesBody;

  /// No description provided for @peopleOweYou.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No one owes you} =1{1 person owes you} other{{count} people owe you}}'**
  String peopleOweYou(int count);

  /// No description provided for @markPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get markPaid;

  /// No description provided for @receivablePaid.
  ///
  /// In en, this message translates to:
  /// **'Paid back'**
  String get receivablePaid;

  /// No description provided for @deleteReceivable.
  ///
  /// In en, this message translates to:
  /// **'Delete receivable'**
  String get deleteReceivable;

  /// No description provided for @deleteReceivableQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete receivable?'**
  String get deleteReceivableQuestion;

  /// No description provided for @deleteReceivableBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the receivable and its payment history.'**
  String get deleteReceivableBody;

  /// No description provided for @debtorRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter who owes you.'**
  String get debtorRequired;

  /// No description provided for @invalidLentAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero.'**
  String get invalidLentAmount;

  /// No description provided for @paymentTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Payment cannot exceed the remaining amount.'**
  String get paymentTooHigh;

  /// No description provided for @noPaymentsReceived.
  ///
  /// In en, this message translates to:
  /// **'No payments received yet.'**
  String get noPaymentsReceived;

  /// No description provided for @lentOn.
  ///
  /// In en, this message translates to:
  /// **'Lent on {date}'**
  String lentOn(String date);

  /// No description provided for @loadingReceivables.
  ///
  /// In en, this message translates to:
  /// **'Loading receivables'**
  String get loadingReceivables;

  /// No description provided for @updatingReceivable.
  ///
  /// In en, this message translates to:
  /// **'Updating receivable'**
  String get updatingReceivable;

  /// No description provided for @receivableNotFound.
  ///
  /// In en, this message translates to:
  /// **'Receivable not found.'**
  String get receivableNotFound;

  /// No description provided for @receivableProgress.
  ///
  /// In en, this message translates to:
  /// **'Receivable repayment progress'**
  String get receivableProgress;

  /// No description provided for @noDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get noDueDate;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @monthlyBudgetSummary.
  ///
  /// In en, this message translates to:
  /// **'Monthly budget'**
  String get monthlyBudgetSummary;

  /// No description provided for @spentLabel.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spentLabel;

  /// No description provided for @limitLabel.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get limitLabel;

  /// No description provided for @budgetCategoriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No categories} =1{1 category} other{{count} categories}}'**
  String budgetCategoriesCount(int count);

  /// No description provided for @totalDebt.
  ///
  /// In en, this message translates to:
  /// **'Total debt'**
  String get totalDebt;

  /// No description provided for @activeDebts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No active debts} =1{1 active debt} other{{count} active debts}}'**
  String activeDebts(int count);

  /// No description provided for @editReceivable.
  ///
  /// In en, this message translates to:
  /// **'Edit receivable'**
  String get editReceivable;

  /// No description provided for @amountLockedAfterPayments.
  ///
  /// In en, this message translates to:
  /// **'The amount cannot change after receiving payments.'**
  String get amountLockedAfterPayments;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @editTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get editTransaction;

  /// No description provided for @transactionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted.'**
  String get transactionDeleted;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @deleteTransactionQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction?'**
  String get deleteTransactionQuestion;

  /// No description provided for @deleteTransactionBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the transaction from your records.'**
  String get deleteTransactionBody;

  /// No description provided for @editBudget.
  ///
  /// In en, this message translates to:
  /// **'Edit budget'**
  String get editBudget;

  /// No description provided for @budgetDeleted.
  ///
  /// In en, this message translates to:
  /// **'Budget deleted.'**
  String get budgetDeleted;

  /// No description provided for @deleteBudgetQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete budget?'**
  String get deleteBudgetQuestion;

  /// No description provided for @deleteBudgetBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the monthly limit for this category.'**
  String get deleteBudgetBody;

  /// No description provided for @committedCashflow.
  ///
  /// In en, this message translates to:
  /// **'Committed cashflow'**
  String get committedCashflow;

  /// No description provided for @committedDays30.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get committedDays30;

  /// No description provided for @committedDays90.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get committedDays90;

  /// No description provided for @committedTotal.
  ///
  /// In en, this message translates to:
  /// **'Committed total'**
  String get committedTotal;

  /// No description provided for @noCommittedPayments.
  ///
  /// In en, this message translates to:
  /// **'No commitments yet'**
  String get noCommittedPayments;

  /// No description provided for @noCommittedPaymentsBody.
  ///
  /// In en, this message translates to:
  /// **'No active schedules or debt minimums fall in this window.'**
  String get noCommittedPaymentsBody;

  /// No description provided for @debtMinimumSource.
  ///
  /// In en, this message translates to:
  /// **'Debt minimum'**
  String get debtMinimumSource;

  /// No description provided for @editScheduledPayment.
  ///
  /// In en, this message translates to:
  /// **'Edit scheduled payment'**
  String get editScheduledPayment;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
