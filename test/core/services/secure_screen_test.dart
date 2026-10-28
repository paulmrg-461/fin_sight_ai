import 'package:fin_sight_ai/core/services/secure_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(MethodChannelSecureScreen.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('forwards the requested state to the platform', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });

    const screen = MethodChannelSecureScreen();
    await screen.setEnabled(true);
    await screen.setEnabled(false);

    expect(calls.map((call) => call.method), ['setSecure', 'setSecure']);
    expect(calls.map((call) => call.arguments), [true, false]);
  });

  test('ignores platforms without the channel', () async {
    const screen = MethodChannelSecureScreen();

    await expectLater(screen.setEnabled(true), completes);
  });
}
