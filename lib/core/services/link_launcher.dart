import 'package:url_launcher/url_launcher.dart';

/// Opens external links behind a testable boundary.
abstract interface class LinkLauncher {
  /// Returns `false` for invalid or unsupported URLs and platform failures.
  Future<bool> open(String url);
}

/// [LinkLauncher] backed by the platform browser.
class UrlLinkLauncher implements LinkLauncher {
  const UrlLinkLauncher({this.launchOverride});

  final Future<bool> Function(Uri, LaunchMode)? launchOverride;

  @override
  Future<bool> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return false;
    }
    try {
      final launch = launchOverride ?? launchUrl;
      return await launch(uri, LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
