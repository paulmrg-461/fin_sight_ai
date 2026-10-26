// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'FinSight AI';

  @override
  String get dashboard => 'Inicio';

  @override
  String get mainMenu => 'Menú principal';

  @override
  String get more => 'Más';

  @override
  String get preferences => 'Preferencias';

  @override
  String get openMenu => 'Abrir menú';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get retry => 'Reintentar';

  @override
  String get add => 'Añadir';

  @override
  String get settings => 'Ajustes';

  @override
  String get loading => 'Cargando…';

  @override
  String get somethingWentWrong => 'Algo salió mal.';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get email => 'Correo';

  @override
  String get password => 'Contraseña';

  @override
  String get welcomeBack => 'Bienvenido de nuevo';

  @override
  String get createAccountTitle => 'Crea tu cuenta';

  @override
  String get signInSubtitle =>
      'Inicia sesión para sincronizar transacciones y deudas con Supabase.';

  @override
  String get createAccount => 'Crear una cuenta';

  @override
  String get alreadyHaveAccount => 'Ya tengo una cuenta';

  @override
  String get signInToSync => 'Inicia sesión para sincronizar';

  @override
  String get invalidEmail => 'Introduce un correo válido.';

  @override
  String get weakPassword => 'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get checkEmailConfirmation =>
      'Revisa tu correo para confirmar la cuenta.';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String signOutEmail(String email) {
    return 'Cerrar sesión ($email)';
  }

  @override
  String get signOutQuestion => '¿Cerrar sesión y borrar los datos locales?';

  @override
  String get signOutEraseBody =>
      'Las transacciones locales y los cambios pendientes de este dispositivo se eliminarán. Sincroniza primero si los necesitas.';

  @override
  String get quickActions => 'Acciones rápidas';

  @override
  String get transactions => 'Transacciones';

  @override
  String get debts => 'Deudas';

  @override
  String get budgets => 'Presupuestos';

  @override
  String get money => 'Dinero';

  @override
  String get scanReceipt => 'Escanear recibo';

  @override
  String get aiCoach => 'Coach IA';

  @override
  String get addTransaction => 'Añadir transacción';

  @override
  String get noTransactionsYet => 'Aún no hay transacciones';

  @override
  String get noTransactionsBody =>
      'Añade tu primer ingreso o gasto para ver tus análisis.';

  @override
  String get addFirstTransaction => 'Añadir una transacción';

  @override
  String get changePeriod => 'Cambiar período';

  @override
  String get switchToLight => 'Cambiar a modo claro';

  @override
  String get switchToDark => 'Cambiar a modo oscuro';

  @override
  String get income => 'Ingresos';

  @override
  String get expenses => 'Gastos';

  @override
  String get balance => 'Balance';

  @override
  String get savingsRate => 'Tasa de ahorro';

  @override
  String get spendingByCategory => 'Gasto por categoría';

  @override
  String get noExpensesPeriod => 'No hay gastos en este período.';

  @override
  String get monthlyExpenses => 'Gastos mensuales';

  @override
  String get recentActivity => 'Actividad reciente';

  @override
  String get syncOfflineNotConfigured =>
      'Sync offline: Supabase no está configurado';

  @override
  String get syncFailedRetry => 'Falló la sincronización. Toca para reintentar';

  @override
  String syncNowPending(int count) {
    return 'Sincronizar ($count pendientes)';
  }

  @override
  String get allChangesSynced => 'Todo sincronizado';

  @override
  String get synchronizing => 'Sincronizando…';

  @override
  String get newTransaction => 'Nueva transacción';

  @override
  String get expense => 'Gasto';

  @override
  String get incomeShort => 'Ingreso';

  @override
  String get amount => 'Monto';

  @override
  String get category => 'Categoría';

  @override
  String get description => 'Descripción';

  @override
  String get date => 'Fecha';

  @override
  String get receiptPathOptional => 'Ruta de la imagen del recibo (opcional)';

  @override
  String get saveTransaction => 'Guardar transacción';

  @override
  String get filterByDate => 'Filtrar por fecha';

  @override
  String get noTransactionsInRange => 'No hay transacciones en este rango.';

  @override
  String get noTransactionsRangeBody => 'Prueba otro rango o limpia el filtro.';

  @override
  String get clearFilter => 'Limpiar';

  @override
  String get noTransactionsCategory =>
      'No hay transacciones en esta categoría.';

  @override
  String get deleteTransaction => 'Eliminar transacción';

  @override
  String get loadingTransactions => 'Cargando transacciones';

  @override
  String get enterAmountGreaterThanZero => 'Introduce un monto mayor que cero.';

  @override
  String get categoryRequired => 'La categoría es obligatoria.';

  @override
  String get sync => 'Sincronizar';

  @override
  String get addDebt => 'Añadir deuda';

  @override
  String get creditorName => 'Acreedor';

  @override
  String get totalAmount => 'Monto total';

  @override
  String get annualInterestRate => 'Tasa de interés anual';

  @override
  String get minimumMonthlyPayment => 'Pago mínimo mensual';

  @override
  String get dueDate => 'Fecha de vencimiento';

  @override
  String get saveDebt => 'Guardar deuda';

  @override
  String get active => 'Activa';

  @override
  String get paid => 'Pagada';

  @override
  String get remaining => 'pendiente';

  @override
  String get ofLabel => 'de';

  @override
  String get total => 'total';

  @override
  String get minimum => 'Mínimo';

  @override
  String get debtDetails => 'Detalle de la deuda';

  @override
  String get makePayment => 'Hacer un pago';

  @override
  String get paymentAmount => 'Monto del pago';

  @override
  String get pay => 'Pagar';

  @override
  String get deleteDebt => 'Eliminar deuda';

  @override
  String get deleteDebtQuestion => '¿Eliminar deuda?';

  @override
  String get deleteDebtBody => 'Esto elimina la deuda y su historial de pagos.';

  @override
  String get payoffCalculator => 'Calculadora de pago';

  @override
  String get monthlyPayment => 'Pago mensual';

  @override
  String get calculate => 'Calcular';

  @override
  String projectedPayoff(String date) {
    return 'Pago estimado: $date';
  }

  @override
  String get paymentNotCoverInterest =>
      'Este pago no cubre los intereses mensuales.';

  @override
  String get paymentHistory => 'Historial de pagos';

  @override
  String get noPaymentsYet => 'Aún no hay pagos registrados.';

  @override
  String get creditorRequired => 'El acreedor es obligatorio.';

  @override
  String get rateRange => 'Introduce una tasa entre 0 y 100.';

  @override
  String get minPaymentGreaterThanZero => 'Introduce un valor mayor que cero.';

  @override
  String get newBudget => 'Nuevo presupuesto';

  @override
  String get addBudget => 'Añadir presupuesto';

  @override
  String get addAnotherBudget => 'Añadir otro presupuesto';

  @override
  String get monthlyLimit => 'Límite mensual';

  @override
  String get saveBudget => 'Guardar presupuesto';

  @override
  String get noBudgetsYet => 'Aún no hay presupuestos';

  @override
  String get noBudgetsBody =>
      'Define un límite mensual por categoría y sigue tu progreso.';

  @override
  String get limitGreaterThanZero => 'Introduce un límite mayor que cero.';

  @override
  String get overBudgetBy => 'Excedido por ';

  @override
  String get scanReceipts => 'Escanear recibos';

  @override
  String get camera => 'Cámara';

  @override
  String get gallery => 'Galería';

  @override
  String get noReceiptsYet => 'Aún no hay recibos';

  @override
  String get noReceiptsBody =>
      'Escanea un recibo para extraer comercio, total y artículos.';

  @override
  String get scanAReceipt => 'Escanear un recibo';

  @override
  String get loadingReceipts => 'Cargando recibos';

  @override
  String get extractingData => 'Extrayendo datos del recibo…';

  @override
  String get savingReceipt => 'Guardando recibo…';

  @override
  String get finishingUp => 'Finalizando…';

  @override
  String get receiptSavedExpenseFailed =>
      'Recibo guardado, pero no se pudo registrar el gasto.';

  @override
  String get receiptPreview => 'Vista previa del recibo';

  @override
  String get merchant => 'Comercio';

  @override
  String get currency => 'Moneda';

  @override
  String get items => 'Artículos';

  @override
  String get addItem => 'Añadir artículo';

  @override
  String get noItemsExtracted =>
      'No se extrajeron artículos. Añádelos manualmente.';

  @override
  String get itemName => 'Nombre';

  @override
  String get quantity => 'Cantidad';

  @override
  String get unitPrice => 'Precio unitario';

  @override
  String get saveReceipt => 'Guardar recibo';

  @override
  String get editItem => 'Editar artículo';

  @override
  String get removeItem => 'Eliminar artículo';

  @override
  String get nameRequired => 'El nombre es obligatorio.';

  @override
  String get enterValidPrice => 'Introduce un precio válido.';

  @override
  String get totalGreaterThanZero => 'Introduce un monto mayor que cero.';

  @override
  String get moneyTitle => 'Dinero';

  @override
  String get totalAvailable => 'Total disponible';

  @override
  String get bankPlusCash => 'Cuenta bancaria + efectivo';

  @override
  String get bankAccount => 'Cuenta bancaria';

  @override
  String get cash => 'Efectivo';

  @override
  String get setBalance => 'Fijar saldo';

  @override
  String get actualBalance => 'Saldo actual';

  @override
  String get currentBalance => 'Saldo actual';

  @override
  String get transfer => 'Transferir';

  @override
  String get transferMoney => 'Transferir dinero';

  @override
  String get from => 'Desde';

  @override
  String get to => 'Hacia';

  @override
  String get noteOptional => 'Nota (opcional)';

  @override
  String get transferBetweenWallets => 'Transferir entre cuentas';

  @override
  String get enterValidBalance => 'Introduce un saldo válido.';

  @override
  String get chooseDifferentWallets => 'Elige dos cuentas diferentes.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get currencyDescription =>
      'Cambiar la moneda actualiza etiquetas y formato. Los montos no se convierten con tasas de cambio.';

  @override
  String get language => 'Idioma';

  @override
  String get languageDescription =>
      'Elige el idioma de la app. Sistema sigue tu dispositivo.';

  @override
  String get systemLanguage => 'Sistema';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Español';

  @override
  String get yourFinancialCoach => 'Tu coach financiero';

  @override
  String get insightsDisclaimer =>
      'Los consejos se generan a partir de tu actividad reciente y no son asesoría financiera.';

  @override
  String get analyzeSpending => 'Analizar gastos';

  @override
  String get savingsTips => 'Consejos de ahorro';

  @override
  String get refresh => 'Actualizar';

  @override
  String get thinking => 'Pensando en tus finanzas…';

  @override
  String get coachReady => 'Tu coach está listo';

  @override
  String get coachReadyBody =>
      'Pide un análisis de gastos o consejos de ahorro personalizados.';

  @override
  String get getInsights => 'Obtener consejos';

  @override
  String get insightsError =>
      'No se pudo contactar al coach IA. Inténtalo de nuevo.';

  @override
  String get noReceiptText => 'No se detectó texto en la imagen del recibo.';

  @override
  String get receiptImageError => 'No se pudo preparar la imagen del recibo.';

  @override
  String itemsCount(int count) {
    return '$count artículos';
  }

  @override
  String get viewAll => 'Ver todo';

  @override
  String get search => 'Buscar';

  @override
  String get period => 'Período';

  @override
  String get copCurrencyLabel => 'COP — Peso colombiano';

  @override
  String get usdCurrencyLabel => 'USD — Dólar estadounidense';

  @override
  String get suggestion => 'Sugerencia';

  @override
  String get alert => 'Alerta';

  @override
  String get analysis => 'Análisis';

  @override
  String setBalanceTitle(String name) {
    return 'Fijar saldo de $name';
  }

  @override
  String budgetUsage(String category) {
    return 'Uso del presupuesto de $category';
  }

  @override
  String get debtPayment => 'Pago de deuda';

  @override
  String get transferAmount => 'Monto';

  @override
  String get all => 'Todas';

  @override
  String get accountOrCash => 'Cuenta / efectivo';

  @override
  String get noDebtsYet => 'Aún no hay deudas';

  @override
  String get noDebtsBody =>
      'Añade una deuda para seguir el saldo y estimar la fecha de pago.';

  @override
  String get loadingDebts => 'Cargando deudas';

  @override
  String get updatingDebt => 'Actualizando deuda';

  @override
  String get debtNotFound => 'Deuda no encontrada.';

  @override
  String get enterValidMonthlyPayment => 'Introduce un pago mensual válido.';

  @override
  String get debtRepaymentProgress => 'Progreso de pago de la deuda';

  @override
  String aprDue(String rate, String date) {
    return '$rate% APR • Vence $date';
  }

  @override
  String minPerMonth(String amount) {
    return 'Mínimo $amount/mes';
  }

  @override
  String dueOn(String date) {
    return 'Vence $date';
  }

  @override
  String get deleteBudget => 'Eliminar presupuesto';

  @override
  String get isoCode => 'ISO';

  @override
  String get receiptImage => 'Imagen del recibo';

  @override
  String transactionRef(String id) {
    return 'Transacción $id';
  }

  @override
  String get categoriesTitle => 'Categorías';

  @override
  String get categoriesDescription =>
      'Gestiona las categorías de transacciones, presupuestos y pagos programados.';

  @override
  String get addCategory => 'Añadir categoría';

  @override
  String get newCategory => 'Nueva categoría';

  @override
  String get renameCategory => 'Renombrar categoría';

  @override
  String get categoryName => 'Nombre de la categoría';

  @override
  String get categoryNameRequired => 'Introduce un nombre de categoría.';

  @override
  String get categoryExists => 'Esa categoría ya existe.';

  @override
  String get archiveCategory => 'Archivar';

  @override
  String get archiveCategoryQuestion => '¿Archivar categoría?';

  @override
  String get archiveCategoryBody =>
      'Se ocultará de los selectores pero se conservará en los registros existentes.';

  @override
  String get archived => 'Archivada';

  @override
  String get showArchived => 'Mostrar archivadas';

  @override
  String get restoreCategory => 'Restaurar';

  @override
  String get noCategories => 'Aún no hay categorías';

  @override
  String get noCategoriesBody =>
      'Añade una categoría para organizar tus transacciones.';

  @override
  String get manageCategories => 'Gestionar categorías';

  @override
  String get scheduledPayments => 'Pagos programados';

  @override
  String get scheduledPaymentsDescription =>
      'Gastos recurrentes como arriendo, créditos, suscripciones o plan celular.';

  @override
  String get incomeType => 'Tipo';

  @override
  String get incomeSchedule => 'Ingreso programado';

  @override
  String get expectedMonthlyIncome => 'Ingreso mensual esperado';

  @override
  String nextIncome(String date) {
    return 'Próximo ingreso: $date';
  }

  @override
  String get addScheduledPayment => 'Añadir pago';

  @override
  String get addFirstScheduledPayment => 'Añadir un pago programado';

  @override
  String get newScheduledPayment => 'Nuevo pago programado';

  @override
  String get paymentName => 'Nombre del pago';

  @override
  String get paymentNameRequired => 'Introduce un nombre de pago.';

  @override
  String get frequency => 'Frecuencia';

  @override
  String get monthly => 'Mensual';

  @override
  String get yearly => 'Anual';

  @override
  String get nextDueDate => 'Próximo vencimiento';

  @override
  String get payNow => 'Pagar ahora';

  @override
  String get pausePayment => 'Pausar';

  @override
  String get resumePayment => 'Reanudar';

  @override
  String get paused => 'Pausada';

  @override
  String get dueToday => 'Vence hoy';

  @override
  String get overdue => 'Vencido';

  @override
  String get noScheduledPayments => 'Sin pagos programados';

  @override
  String get noScheduledPaymentsBody =>
      'Añade arriendo, créditos, suscripciones o plan celular y el gasto se registrará automáticamente al vencer.';

  @override
  String autoCreatedPayments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se añadieron $count movimientos programados.',
      one: 'Se añadió 1 movimiento programado.',
    );
    return '$_temp0';
  }

  @override
  String get deleteScheduledPayment => 'Eliminar pago programado';

  @override
  String get deleteScheduledPaymentQuestion => '¿Eliminar pago programado?';

  @override
  String get deleteScheduledPaymentBody =>
      'Se elimina la programación. Los gastos ya registrados se conservan.';

  @override
  String get notesOptional => 'Notas (opcional)';

  @override
  String scheduledFor(String date) {
    return 'Próximo: $date';
  }

  @override
  String get paidToday => 'Pagado hoy';

  @override
  String get quickActionsSubtitle => 'Accesos a lo que más usas.';

  @override
  String get loginFooter => 'Tus datos se guardan primero en tu dispositivo.';

  @override
  String get accounts => 'Cuentas';

  @override
  String get settingsFooter => 'FinSight AI · Tus finanzas, a la vista.';

  @override
  String get scheduledTab => 'Pagos';

  @override
  String get previousPeriod => 'Anterior';

  @override
  String get currentPeriod => 'Actual';

  @override
  String get cardLabel => 'Tarjeta';

  @override
  String get receivablesTitle => 'Me deben';

  @override
  String get owedToMe => 'Me deben';

  @override
  String get owedToMeBody => 'Dinero que prestaste y esperas recuperar.';

  @override
  String get addReceivable => 'Añadir dinero prestado';

  @override
  String get saveReceivable => 'Guardar préstamo';

  @override
  String get debtorName => 'Quién te debe';

  @override
  String get amountLent => 'Monto prestado';

  @override
  String get dateLent => 'Fecha del préstamo';

  @override
  String get dueDateOptional => 'Fecha de pago (opcional)';

  @override
  String get remainingAmount => 'Pendiente';

  @override
  String get received => 'Recibido';

  @override
  String get addPayment => 'Abonar';

  @override
  String get receivableDetails => 'Detalle del préstamo';

  @override
  String get noReceivables => 'Aún no has prestado dinero';

  @override
  String get noReceivablesBody =>
      'Añade el dinero que prestaste y sigue los abonos hasta recuperarlo.';

  @override
  String peopleOweYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas te deben',
      one: '1 persona te debe',
      zero: 'Nadie te debe',
    );
    return '$_temp0';
  }

  @override
  String get markPaid => 'Marcar como pagado';

  @override
  String get receivablePaid => 'Pagado';

  @override
  String get deleteReceivable => 'Eliminar préstamo';

  @override
  String get deleteReceivableQuestion => '¿Eliminar préstamo?';

  @override
  String get deleteReceivableBody =>
      'Esto elimina el préstamo y su historial de abonos.';

  @override
  String get debtorRequired => 'Indica quién te debe.';

  @override
  String get invalidLentAmount => 'Introduce un monto mayor que cero.';

  @override
  String get paymentTooHigh => 'El abono no puede superar el monto pendiente.';

  @override
  String get noPaymentsReceived => 'Aún no has recibido abonos.';

  @override
  String lentOn(String date) {
    return 'Prestado el $date';
  }

  @override
  String get loadingReceivables => 'Cargando préstamos';

  @override
  String get updatingReceivable => 'Actualizando préstamo';

  @override
  String get receivableNotFound => 'Préstamo no encontrado.';

  @override
  String get receivableProgress => 'Progreso de pago del préstamo';

  @override
  String get noDueDate => 'Sin fecha de pago';

  @override
  String get notes => 'Notas';

  @override
  String get monthlyBudgetSummary => 'Presupuesto mensual';

  @override
  String get spentLabel => 'Gastado';

  @override
  String get limitLabel => 'Límite';

  @override
  String budgetCategoriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categorías',
      one: '1 categoría',
      zero: 'Sin categorías',
    );
    return '$_temp0';
  }

  @override
  String get totalDebt => 'Deuda total';

  @override
  String activeDebts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count deudas activas',
      one: '1 deuda activa',
      zero: 'Sin deudas activas',
    );
    return '$_temp0';
  }

  @override
  String get editReceivable => 'Editar cuenta por cobrar';

  @override
  String get amountLockedAfterPayments =>
      'El monto no se puede cambiar después de recibir abonos.';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get editTransaction => 'Editar transacción';

  @override
  String get transactionDeleted => 'Transacción eliminada.';

  @override
  String get undo => 'Deshacer';

  @override
  String get deleteTransactionQuestion => '¿Eliminar transacción?';

  @override
  String get deleteTransactionBody =>
      'Esto elimina la transacción de tus registros.';

  @override
  String get editBudget => 'Editar presupuesto';

  @override
  String get budgetDeleted => 'Presupuesto eliminado.';

  @override
  String get deleteBudgetQuestion => '¿Eliminar presupuesto?';

  @override
  String get deleteBudgetBody =>
      'Esto elimina el límite mensual de esta categoría.';

  @override
  String get committedCashflow => 'Flujo comprometido';

  @override
  String get committedDays30 => '30 días';

  @override
  String get committedDays90 => '90 días';

  @override
  String get committedTotal => 'Total comprometido';

  @override
  String get noCommittedPayments => 'Sin compromisos aún';

  @override
  String get noCommittedPaymentsBody =>
      'No hay pagos programados ni mínimos de deuda en este periodo.';

  @override
  String get debtMinimumSource => 'Mínimo de deuda';

  @override
  String get editScheduledPayment => 'Editar pago programado';

  @override
  String get searchTransactions => 'Buscar transacciones';

  @override
  String get noMatchingTransactions => 'Sin transacciones coincidentes';

  @override
  String get noMatchingTransactionsBody =>
      'Prueba con otra descripción, categoría o monto.';

  @override
  String get clearSearch => 'Limpiar búsqueda';
}
