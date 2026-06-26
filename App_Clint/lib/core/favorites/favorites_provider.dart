import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Favorites for workers (maids), persisted locally.
class FavoritesProvider extends ChangeNotifier {
  static const String _maidFavoritesKey = 'favorite_maids';
  static FavoritesProvider? _instance;
  Set<String> _favoriteMaidIds = {};

  FavoritesProvider._() {
    _loadFavorites();
  }

  static FavoritesProvider get instance {
    _instance ??= FavoritesProvider._();
    return _instance!;
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final maids = prefs.getStringList(_maidFavoritesKey);
      _favoriteMaidIds = maids?.toSet() ?? {};
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading favorites: $e');
      }
    }
  }

  Future<void> _saveMaids() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_maidFavoritesKey, _favoriteMaidIds.toList());
  }

  bool isMaidFavorited(String maidId) => _favoriteMaidIds.contains(maidId);

  Future<void> toggleMaidFavorite(String maidId) async {
    if (_favoriteMaidIds.contains(maidId)) {
      _favoriteMaidIds.remove(maidId);
    } else {
      _favoriteMaidIds.add(maidId);
    }
    await _saveMaids();
    notifyListeners();
  }

  /// Backward-compatible alias used by maid cards.
  bool isFavorited(String maidId) => isMaidFavorited(maidId);

  Future<void> toggleFavorite(String maidId) => toggleMaidFavorite(maidId);

  Set<String> get favoriteMaidIds => Set.unmodifiable(_favoriteMaidIds);

  int get favoriteCount => _favoriteMaidIds.length;
}
