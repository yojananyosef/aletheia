import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'favorites_models.dart';
import 'favorites_persistence.dart';

/// Estado de Favoritos: pasajes, recursos y mapas guardados por el usuario.
final favoritesProvider = NotifierProvider<FavoritesController, List<Favorite>>(
  FavoritesController.new,
);

class FavoritesController extends Notifier<List<Favorite>> {
  int _seq = 0;

  @override
  List<Favorite> build() => ref.read(favoritesStoreProvider).initial;

  String _newId() => 'fav_${DateTime.now().microsecondsSinceEpoch}_${_seq++}';

  void _commit(List<Favorite> next) {
    state = next;
    ref.read(favoritesStoreProvider).save(next);
  }

  Favorite? find(FavoriteKind kind, String? reference, {String? resourceId}) {
    for (final favorite in state) {
      if (favorite.kind != kind) continue;
      if (favorite.reference != reference) continue;
      if (resourceId != null && favorite.resourceId != resourceId) continue;
      return favorite;
    }
    return null;
  }

  bool isSaved(FavoriteKind kind, String? reference, {String? resourceId}) =>
      find(kind, reference, resourceId: resourceId) != null;

  Favorite add({
    required FavoriteKind kind,
    required String title,
    String? subtitle,
    String? resourceId,
    String? reference,
  }) {
    final favorite = Favorite(
      id: _newId(),
      kind: kind,
      title: title,
      subtitle: subtitle,
      resourceId: resourceId,
      reference: reference,
      createdAt: DateTime.now(),
    );
    _commit([favorite, ...state]);
    return favorite;
  }

  void remove(String id) {
    _commit([
      for (final favorite in state)
        if (favorite.id != id) favorite,
    ]);
  }

  void removeMatching(
    FavoriteKind kind,
    String? reference, {
    String? resourceId,
  }) {
    final match = find(kind, reference, resourceId: resourceId);
    if (match != null) remove(match.id);
  }

  /// Guarda o quita un pasaje; devuelve `true` si quedó guardado.
  bool togglePassage({
    required String reference,
    required String title,
    String? subtitle,
  }) {
    final existing = find(FavoriteKind.passage, reference);
    if (existing != null) {
      remove(existing.id);
      return false;
    }
    add(
      kind: FavoriteKind.passage,
      title: title,
      subtitle: subtitle,
      reference: reference,
      resourceId: 'bible.rv1909',
    );
    return true;
  }
}
