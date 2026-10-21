/// Modelo de Favoritos (M6.4).
library;

enum FavoriteKind { passage, resource, map }

class Favorite {
  const Favorite({
    required this.id,
    required this.kind,
    required this.title,
    required this.createdAt,
    this.subtitle,
    this.resourceId,
    this.reference,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) => Favorite(
    id: json['id'] as String? ?? '',
    kind: switch (json['kind'] as String?) {
      'resource' => FavoriteKind.resource,
      'map' => FavoriteKind.map,
      _ => FavoriteKind.passage,
    },
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String?,
    resourceId: json['resourceId'] as String?,
    reference: json['reference'] as String?,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );

  final String id;
  final FavoriteKind kind;
  final String title;
  final String? subtitle;
  final String? resourceId;
  final String? reference;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    if (subtitle != null) 'subtitle': subtitle,
    if (resourceId != null) 'resourceId': resourceId,
    if (reference != null) 'reference': reference,
    'createdAt': createdAt.toIso8601String(),
  };

  bool matches(FavoriteKind kind, String? reference, String? resourceId) =>
      this.kind == kind &&
      this.reference == reference &&
      (this.resourceId == null ||
          resourceId == null ||
          this.resourceId == resourceId);
}
