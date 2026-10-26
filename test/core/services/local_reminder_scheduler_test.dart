import 'package:fin_sight_ai/core/services/local_reminder_scheduler.dart';
import 'package:fin_sight_ai/core/services/reminder_scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/timezone.dart' as tz;

class MockNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class _FakeInitSettings extends Fake implements InitializationSettings {}

void main() {
  late MockNotificationsPlugin plugin;
  late LocalReminderScheduler scheduler;
  var initializeCalls = 0;
  var zonedCalls = 0;
  var cancelCalls = 0;
  var cancelAllCalls = 0;
  int? lastId;
  String? lastTitle;
  String? lastBody;
  tz.TZDateTime? lastDate;
  var failInitialize = false;

  setUpAll(() {
    registerFallbackValue(_FakeInitSettings());
    registerFallbackValue(NotificationDetails());
    registerFallbackValue(tz.TZDateTime.utc(2026));
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
  });

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    initializeCalls = 0;
    zonedCalls = 0;
    cancelCalls = 0;
    cancelAllCalls = 0;
    lastId = null;
    lastTitle = null;
    lastBody = null;
    lastDate = null;
    failInitialize = false;
    plugin = MockNotificationsPlugin();
    when(() => plugin.initialize(settings: any(named: 'settings')))
        .thenAnswer((_) async {
          initializeCalls++;
          return !failInitialize;
        });
    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((invocation) async {
      zonedCalls++;
      lastId = invocation.namedArguments[#id] as int?;
      lastTitle = invocation.namedArguments[#title] as String?;
      lastBody = invocation.namedArguments[#body] as String?;
      lastDate = invocation.namedArguments[#scheduledDate] as tz.TZDateTime?;
    });
    when(() => plugin.cancel(id: any(named: 'id')))
        .thenAnswer((invocation) async {
          cancelCalls++;
          lastId = invocation.namedArguments[#id] as int?;
        });
    when(() => plugin.cancelAll()).thenAnswer((_) async {
      cancelAllCalls++;
    });
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(null);
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(null);
    scheduler = LocalReminderScheduler(plugin: plugin);
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  ScheduledPaymentReminder reminder({
    String id = 'pay-1',
    DateTime? due,
    bool active = true,
  }) {
    return ScheduledPaymentReminder(
      id: id,
      name: 'Rent',
      category: 'Housing',
      amount: 800,
      nextDueDate: due ?? DateTime.now().add(const Duration(days: 2)),
      isActive: active,
    );
  }

  test('initializes the plugin once on Android', () async {
    await scheduler.initialize();
    await scheduler.initialize();

    expect(initializeCalls, 1);
  });

  test('schedules a future active payment at 9am', () async {
    final due = DateTime.now().add(const Duration(days: 3));

    await scheduler.scheduleFor(reminder(due: due));

    expect(zonedCalls, 1);
    expect(lastTitle, 'Rent');
    expect(lastBody, contains('Scheduled payment due today'));
    final expected = DateTime(due.year, due.month, due.day, 9);
    expect(lastDate?.millisecondsSinceEpoch, expected.millisecondsSinceEpoch);
    expect(cancelCalls, greaterThanOrEqualTo(1));
  });

  test('uses a stable id for the same payment', () async {
    await scheduler.scheduleFor(reminder(id: 'stable'));
    final first = lastId;
    await scheduler.scheduleFor(reminder(id: 'stable'));
    final second = lastId;
    await scheduler.scheduleFor(reminder(id: 'other'));

    expect(first, isNotNull);
    expect(second, first);
    expect(lastId, isNot(first));
  });

  test('does not schedule paused payments', () async {
    await scheduler.scheduleFor(reminder(active: false));

    expect(zonedCalls, 0);
    expect(cancelCalls, 1);
  });

  test('does not schedule payments due today', () async {
    await scheduler.scheduleFor(reminder(due: DateTime.now()));

    expect(zonedCalls, 0);
    expect(cancelCalls, 1);
  });

  test('cancels one or all reminders', () async {
    await scheduler.cancelFor('pay-1');
    await scheduler.cancelAll();

    expect(cancelCalls, 1);
    expect(cancelAllCalls, 1);
  });

  test('is a no-op on unsupported platforms', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;

    await scheduler.initialize();
    await scheduler.scheduleFor(reminder());
    await scheduler.cancelFor('pay-1');
    await scheduler.cancelAll();

    expect(initializeCalls, 0);
    expect(zonedCalls, 0);
    expect(cancelCalls, 0);
    expect(cancelAllCalls, 0);
  });

  test('skips scheduling when initialization fails', () async {
    failInitialize = true;

    await scheduler.scheduleFor(reminder());

    expect(initializeCalls, 1);
    expect(zonedCalls, 0);
  });
}
