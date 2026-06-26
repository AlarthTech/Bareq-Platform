import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/notification_preferences.dart';

abstract class NotificationPreferencesLocalDataSource {
  Future<NotificationPreferences> read();

  Future<NotificationPreferences> write(NotificationPreferences preferences);
}

class NotificationPreferencesLocalDataSourceImpl
    implements NotificationPreferencesLocalDataSource {
  NotificationPreferencesLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  static const _allEnabledKey = 'notif_pref_all_enabled';
  static const _legacyBookingKey = 'notif_pref_booking_status';
  static const _legacyPromotionalKey = 'notif_pref_promotional';
  static const _legacyGeneralKey = 'notif_pref_general';

  @override
  Future<NotificationPreferences> read() async {
    if (_prefs.containsKey(_allEnabledKey)) {
      return NotificationPreferences(
        notificationsEnabled: _prefs.getBool(_allEnabledKey) ?? true,
      );
    }

    // Migrate legacy per-category keys: off only if every category was disabled.
    final booking = _prefs.getBool(_legacyBookingKey) ?? true;
    final promotional = _prefs.getBool(_legacyPromotionalKey) ?? true;
    final general = _prefs.getBool(_legacyGeneralKey) ?? true;
    final enabled = booking && promotional && general;

    final preferences = NotificationPreferences(notificationsEnabled: enabled);
    await write(preferences);
    return preferences;
  }

  @override
  Future<NotificationPreferences> write(
    NotificationPreferences preferences,
  ) async {
    await _prefs.setBool(_allEnabledKey, preferences.notificationsEnabled);
    return preferences;
  }
}
