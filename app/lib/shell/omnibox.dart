import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization.dart';
import '../core/theme.dart';
import '../references/reference_parser.dart';
import '../workspace/models.dart';
import '../workspace/workspace_controller.dart';

/// Omnibox "Passage or topic": parser de referencias + búsqueda.
///
/// Réplica funcional del original: al escribir ofrece `Ir a <referencia>`
/// (si el texto parsea como referencia bíblica) y `Buscar «…»`.
///
/// El ancho lo determina el contenedor (topbar adaptable); la omnibox se
/// estira al espacio disponible.
class Omnibox extends ConsumerStatefulWidget {
  const Omnibox({super.key, this.autofocus = false, this.onNavigated});

  /// El diálogo del rail (barra lateral colapsada) enfoca el campo al abrir.
  final bool autofocus;

  /// Se avisa tras abrir una pestaña (el diálogo del rail se cierra).
  final VoidCallback? onNavigated;

  @override
  ConsumerState<Omnibox> createState() => _OmniboxState();
}

class _OmniboxState extends ConsumerState<Omnibox> {
  TextEditingController? _fieldController;

  void _openReference(ParsedReference ref0) {
    ref
        .read(workspaceProvider.notifier)
        .openTab(
          TabSpec(
            kind: PanelKind.bible,
            title: ref0.display,
            reference: ref0.canonical,
          ),
        );
  }

  void _search(String query) {
    ref
        .read(workspaceProvider.notifier)
        .openTab(TabSpec(kind: PanelKind.search, query: query));
  }

  void _submit(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;
    final parsed = parseReference(text);
    if (parsed != null) {
      _openReference(parsed);
    } else {
      _search(text);
    }
    _fieldController?.clear();
    widget.onNavigated?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue value) {
        final text = value.text.trim();
        if (text.isEmpty) return const Iterable<String>.empty();
        final parsed = parseReference(text);
        return [if (parsed != null) 'goto:${parsed.canonical}', 'search:$text'];
      },
      displayStringForOption: (_) => '',
      onSelected: (option) {
        if (option.startsWith('goto:')) {
          final parsed = parseReference(option.substring(5));
          if (parsed != null) _openReference(parsed);
        } else if (option.startsWith('search:')) {
          _search(option.substring(7));
        }
        _fieldController?.clear();
        FocusScope.of(context).unfocus();
        widget.onNavigated?.call();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        _fieldController = controller;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: widget.autofocus,
          onSubmitted: _submit,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: context.l10n.omniboxHint,
            hintStyle: TextStyle(fontSize: 14, color: kTextSecondary),
            isDense: true,
            filled: true,
            fillColor: kPanelBg,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 9,
              horizontal: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kAccent),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            color: kPanelBg,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420, maxHeight: 300),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                children: [
                  for (final option in options)
                    ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      leading: Icon(
                        option.startsWith('goto:')
                            ? Icons.arrow_forward
                            : Icons.search,
                        size: 16,
                        color: kTextSecondary,
                      ),
                      title: Text(
                        _label(context, option),
                        style: const TextStyle(fontSize: 13),
                      ),
                      onTap: () => onSelected(option),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _label(BuildContext context, String option) {
    final l10n = context.l10n;
    if (option.startsWith('goto:')) {
      return l10n.omniboxGoto(
        displayFromCanonical(option.substring(5), lang: context.l10nLang),
      );
    }
    if (option.startsWith('search:')) {
      return l10n.omniboxSearch(option.substring(7));
    }
    return option;
  }
}
