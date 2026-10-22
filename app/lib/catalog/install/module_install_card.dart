/// Tarjeta «módulo no instalado» con CTA de instalación.
///
/// La comparten el Lector (recurso cuyo módulo no está instalado), la
/// Búsqueda (índice FTS5) y la Tienda: estado instalando con progreso y
/// cancelación, y [onDone] para que la vista que la pidió reintente la
/// lectura al terminar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog_source_providers.dart';
import '../../core/localization.dart';
import '../../core/theme.dart';
import 'mods_manifest.dart';
import 'modules_store.dart';

class ModuleInstallCard extends ConsumerWidget {
  const ModuleInstallCard({
    super.key,
    required this.moduleId,
    this.description,
    this.onDone,
  });

  /// Módulo instalable (`bible.kjv`, `catalog.search`, …).
  final String moduleId;

  /// Texto adicional para el usuario («en la búsqueda offline…»).
  final String? description;

  /// Se llama al terminar la instalación con éxito (la vista reintenta).
  final VoidCallback? onDone;

  ModuleEntry? _entry(CatalogModulesManifest? manifest) {
    if (manifest == null) return null;
    for (final entry in manifest.entries) {
      if (entry.id == moduleId) return entry;
    }
    return null;
  }

  static String _sizeMB(double bytes, String lang) {
    final value = (bytes / 1000000).toStringAsFixed(1);
    return '${lang == 'es' ? value.replaceAll('.', ',') : value} MB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lang = context.l10nLang;
    final store = ref.watch(modulesStoreProvider);
    final manifest = ref.watch(catalogModulesManifestProvider).value;
    final entry = _entry(manifest);

    if (store == null) {
      // Sin tienda de módulos (web): solo se explica la situación.
      return Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          description ?? l10n.moduleInstallUnavailable,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: kTextSecondary),
        ),
      );
    }

    return Container(
      key: ValueKey('module-install-$moduleId'),
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: kAccent.withValues(alpha: 0.06),
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ValueListenableBuilder<Map<String, ModuleInstallProgress>>(
        valueListenable: store.transfers,
        builder: (context, transfers, _) {
          final progress = transfers[moduleId];
          final running = progress?.phase == ModuleInstallPhase.running;
          final failed = progress?.phase == ModuleInstallPhase.error;
          final title = entry?.title ?? moduleId;
          final size = entry == null ? '' : _sizeMB(entry.size.toDouble(), lang);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (size.isNotEmpty)
                    Text(
                      l10n.moduleSize(size),
                      style: TextStyle(fontSize: 11.5, color: kTextSecondary),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                failed
                    ? l10n.moduleInstallFailed
                    : description ?? l10n.moduleAvailableBody,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.35,
                  color: kTextSecondary,
                ),
              ),
              if (running) ...[
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: progress?.fraction,
                  minHeight: 3.5,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.moduleDownloading(
                          _sizeMB((progress?.received ?? 0).toDouble(), lang),
                        ),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: kTextSecondary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.moduleCancel,
                      icon: const Icon(Icons.close, size: 15),
                      color: kTextSecondary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => store.cancel(moduleId),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonal(
                    key: ValueKey('module-install-now-$moduleId'),
                    onPressed: entry == null
                        ? null
                        : () => _install(store, entry),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(l10n.moduleInstall),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _install(ModulesStore store, ModuleEntry entry) async {
    final ok = await store.install(entry);
    if (ok) onDone?.call();
  }
}
