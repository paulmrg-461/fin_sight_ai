import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';

export '../../l10n/app_localizations.dart';

/// Delegates that support every locale offered by the app.
///
/// The generated `AppLocalizations.localizationsDelegates` list pulls the
/// deprecated Material/Cupertino delegates from `flutter_localizations`, which
/// do not match the `material_ui`/`cupertino_ui` types used by Flutter 3.50+.
/// Combining our ARB delegate with `GlobalMaterialLocalizations.delegates`
/// keeps Material, Cupertino, and Widgets localizations aligned.
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ];

/// Short accessor for the generated localizations.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
