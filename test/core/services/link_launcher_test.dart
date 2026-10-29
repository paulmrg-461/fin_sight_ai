import 'package:fin_sight_ai/core/services/link_launcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  test('opens http and https links externally', () async {
    final calls = <(Uri, LaunchMode)>[];
    final launcher = UrlLinkLauncher(
      launchOverride: (uri, mode) async {
        calls.add((uri, mode));
        return true;
      },
    );

    expect(await launcher.open('https://devpaul.pro'), isTrue);
    expect(await launcher.open('http://example.com'), isTrue);
    expect(calls.map((call) => call.$1.toString()), [
      'https://devpaul.pro',
      'http://example.com',
    ]);
    expect(
      calls.every((call) => call.$2 == LaunchMode.externalApplication),
      isTrue,
    );
  });

  test('rejects unsupported or malformed URLs without launching', () async {
    var launches = 0;
    final launcher = UrlLinkLauncher(
      launchOverride: (uri, mode) async {
        launches++;
        return true;
      },
    );

    expect(await launcher.open(''), isFalse);
    expect(await launcher.open('not a url'), isFalse);
    expect(await launcher.open('mailto:hello@devpaul.pro'), isFalse);
    expect(await launcher.open('javascript:alert(1)'), isFalse);
    expect(launches, 0);
  });

  test('returns false when the platform throws or refuses', () async {
    final throwing = UrlLinkLauncher(
      launchOverride: (uri, mode) async => throw StateError('no browser'),
    );
    final refusing = UrlLinkLauncher(
      launchOverride: (uri, mode) async => false,
    );

    expect(await throwing.open('https://devpaul.pro'), isFalse);
    expect(await refusing.open('https://devpaul.pro'), isFalse);
  });
}
