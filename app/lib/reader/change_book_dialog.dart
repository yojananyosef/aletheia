/// Diálogo "Cambiar libro" (M2): lista de Biblias del catálogo.
///
/// Usa el gateway del catálogo (`GET /v1/resources?type=bible` o los recursos
/// incluidos en la app) y devuelve el `ResourceSummary` elegido.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/catalog_gateway.dart';
import '../catalog/catalog_models.dart';
import '../core/localization.dart';
import '../core/resource_colors.dart';
import '../core/theme.dart';

class ChangeBookDialog extends ConsumerStatefulWidget {
  const ChangeBookDialog({super.key, required this.currentResourceId});

  final String currentResourceId;

  @override
  ConsumerState<ChangeBookDialog> createState() => _ChangeBookDialogState();
}

class _ChangeBookDialogState extends ConsumerState<ChangeBookDialog> {
  final _filterController = TextEditingController();
  late final Future<List<ResourceSummary>> _bibles;

  @override
  void initState() {
    super.initState();
    _bibles = ref
        .read(catalogGatewayProvider)
        .listResources(type: 'bible', pageSize: 50)
        .then((listing) => listing.items);
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  static String _subtitleFor(ResourceSummary bible, String lang) => [
    bible.typeLabelIn(lang),
    if (bible.language.isNotEmpty) languageLabel(bible.language, lang: lang),
    if (bible.licenseText.isNotEmpty) bible.licenseText,
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filter = _filterController.text.trim().toLowerCase();

    return AlertDialog(
      title: Text(
        l10n.changeBookTitle,
        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      content: SizedBox(
        width: 420,
        height: 340,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _filterController,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.libraryFind,
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 16),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<ResourceSummary>>(
                future: _bibles,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        l10n.changeBookLoadError('${snapshot.error}'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: kTextSecondary),
                      ),
                    );
                  }
                  final all = snapshot.data ?? const <ResourceSummary>[];
                  final bibles = filter.isEmpty
                      ? all
                      : all
                            .where(
                              (b) =>
                                  '${b.title} ${b.abbrev ?? ''} '
                                          '${b.authorsLabel}'
                                      .toLowerCase()
                                      .contains(filter),
                            )
                            .toList();
                  if (bibles.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.changeBookEmpty,
                        style: TextStyle(fontSize: 12.5, color: kTextSecondary),
                      ),
                    );
                  }
                  return ListView(
                    children: [
                      for (final bible in bibles)
                        ListTile(
                          dense: true,
                          leading: Container(
                            width: 34,
                            height: 44,
                            decoration: BoxDecoration(
                              color: resourceColorFor(bible.id)
                                  .withValues(alpha: 0.09),
                              border: Border.all(
                                color: resourceColorFor(bible.id)
                                    .withValues(alpha: 0.30),
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Icon(
                              Icons.menu_book_outlined,
                              size: 18,
                              color: resourceColorFor(bible.id),
                            ),
                          ),
                          title: Text(
                            bible.title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            _subtitleFor(bible, context.l10nLang),
                            style: TextStyle(
                              fontSize: 12,
                              color: kTextSecondary,
                            ),
                          ),
                          trailing: bible.id == widget.currentResourceId
                              ? const Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: kAccent,
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(bible),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
