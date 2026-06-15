import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const delegate = _AppLocalizationsDelegate();

  bool get _de => locale.languageCode == 'de';

  // ── General ───────────────────────────────────────────────────────────────
  String get cancel => _de ? 'Abbrechen' : 'Cancel';
  String get save => _de ? 'Speichern' : 'Save';
  String get close => _de ? 'Schließen' : 'Close';
  String get delete => _de ? 'Löschen' : 'Delete';
  String get edit => _de ? 'Bearbeiten' : 'Edit';
  String get retry => _de ? 'Erneut versuchen' : 'Retry';
  String get back => _de ? 'Zurück' : 'Back';
  String get accept => _de ? 'Annehmen' : 'Accept';
  String get decline => _de ? 'Ablehnen' : 'Decline';
  String get send => _de ? 'Senden' : 'Send';
  String get understood => _de ? 'Verstanden' : 'Got it';
  String get error => _de ? 'Fehler' : 'Error';
  String get all => _de ? 'Alle' : 'All';
  String get notice => _de ? 'Hinweis' : 'Notice';
  String get loading => _de ? 'Laden…' : 'Loading…';
  String get refresh => _de ? 'Aktualisieren' : 'Refresh';
  String get add => _de ? 'Hinzufügen' : 'Add';
  String get required_ => _de ? 'Pflichtfeld' : 'Required field';
  String get from => _de ? 'Von' : 'From';
  String get until => _de ? 'Bis' : 'Until';

  // ── Language switcher ─────────────────────────────────────────────────────
  String get langDe => '🇩🇪 Deutsch';
  String get langEn => '🇬🇧 English';

  // ── Nav bar ───────────────────────────────────────────────────────────────
  String get navMatches => _de ? 'Matches' : 'Matches';
  String get navProfile => _de ? 'Profil' : 'Profile';
  String get navSessions => _de ? 'Termine' : 'Sessions';

  // ── Login screen ──────────────────────────────────────────────────────────
  String get loginTagline1 => _de ? 'Lernen verbindet.' : 'Learning connects.';
  String get loginTagline2 => _de ? 'Erfolg entsteht.' : 'Success follows.';
  String get loginSubtitle =>
      _de ? 'Finde deinen Lernpartner.' : 'Find your study partner.';
  String get loginTitle => _de ? 'Willkommen zurück 👋' : 'Welcome back 👋';
  String get loginSubheading =>
      _de
          ? 'Logge dich ein und setze deine Lernreise fort.'
          : 'Log in and continue your learning journey.';
  String get emailLabel => _de ? 'E-Mail' : 'Email';
  String get emailValidation =>
      _de ? 'Gültige E-Mail eingeben' : 'Enter a valid email';
  String get passwordLabel => _de ? 'Passwort' : 'Password';
  String get passwordValidation =>
      _de ? 'Passwort eingeben' : 'Enter your password';
  String get rememberMe => _de ? 'Angemeldet bleiben' : 'Stay logged in';
  String get forgotPassword => _de ? 'Passwort vergessen?' : 'Forgot password?';
  String get loginButton => _de ? 'Anmelden' : 'Log in';
  String get noAccount => _de ? 'Noch kein Konto?' : 'No account yet?';
  String get registerNow => _de ? 'Jetzt Registrieren' : 'Register now';

  // ── Forgot password dialog ────────────────────────────────────────────────
  String get forgotPasswordTitle =>
      _de ? 'Passwort zurücksetzen' : 'Reset password';
  String get forgotPasswordHint =>
      _de
          ? 'Gib deine E-Mail-Adresse und ein neues Passwort ein.'
          : 'Enter your email address and a new password.';
  String get newPassword => _de ? 'Neues Passwort' : 'New password';
  String get confirmPassword =>
      _de ? 'Passwort bestätigen' : 'Confirm password';
  String get passwordMinLength =>
      _de ? 'Mindestens 8 Zeichen' : 'At least 8 characters';
  String get passwordsNoMatch =>
      _de ? 'Passwörter stimmen nicht überein' : 'Passwords do not match';
  String get resetButton => _de ? 'Zurücksetzen' : 'Reset';
  String get resetSuccess =>
      _de
          ? 'Passwort wurde zurückgesetzt. Du kannst dich jetzt einloggen.'
          : 'Password has been reset. You can now log in.';
  String get resetError =>
      _de
          ? 'Zurücksetzen fehlgeschlagen. Bitte versuche es erneut.'
          : 'Reset failed. Please try again.';

  // ── Register screen ───────────────────────────────────────────────────────
  String get registerTitle =>
      _de ? 'Konto erstellen 🎓' : 'Create account 🎓';
  String get registerSubtitle =>
      _de
          ? 'Werde Teil der StudyMatch-Community.'
          : 'Join the StudyMatch community.';
  String get aliasLabel => _de ? 'Anzeigename / Alias' : 'Display name / Alias';
  String get aliasHelper =>
      _de ? 'Wie sollen andere dich nennen?' : 'What should others call you?';
  String get aliasValidation =>
      _de ? 'Mindestens 2 Zeichen erforderlich' : 'At least 2 characters required';
  String get studiengangLabel =>
      _de ? 'Studiengang (optional)' : 'Field of study (optional)';
  String get registerButton => _de ? 'Konto erstellen' : 'Create account';
  String get alreadyRegistered => _de ? 'Bereits registriert?' : 'Already registered?';
  String get loginLink => _de ? 'Anmelden' : 'Log in';

  // ── Match list screen ─────────────────────────────────────────────────────
  String get matchesTitle => _de ? 'Matches' : 'Matches';
  String get loadingMatches => _de ? 'Lade Matches…' : 'Loading matches…';
  String get errorLoading => _de ? 'Fehler beim Laden.' : 'Error loading.';
  String get tabAccepted => _de ? 'Angenommen' : 'Accepted';
  String get tabRequests => _de ? 'Anfragen' : 'Requests';
  String get tabSuggestions => _de ? 'Vorschläge' : 'Suggestions';
  String get showAll => _de ? 'Alle anzeigen' : 'Show all';
  String matchAbove(int pct) =>
      _de ? 'Ab $pct% Match' : 'From $pct% match';
  String get adjustFilter => _de ? 'Anpassen' : 'Adjust';
  String get filterMinMatch =>
      _de ? 'Mindest-Match:' : 'Minimum match:';
  String get filterDescription =>
      _de
          ? 'Nur Personen ab diesem Wert werden angezeigt – und umgekehrt.'
          : 'Only people at or above this score are shown – and vice versa.';
  String get filterApply => _de ? 'Anwenden' : 'Apply';
  String get filterSave => _de ? 'Speichern' : 'Save';
  String get noAcceptedMatches =>
      _de ? 'Noch keine bestätigten Matches' : 'No confirmed matches yet';
  String get noAcceptedMatchesSub =>
      _de
          ? 'Schicke Anfragen an passende Lernpartner\naus dem Vorschläge-Tab.'
          : 'Send requests to matching study partners\nfrom the Suggestions tab.';
  String noMatchesAbove(int pct) =>
      _de ? 'Keine Matches ab $pct%' : 'No matches from $pct%';
  String get lowerThreshold =>
      _de ? 'Senke den Mindest-Prozentwert.' : 'Lower the minimum percentage.';
  String get noOpenRequests =>
      _de ? 'Keine offenen Anfragen' : 'No open requests';
  String get noOpenRequestsSub =>
      _de
          ? 'Wenn jemand eine Match-Anfrage\nan dich sendet, erscheint sie hier.'
          : 'When someone sends you a match request,\nit will appear here.';
  String get noSuggestions =>
      _de ? 'Keine Vorschläge gefunden' : 'No suggestions found';
  String noSuggestionsAbove(int pct) =>
      _de ? 'Keine Vorschläge ab $pct%' : 'No suggestions from $pct%';
  String get noSuggestionsSub =>
      _de
          ? 'Trage Fächer und Verfügbarkeiten in dein Profil ein.'
          : 'Add subjects and availabilities to your profile.';
  String get noSuggestionsLowerThreshold =>
      _de
          ? 'Senke den Mindest-Prozentwert oder ergänze dein Profil.'
          : 'Lower the minimum percentage or complete your profile.';
  String get lernstilHint =>
      _de
          ? 'Dein Lernstil muss im Profil angegeben sein.'
          : 'Your learning style must be set in your profile.';
  String get requestSent => _de ? 'Anfrage gesendet' : 'Request sent';
  String get scoreVeryGood => _de ? 'Sehr gutes Match' : 'Excellent match';
  String get scoreGood => _de ? 'Gutes Match' : 'Good match';
  String get scoreMedium => _de ? 'Mäßiges Match' : 'Average match';
  String get declineError => _de ? 'Fehler beim Ablehnen' : 'Error declining';
  String confirmedAlias(String alias) =>
      _de ? '$alias bestätigt!' : '$alias confirmed!';
  String get confirmError =>
      _de ? 'Fehler beim Bestätigen' : 'Error confirming';
  String get chatPolicyNotice => _de ? 'Hinweis' : 'Notice';
  String get chatPolicyText =>
      _de
          ? 'Bleib respektvoll: Beleidigungen, Diskriminierung, Bedrohungen und unangemessene Inhalte sind im Chat nicht erlaubt.'
          : 'Be respectful: Insults, discrimination, threats and inappropriate content are not allowed in chat.';
  String get showProfile => _de ? 'Profil anzeigen' : 'Show profile';
  String get openChat => _de ? 'Chat öffnen' : 'Open chat';
  String get allPercent => _de ? '0% (alle)' : '0% (all)';

  // ── Match detail screen ───────────────────────────────────────────────────
  String get matchNotFound =>
      _de ? 'Match nicht gefunden.' : 'Match not found.';
  String get commonSubjects => _de ? 'Gemeinsame Fächer' : 'Common subjects';
  String get learningStyle => _de ? 'Lernstil' : 'Learning style';
  String get commonTimeSlots =>
      _de ? 'Gemeinsame Zeitfenster' : 'Common time slots';
  String get startChat => _de ? 'Chat starten' : 'Start chat';
  String get requestSentWaiting =>
      _de
          ? 'Anfrage gesendet – warte auf Bestätigung'
          : 'Request sent – waiting for confirmation';
  String get acceptRequest => _de ? 'Anfrage annehmen' : 'Accept request';
  String get matchConfirmed => _de ? 'Match bestätigt!' : 'Match confirmed!';
  String get confirmErrorMsg =>
      _de ? 'Fehler beim Bestätigen' : 'Error confirming';
  String get sendMatchRequest =>
      _de ? 'Match-Anfrage senden' : 'Send match request';
  String get requestSentSuccess => _de ? 'Anfrage gesendet!' : 'Request sent!';
  String get requestSentError =>
      _de ? 'Fehler beim Senden' : 'Error sending';
  String get lernstilStill => _de ? 'Ruhig / Still' : 'Quiet / Still';
  String get lernstilGemischt => _de ? 'Gemischt' : 'Mixed';
  String get lernstilDiskutierend => _de ? 'Diskutierend' : 'Discussing';

  // ── Profile screen ────────────────────────────────────────────────────────
  String get myProfile => _de ? 'Mein Profil' : 'My profile';
  String get loadingProfile => _de ? 'Profil laden…' : 'Loading profile…';
  String get profileLoadError =>
      _de ? 'Profil konnte nicht geladen werden' : 'Could not load profile';
  String get lightMode => _de ? 'Heller Modus' : 'Light mode';
  String get darkMode => _de ? 'Dunkler Modus' : 'Dark mode';
  String get changePassword => _de ? 'Passwort ändern' : 'Change password';
  String get logout => _de ? 'Abmelden' : 'Log out';
  String get displayName => _de ? 'Anzeigename' : 'Display name';
  String get studiengang => _de ? 'Studiengang' : 'Field of study';
  String get lernstilLabel => _de ? 'Lernstil' : 'Learning style';
  String get bio => _de ? 'Über mich (Bio)' : 'About me (Bio)';
  String get deleteAccount => _de ? 'Account löschen' : 'Delete account';
  String get aliasMin2 =>
      _de ? 'Mindestens 2 Zeichen' : 'At least 2 characters';
  String get mySubjects => _de ? 'Meine Fächer' : 'My subjects';
  String get noSubjects =>
      _de ? 'Noch keine Fächer eingetragen.' : 'No subjects added yet.';
  String get myAvailability => _de ? 'Meine Verfügbarkeit' : 'My availability';
  String get noAvailability =>
      _de
          ? 'Noch keine Zeitfenster eingetragen.'
          : 'No time slots added yet.';
  String get addSubjectTitle => _de ? 'Fach hinzufügen' : 'Add subject';
  String subjectLimit(int count) =>
      _de ? 'max. 5 Fächer gleichzeitig ($count/5)' : 'max. 5 subjects at a time ($count/5)';
  String get subjectLimitReached =>
      _de
          ? 'Du hast bereits die maximale Anzahl an Fächern erreicht. Entferne zuerst ein Fach, um ein neues hinzuzufügen.'
          : 'You have already reached the maximum number of subjects. Remove one first to add a new one.';
  String get allSubjectsAdded =>
      _de ? 'Alle Fächer bereits hinzugefügt.' : 'All subjects already added.';
  String get addTimeSlot => _de ? 'Zeitfenster hinzufügen' : 'Add time slot';
  String get editTimeSlot => _de ? 'Zeitfenster bearbeiten' : 'Edit time slot';
  String get dayLabel => _de ? 'Wochentag' : 'Day of week';
  String get endMustBeAfterStart =>
      _de
          ? 'Endzeit muss nach Startzeit liegen'
          : 'End time must be after start time';
  String get changePasswordTitle =>
      _de ? 'Passwort ändern' : 'Change password';
  String get currentPassword => _de ? 'Aktuelles Passwort' : 'Current password';
  String get newPasswordLabel => _de ? 'Neues Passwort' : 'New password';
  String get confirmNewPassword =>
      _de ? 'Neues Passwort bestätigen' : 'Confirm new password';
  String get passwordChangedSuccess =>
      _de ? 'Passwort erfolgreich geändert' : 'Password changed successfully';
  String get deleteAccountTitle =>
      _de ? 'Account wirklich löschen?' : 'Really delete account?';
  String get deleteAccountText =>
      _de
          ? 'Dein Account wird vollständig und unwiderruflich gelöscht – '
              'einschließlich Profil, Fächer, Verfügbarkeiten, Matches und Nachrichten. '
              'Diese Aktion kann nicht rückgängig gemacht werden.'
          : 'Your account will be permanently and irreversibly deleted – '
              'including profile, subjects, availabilities, matches and messages. '
              'This action cannot be undone.';
  String get deleteAccountConfirm =>
      _de ? 'Ja, Account löschen' : 'Yes, delete account';
  String get notifications => _de ? 'Benachrichtigungen' : 'Notifications';
  String get markAllRead => _de ? 'Alle lesen' : 'Mark all read';
  String get noNotifications =>
      _de ? 'Keine Benachrichtigungen' : 'No notifications';
  String minutesAgo(int min) =>
      _de ? 'vor $min Min.' : '${min}m ago';
  String hoursAgo(int h) => _de ? 'vor $h Std.' : '${h}h ago';

  // ── Sessions screen ───────────────────────────────────────────────────────
  String get mySessions => _de ? 'Meine Termine' : 'My sessions';
  String get loadingSessions => _de ? 'Termine laden…' : 'Loading sessions…';
  String get sortUpcoming => _de ? 'Bevorstehend zuerst' : 'Upcoming first';
  String get sortPast => _de ? 'Vergangen zuerst' : 'Past first';
  String get sortRequested => _de ? 'Angefragt zuerst' : 'Requested first';
  String get showAllSessions =>
      _de ? 'Alle Termine wieder anzeigen' : 'Show all sessions';
  String get newSession => _de ? 'Neuer Termin' : 'New session';
  String get noSessions => _de ? 'Noch keine Termine' : 'No sessions yet';
  String get noSessionsSub =>
      _de
          ? 'Erstelle einen neuen Lerntermin\nmit einem deiner Matches.'
          : 'Create a new study session\nwith one of your matches.';
  String get noSessionsOnDay =>
      _de ? 'Keine Termine an diesem Tag.' : 'No sessions on this day.';
  String get groupUpcoming => _de ? 'Bevorstehend' : 'Upcoming';
  String get groupPast => _de ? 'Vergangen' : 'Past';
  String get groupRequested => _de ? 'Angefragt' : 'Requested';
  String get legendSession => _de ? 'Termin' : 'Session';
  String get legendPending => _de ? 'Änderung offen' : 'Change pending';
  String get legendCancelled => _de ? 'Abgesagt' : 'Cancelled';
  String get sessionCreated => _de ? 'Termin erstellt!' : 'Session created!';
  String sessionWithPartner(String alias) =>
      _de ? 'Termin mit $alias' : 'Session with $alias';
  String get proposeNewTime =>
      _de ? 'Neue Zeit vorschlagen' : 'Propose new time';
  String get proposeChange =>
      _de ? 'Änderung vorschlagen' : 'Propose change';
  String get changeRequest =>
      _de ? 'Änderungsanfrage' : 'Change request';
  String get changeRequestSent =>
      _de
          ? 'Änderungsanfrage gesendet – warte auf Bestätigung.'
          : 'Change request sent – waiting for confirmation.';
  String get changeRequestSentSuccess =>
      _de ? 'Änderungsanfrage gesendet!' : 'Change request sent!';
  String get changeRequestError =>
      _de ? 'Fehler beim Senden' : 'Error sending';
  String proposedDate(String date) =>
      _de ? 'Neues Datum: $date' : 'New date: $date';
  String proposedTime(String time) =>
      _de ? 'Neue Uhrzeit: $time' : 'New time: $time';
  String proposedTimeRange(String from, String to) =>
      _de ? 'Neue Uhrzeit: $from – $to Uhr' : 'New time: $from – $to';
  String get requestChange =>
      _de ? 'Änderung anfragen' : 'Request change';
  String get cancelSession => _de ? 'Termin absagen' : 'Cancel session';
  String get cancelSessionTitle =>
      _de ? 'Termin absagen' : 'Cancel session';
  String get cancelSessionConfirm =>
      _de
          ? 'Möchtest du diesen Termin wirklich absagen?'
          : 'Do you really want to cancel this session?';
  String get cancelReason => _de ? 'Grund (optional)' : 'Reason (optional)';
  String get cancelReasonHint =>
      _de ? 'z. B. Ich kann leider nicht…' : 'e.g. I unfortunately cannot…';
  String get cancelButton => _de ? 'Absagen' : 'Cancel session';
  String get sessionCancelled =>
      _de ? 'Termin abgesagt.' : 'Session cancelled.';
  String get cancelError =>
      _de ? 'Fehler beim Absagen.' : 'Error cancelling.';
  String get deleteSession => _de ? 'Termin löschen' : 'Delete session';
  String get sessionDeleted => _de ? 'Termin gelöscht.' : 'Session deleted.';
  String get deleteError => _de ? 'Fehler beim Löschen.' : 'Error deleting.';
  String get statusConfirmed => _de ? 'Bestätigt' : 'Confirmed';
  String get statusCancelled => _de ? 'Abgesagt' : 'Cancelled';
  String get statusRequested => _de ? 'Angefragt' : 'Requested';
  String get statusPlanned => _de ? 'Geplant' : 'Planned';
  String get pendingChange => _de ? 'Änderung angefragt' : 'Change requested';
  String get pendingOutgoing => _de ? 'Ausstehend' : 'Pending';
  String get sessionRequest => _de ? 'Terminanfrage' : 'Session request';
  String sessionRequestFrom(String alias) =>
      _de
          ? '$alias möchte einen Termin mit dir vereinbaren.'
          : '$alias wants to schedule a session with you.';
  String get acceptedSession =>
      _de ? 'Termin angenommen!' : 'Session accepted!';
  String get declineSessionError =>
      _de ? 'Fehler beim Ablehnen.' : 'Error declining.';
  String get acceptSessionError =>
      _de ? 'Fehler beim Annehmen.' : 'Error accepting.';
  String get newStudySession =>
      _de ? 'Neuer Lerntermin' : 'New study session';
  String get studyPartner => _de ? 'Lernpartner' : 'Study partner';
  String get choosePartner =>
      _de ? 'Partner auswählen' : 'Select partner';
  String get noMatchesForSession =>
      _de
          ? 'Keine Matches gefunden. Vervollständige zuerst dein Profil.'
          : 'No matches found. Complete your profile first.';
  String get roomOptional => _de ? 'Raum (optional)' : 'Room (optional)';
  String get noRoom => _de ? 'Kein Raum' : 'No room';
  String get createSession => _de ? 'Termin erstellen' : 'Create session';
  String get selectPartnerFirst =>
      _de
          ? 'Bitte wähle einen Lernpartner aus'
          : 'Please select a study partner';
  // Calendar strings
  String get calendarAllSessions =>
      _de ? 'Alle Termine wieder anzeigen' : 'Show all sessions';

  List<String> get calendarDayLabels => _de
      ? ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']
      : ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  List<String> get calendarMonthNames => _de
      ? ['', 'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember']
      : ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  List<String> get calendarWeekdayNames => _de
      ? ['', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag']
      : ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  List<String> get weekdayAbbrs => _de
      ? ['', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']
      : ['', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  List<String> get monthAbbrs => _de
      ? ['', 'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez']
      : ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  Map<String, String> get wochentageLabels => _de
      ? {'montag': 'Montag', 'dienstag': 'Dienstag', 'mittwoch': 'Mittwoch', 'donnerstag': 'Donnerstag', 'freitag': 'Freitag', 'samstag': 'Samstag'}
      : {'montag': 'Monday', 'dienstag': 'Tuesday', 'mittwoch': 'Wednesday', 'donnerstag': 'Thursday', 'freitag': 'Friday', 'samstag': 'Saturday'};

  // ── Chat screen ───────────────────────────────────────────────────────────
  String get chatLoading =>
      _de ? 'Nachrichten laden…' : 'Loading messages…';
  String get chatReload => _de ? 'Erneut laden' : 'Reload';
  String get noMessages =>
      _de ? 'Noch keine Nachrichten.' : 'No messages yet.';
  String get writeFirstMessage =>
      _de ? 'Schreib die erste Nachricht!' : 'Write the first message!';
  String get messageHint => _de ? 'Nachricht…' : 'Message…';
  String get backToMatches => _de ? 'Zur Matchübersicht' : 'Back to matches';
  String get proposeSession =>
      _de ? 'Termin vorschlagen' : 'Propose session';
  String get sessionProposalTitle =>
      _de ? 'Termin vorschlagen' : 'Propose session';
  String get sendRequest => _de ? 'Anfrage senden' : 'Send request';
  String get sessionRequestSent =>
      _de ? 'Terminanfrage gesendet!' : 'Session request sent!';
  String get sessionRequestError =>
      _de ? 'Fehler beim Senden' : 'Error sending';
  String sessionRequestBanner(String date, String time) =>
      _de
          ? 'Terminanfrage: $date um $time Uhr'
          : 'Session request: $date at $time';
}

// ── Delegate ──────────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'de' || locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
