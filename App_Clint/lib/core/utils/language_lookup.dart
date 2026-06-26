import '../../features/home/domain/entities/language.dart';
import '../../features/home/domain/entities/maid.dart';

/// Display + matching helpers for worker language IDs from the Languages API.
class LanguageLookup {
  LanguageLookup._();

  /// Resolves a worker language token (id or code) to an API language name.
  static String displayName(List<Language> catalog, String workerLanguageKey) {
    final key = workerLanguageKey.trim();
    if (key.isEmpty) return key;
    final match = _findByWorkerKey(catalog, key);
    return match?.name ?? key;
  }

  /// Active languages for filter chips (id = [Language.id] as string for selection).
  static List<LanguageFilterOption> filterOptions({
    required List<Language> catalog,
    required List<Maid> maids,
    bool onlyLanguagesUsedByMaids = true,
  }) {
    final active = catalog.where((l) => l.isActive).toList();
    final options = <LanguageFilterOption>[];

    for (final lang in active) {
      final matchKeys = _matchKeysForLanguage(lang);
      if (onlyLanguagesUsedByMaids && maids.isNotEmpty) {
        final used = maids.any(
          (m) => m.languages.any(
            (token) => matchKeys.contains(token.trim()),
          ),
        );
        if (!used) continue;
      }
      options.add(
        LanguageFilterOption(
          filterId: lang.id.toString(),
          name: lang.name,
          matchKeys: matchKeys,
        ),
      );
    }

    options.sort((a, b) => a.name.compareTo(b.name));
    return options;
  }

  /// True if [maid] speaks any language selected in [selectedFilterIds].
  static bool maidMatchesLanguageFilter(
    Maid maid,
    Set<String> selectedFilterIds,
    List<Language> catalog,
  ) {
    if (selectedFilterIds.isEmpty) return true;

    final maidTokens = maid.languages.map((e) => e.trim()).where((e) => e.isNotEmpty);

    for (final filterId in selectedFilterIds) {
      final lang = _findByFilterId(catalog, filterId);
      final keys =
          lang != null
              ? _matchKeysForLanguage(lang)
              : {filterId.trim()};

      if (maidTokens.any((token) => keys.contains(token))) {
        return true;
      }
    }
    return false;
  }

  static String displayNameForFilterId(
    List<Language> catalog,
    String filterId,
  ) {
    return _findByFilterId(catalog, filterId)?.name ??
        displayName(catalog, filterId);
  }

  static Set<String> _matchKeysForLanguage(Language lang) {
    return {
      lang.id.toString(),
      if (lang.code != null && lang.code!.trim().isNotEmpty) lang.code!.trim(),
    };
  }

  static Language? _findByFilterId(List<Language> catalog, String filterId) {
    final id = int.tryParse(filterId.trim());
    if (id != null) {
      for (final lang in catalog) {
        if (lang.id == id) return lang;
      }
    }
    return _findByWorkerKey(catalog, filterId);
  }

  static Language? _findByWorkerKey(List<Language> catalog, String key) {
    final trimmed = key.trim();
    final asInt = int.tryParse(trimmed);
    if (asInt != null) {
      for (final lang in catalog) {
        if (lang.id == asInt) return lang;
      }
    }
    for (final lang in catalog) {
      if (lang.code != null && lang.code!.trim().toLowerCase() == trimmed.toLowerCase()) {
        return lang;
      }
    }
    return null;
  }
}

/// Language row in the worker filter sheet (stores API id, shows name).
class LanguageFilterOption {
  const LanguageFilterOption({
    required this.filterId,
    required this.name,
    required this.matchKeys,
  });

  final String filterId;
  final String name;
  final Set<String> matchKeys;
}
