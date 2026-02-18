// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mukadam Management';

  @override
  String get quickRegistration => 'Quick\nRegistration';

  @override
  String get seePlans => 'See\nPlans';

  @override
  String get transportRegistration => 'Transport\nRegistration';

  @override
  String get onBoarded => 'On\nBoarded';

  @override
  String get mukadamVerification => 'Mukadam\nVerification';

  @override
  String get transportVerification => 'Transport\nVerification';

  @override
  String get home => 'Home';

  @override
  String get dialpad => 'Dialpad';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get pageNotFound => 'Page not found';
}
