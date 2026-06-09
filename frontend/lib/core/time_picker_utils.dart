import 'package:flutter/material.dart';

Future<TimeOfDay?> showTimePicker24h(
  BuildContext context, {
  required TimeOfDay initialTime,
}) {
  return showTimePicker(
    context: context,
    initialTime: initialTime,
    builder: (ctx, child) => Localizations.override(
      context: ctx,
      delegates: const [_DeTimePickerDelegate()],
      child: MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    ),
  );
}

class _DeTimePickerDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _DeTimePickerDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      const _DeTimePicker24hLocalizations();

  @override
  bool shouldReload(covariant LocalizationsDelegate<MaterialLocalizations> old) =>
      false;
}

class _DeTimePicker24hLocalizations extends DefaultMaterialLocalizations {
  const _DeTimePicker24hLocalizations();

  @override
  String get inputTimeModeButtonLabel => 'Manuelle Eingabe';

  @override
  String get timePickerHourLabel => 'Stunde';

  @override
  String get timePickerMinuteLabel => 'Minute';

  @override
  String get timePickerDialHelpText => 'Uhrzeit wählen';

  @override
  String get timePickerInputHelpText => 'Uhrzeit eingeben';

  @override
  String get cancelButtonLabel => 'Abbrechen';

  @override
  String get okButtonLabel => 'OK';
}
