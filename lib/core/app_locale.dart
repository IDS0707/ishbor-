import 'package:flutter/foundation.dart';

/// Global language selector.
///
/// Changing [appLocale.value] triggers all [ValueListenableBuilder] / [addListener]
/// consumers to rebuild with the new language.
///
/// Supported values:
///   'uz'    — O'zbekcha (lotin)
///   'uz_kr' — Ўзбекча (кирилл)
///   'ru'    — Русский
///   'en'    — English
final ValueNotifier<String> appLocale = ValueNotifier<String>('uz');
