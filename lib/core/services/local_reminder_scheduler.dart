import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_scheduler.dart';

/// Local notifications for scheduled payments on Android and iOS.
///
/// Desktop, web, and tests resolve to a no-op so the app and the integration
/// suite stay deterministic.
class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'scheduled_payments';
  static const String channelName = 'Scheduled payments';
  static const String channelDescription =
      'Reminders for upcoming scheduled expenses and income';
  static const int reminderHour = 9;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<void> initialize() async {
    if (!_supported || _initialized) {
      return;
    }
    tzdata.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    try {
      final initialized = await _plugin.initialize(settings: settings);
      _initialized = initialized != false;
    } catch (_) {
      // Notifications are a convenience; never block startup on them.
    }
  }

  @override
  Future<void> scheduleFor(ScheduledPaymentReminder payment) async {
    if (!_supported) {
      return;
    }
    await initialize();
    if (!_initialized) {
      return;
    }

    final id = _notificationId(payment.id);
    try {
      await _plugin.cancel(id: id);
      if (!payment.isActive) {
        return;
      }

      final now = DateTime.now();
      final due = DateTime(
        payment.nextDueDate.year,
        payment.nextDueDate.month,
        payment.nextDueDate.day,
        reminderHour,
      );
      if (!due.isAfter(now)) {
        // Due today (or overdue): in-app processing owns the reminder.
        return;
      }

      await _requestPermission();
      await _plugin.zonedSchedule(
        id: id,
        title: payment.name,
        body: _bodyFor(payment),
        scheduledDate: tz.TZDateTime.from(due, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'scheduled_payment:${payment.id}',
      );
    } catch (_) {
      // Invalid permissions or platform errors must not affect the schedule.
    }
  }

  @override
  Future<void> cancelFor(String paymentId) async {
    if (!_supported) {
      return;
    }
    await initialize();
    if (!_initialized) {
      return;
    }
    try {
      await _plugin.cancel(id: _notificationId(paymentId));
    } catch (_) {
      // Ignore cancellation failures.
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!_supported) {
      return;
    }
    await initialize();
    if (!_initialized) {
      return;
    }
    try {
      await _plugin.cancelAll();
    } catch (_) {
      // Ignore cancellation failures.
    }
  }

  Future<void> _requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return;
    }
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  String _bodyFor(ScheduledPaymentReminder payment) {
    final spanish = PlatformDispatcher.instance.locale.languageCode == 'es';
    final category = payment.category.isEmpty ? '' : '${payment.category} · ';
    return spanish
        ? '${category}Pago programado para hoy'
        : '${category}Scheduled payment due today';
  }

  /// Stable FNV-1a hash masked to the positive 31-bit notification id range.
  int _notificationId(String id) {
    var hash = 0x811c9dc5;
    for (final code in id.codeUnits) {
      hash ^= code;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }
}
