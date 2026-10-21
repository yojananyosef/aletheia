import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Plegado manual de la barra lateral: `null` = automático según el ancho de
/// la ventana; un valor explícito (elegido con la flecha del pie del rail)
/// manda sobre el automatismo.
class SidebarCollapsed extends Notifier<bool?> {
  @override
  bool? build() => null;

  void setCollapsed(bool value) => state = value;
}

final sidebarCollapsedProvider = NotifierProvider<SidebarCollapsed, bool?>(
  SidebarCollapsed.new,
);
