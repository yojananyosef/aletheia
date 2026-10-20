import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pestaña que ocupa toda la ventana (pantalla completa **del panel**, no del
/// sistema operativo). Es estado transitorio: no se persiste con el workspace.
class PanelFullscreen extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String tabId) => state = tabId;

  void clear() => state = null;

  void toggle(String tabId) => state = state == tabId ? null : tabId;
}

final panelFullscreenProvider =
    NotifierProvider<PanelFullscreen, String?>(PanelFullscreen.new);
