/// Panel de Documentos (M6.4).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization.dart';
import '../core/theme.dart';
import '../workspace/models.dart';
import '../workspace/workspace_controller.dart';
import 'documents_data.dart';

class DocumentsPanel extends ConsumerStatefulWidget {
  const DocumentsPanel({super.key, required this.tile, required this.tab});

  final WorkspaceTile tile;
  final WorkspaceTab tab;

  @override
  ConsumerState<DocumentsPanel> createState() => _DocumentsPanelState();
}

class _DocumentsPanelState extends ConsumerState<DocumentsPanel> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  String? get _documentId {
    final reference = widget.tab.reference;
    return reference == null || reference.isEmpty ? null : reference;
  }

  @override
  void didUpdateWidget(covariant DocumentsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tab.reference != oldWidget.tab.reference) {
      _query = '';
      _search.clear();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openDocument(ToolDocument document) {
    ref
        .read(workspaceProvider.notifier)
        .updateTab(
          tileId: widget.tile.id,
          tabId: widget.tab.id,
          reference: document.id,
        );
  }

  void _back() {
    ref
        .read(workspaceProvider.notifier)
        .updateTab(tileId: widget.tile.id, tabId: widget.tab.id, reference: '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final documents = documentDefinitions(l10n);
    final document = _documentId == null
        ? null
        : documents.where((d) => d.id == _documentId).firstOrNull;
    return Container(
      color: kPanelBg,
      child: document == null
          ? _buildHub(documents, l10n)
          : _buildDocument(document, l10n),
    );
  }

  Widget _buildHub(List<ToolDocument> documents, AppLocalizations l10n) {
    final query = _query.trim().toLowerCase();
    final visible = [
      for (final document in documents)
        if (query.isEmpty ||
            document.title.toLowerCase().contains(query) ||
            document.subtitle.toLowerCase().contains(query) ||
            document.body.toLowerCase().contains(query))
          document,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(
            children: [
              const Icon(Icons.description_outlined, size: 18, color: kAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.panelTitleDocuments,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Text(
            l10n.documentsIntro,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: kTextSecondary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: TextField(
            key: const ValueKey('documents-search'),
            controller: _search,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: l10n.documentsSearchHint,
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 17),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: kBorder),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    l10n.documentsNoResults,
                    style: TextStyle(fontSize: 13, color: kTextSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final document = visible[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: kPanelBg,
                        border: Border.all(color: kCardBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        key: ValueKey('documents-card-${document.id}'),
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _openDocument(document),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                          child: Row(
                            children: [
                              Icon(document.icon, size: 22, color: kAccent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      document.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      document.subtitle,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        height: 1.35,
                                        color: kTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: kTextSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Text(
            l10n.documentsAttribution,
            style: TextStyle(fontSize: 10.5, color: kTextSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildDocument(ToolDocument document, AppLocalizations l10n) {
    final blocks = document.body
        .split(RegExp(r'\n\s*\n'))
        .where((block) => block.trim().isNotEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 14, 4),
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('documents-back'),
                iconSize: 18,
                tooltip: l10n.readerBack,
                onPressed: _back,
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  document.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SelectionArea(
            child: ListView(
              key: const ValueKey('documents-body'),
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
              children: [
                Text(
                  document.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: kTextSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                for (final block in blocks)
                  if (block.trimLeft().startsWith('## '))
                    Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 6),
                      child: Text(
                        block.trim().substring(3).trim(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        block.trim(),
                        style: const TextStyle(fontSize: 14, height: 1.55),
                      ),
                    ),
                const Divider(height: 28),
                Text(
                  l10n.documentsAttribution,
                  style: TextStyle(fontSize: 10.5, color: kTextSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
