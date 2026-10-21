import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database.dart';
import 'favorites_models.dart';

/// Persistencia de Favoritos en SQLite (`aletheia.db`, tabla `favorites`).
class FavoritesStore {
  FavoritesStore._(this._db, this.initial);

  final AletheiaDatabase? _db;
  final List<Favorite> initial;

  static FavoritesStore onDatabase(AletheiaDatabase db) =>
      FavoritesStore._(db, db.loadFavorites());

  static FavoritesStore inMemory([List<Favorite> favorites = const []]) =>
      FavoritesStore._(null, favorites);

  Future<void> save(List<Favorite> favorites) async {
    try {
      _db?.saveFavorites(favorites);
    } catch (_) {
      // Persistencia best-effort, como el resto de almacenes locales.
    }
  }
}

final favoritesStoreProvider = Provider<FavoritesStore>(
  (ref) => FavoritesStore.inMemory(),
);
