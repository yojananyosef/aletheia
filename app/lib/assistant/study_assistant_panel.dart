/// Panel del Asistente de estudio (M6.4).
///
/// Estructura del original en la evidencia de reconocimiento
/// (estado sin sesión): icono, invitación, preguntas de ejemplo deshabilitadas,
/// aviso de IA y el bloque para iniciar sesión. El clon sustituye la sesión por
/// el **plugin de IA**: sin proveedor conectado se ve la invitación (con
/// preguntas de ejemplo deshabilitadas) y un botón que explica el plugin y
/// ofrece el Estudio guiado; con un proveedor (inyectado en
/// `assistantEngineProvider`) aparece el chat con alcance, historial de
/// preguntas, «Copiar todo» y respuestas con citas que abren el lector.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization.dart';
import '../core/theme.dart';
import '../references/reference_parser.dart';
import '../workspace/models.dart';
import '../workspace/workspace_controller.dart';
import 'assistant_controller.dart';
import 'assistant_models.dart';

class StudyAssistantPanel extends ConsumerStatefulWidget {
  const StudyAssistantPanel({super.key});

  @override
  ConsumerState<StudyAssistantPanel> createState() =>
      _StudyAssistantPanelState();
}

class _StudyAssistantPanelState extends ConsumerState<StudyAssistantPanel> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  AssistantScope _scope = AssistantScope.allBooks;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final engine = ref.watch(assistantEngineProvider);
    // Baja al final cuando llega un mensaje nuevo.
    ref.listen(assistantChatProvider, (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    });

    if (engine == null) {
      return Container(
        color: kPanelBg,
        child: _SignedOutState(onConnect: _explainPlugin),
      );
    }

    final chat = ref.watch(assistantChatProvider);
    return Container(
      color: kPanelBg,
      child: Column(
        children: [
          _toolbar(engine, chat),
          Divider(height: 1, thickness: 1, color: kBorder),
          Expanded(
            child: chat.messages.isEmpty
                ? _suggestions(large: true)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    itemCount: chat.messages.length,
                    itemBuilder: (context, index) =>
                        _message(chat.messages[index]),
                  ),
          ),
          if (chat.busy)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
              child: Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.assistantThinking,
                    style: TextStyle(fontSize: 12, color: kTextSecondary),
                  ),
                ],
              ),
            ),
          _composer(),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- barra

  Widget _toolbar(StudyAssistantEngine engine, AssistantChatState chat) {
    final l10n = context.l10n;
    final hasMessages = chat.messages.isNotEmpty;
    final questions = [
      for (final message in chat.messages)
        if (message.role == AssistantRole.user) message.text,
    ];
    return Container(
      height: 40,
      color: kPanelBg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            TextButton.icon(
              key: const ValueKey('assistant-new'),
              onPressed: hasMessages
                  ? () => ref.read(assistantChatProvider.notifier).clear()
                  : null,
              icon: const Icon(Icons.add, size: 15),
              label: Text(
                l10n.assistantNew,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            PopupMenuButton<String>(
              key: const ValueKey('assistant-recents'),
              enabled: questions.isNotEmpty,
              tooltip: l10n.assistantRecent,
              onSelected: (question) => _send(question),
              itemBuilder: (context) => [
                if (questions.isEmpty)
                  PopupMenuItem(
                    enabled: false,
                    child: Text(
                      l10n.assistantRecentEmpty,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  )
                else
                  for (final question in questions.reversed)
                    PopupMenuItem(
                      value: question,
                      child: Text(
                        question,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
              ],
              child: Row(
                children: [
                  Icon(Icons.history, size: 15, color: kTextPrimary),
                  const SizedBox(width: 6),
                  Text(
                    l10n.assistantRecent,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              key: const ValueKey('assistant-copy'),
              onPressed: hasMessages ? _copyAll : null,
              icon: const Icon(Icons.copy_all_outlined, size: 15),
              label: Text(
                l10n.assistantCopyAll,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 6),
            Center(
              child: Text(
                engine.name,
                style: TextStyle(fontSize: 11, color: kTextSecondary),
              ),
            ),
            const SizedBox(width: 10),
            PopupMenuButton<AssistantScope>(
              key: const ValueKey('assistant-scope'),
              tooltip: l10n.assistantScope,
              onSelected: (scope) => setState(() => _scope = scope),
              itemBuilder: (context) => [
                for (final scope in AssistantScope.values)
                  PopupMenuItem(
                    value: scope,
                    child: Text(
                      scope == AssistantScope.allBooks
                          ? l10n.assistantScopeAll
                          : l10n.assistantScopeBible,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
              ],
              child: Row(
                children: [
                  Icon(Icons.workspaces_outline, size: 15, color: kTextPrimary),
                  const SizedBox(width: 6),
                  Text(
                    _scope == AssistantScope.allBooks
                        ? l10n.assistantScopeAll
                        : l10n.assistantScopeBible,
                    style: const TextStyle(fontSize: 12),
                  ),
                  Icon(Icons.arrow_drop_down, size: 16, color: kTextPrimary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------- mensajes

  Widget _message(AssistantMessage message) {
    final l10n = context.l10n;
    final lang = context.l10nLang;
    final user = message.role == AssistantRole.user;
    final text = message.failed ? l10n.assistantFailed : message.text;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        decoration: BoxDecoration(
          color: user ? kAccent.withValues(alpha: 0.08) : kPanelBg,
          border: Border.all(
            color: user ? kAccent.withValues(alpha: 0.35) : kBorder,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  user ? Icons.person_outline : Icons.auto_awesome,
                  size: 13,
                  color: user ? kAccent : kTextSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  user ? l10n.assistantYou : l10n.assistantAnswerLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: user ? kAccent : kTextSecondary,
                  ),
                ),
              ],
            ),
            if (text.isNotEmpty) ...[
              const SizedBox(height: 5),
              SelectableText(
                text,
                style: const TextStyle(fontSize: 12.5, height: 1.4),
              ),
            ],
            if (message.references.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final (index, reference) in message.references.indexed)
                    OutlinedButton(
                      key: ValueKey('assistant-ref-$index'),
                      onPressed: () => ref
                          .read(workspaceProvider.notifier)
                          .openTab(
                            TabSpec(
                              kind: PanelKind.bible,
                              reference: reference,
                            ),
                          ),
                      child: Text(
                        displayFromCanonical(reference, lang: lang),
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------- preguntas

  /// Preguntas de ejemplo (las mismas cadenas que el estado sin proveedor).
  List<String> _prompts(BuildContext context) {
    final l10n = context.l10n;
    return [
      l10n.assistantPrompt1,
      l10n.assistantPrompt2,
      l10n.assistantPrompt3,
    ];
  }

  Widget _suggestions({required bool large}) {
    final l10n = context.l10n;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 26, color: kTextSecondary),
            const SizedBox(height: 12),
            Text(
              l10n.assistantChatHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: kTextSecondary),
            ),
            const SizedBox(height: 14),
            for (final (index, prompt) in _prompts(context).indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  key: ValueKey('assistant-suggest-${index + 1}'),
                  onPressed: () => _send(prompt),
                  child: Text(
                    prompt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------- composer

  Widget _composer() {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: kPanelBg,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('assistant-input'),
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: l10n.assistantInput,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: kBorder),
                    ),
                  ),
                  onSubmitted: (value) => _send(value),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: const ValueKey('assistant-send'),
                tooltip: l10n.assistantSend,
                onPressed: _input.text.trim().isEmpty
                    ? null
                    : () => _send(_input.text),
                icon: const Icon(Icons.send, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.assistantAiNotice,
            style: TextStyle(fontSize: 11, color: kTextSecondary),
          ),
        ],
      ),
    );
  }

  void _send(String question) {
    if (question.trim().isEmpty) return;
    _input.clear();
    ref.read(assistantChatProvider.notifier).ask(question, _scope);
  }

  void _copyAll() {
    final l10n = context.l10n;
    final chat = ref.read(assistantChatProvider);
    final buffer = StringBuffer();
    for (final message in chat.messages) {
      buffer.writeln(
        '${message.role == AssistantRole.user ? l10n.assistantYou : l10n.assistantAnswerLabel}: ${message.text}',
      );
      for (final reference in message.references) {
        buffer.writeln('· $reference');
      }
    }
    Clipboard.setData(ClipboardData(text: buffer.toString().trimRight()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.assistantCopied),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  Future<void> _explainPlugin() async {
    final l10n = context.l10n;
    final openGuided = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.assistantDialogTitle),
        content: SizedBox(
          width: 420,
          child: Text(
            l10n.assistantDialogBody,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.close),
          ),
          FilledButton(
            key: const ValueKey('assistant-open-guided'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.assistantDialogOpenGuided),
          ),
        ],
      ),
    );
    if (openGuided == true) {
      ref
          .read(workspaceProvider.notifier)
          .openTab(const TabSpec(kind: PanelKind.guidedStudy));
    }
  }
}

/// Estado sin proveedor conectado (equivalente al «sin sesión» del original).
class _SignedOutState extends StatelessWidget {
  const _SignedOutState({required this.onConnect});

  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(color: kBorder),
              const SizedBox(height: 22),
              Icon(Icons.auto_awesome, size: 30, color: kTextSecondary),
              const SizedBox(height: 14),
              Text(
                l10n.assistantLead,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              for (final (index, prompt) in [
                l10n.assistantPrompt1,
                l10n.assistantPrompt2,
                l10n.assistantPrompt3,
              ].indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    key: ValueKey('assistant-prompt-${index + 1}'),
                    onPressed: null,
                    child: Text(
                      prompt,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              Text(
                l10n.assistantAiNotice,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: kTextSecondary),
              ),
              const SizedBox(height: 18),
              Icon(Icons.key_outlined, size: 18, color: kTextSecondary),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('assistant-connect'),
                    onPressed: onConnect,
                    icon: const Icon(Icons.extension_outlined, size: 15),
                    label: Text(
                      l10n.assistantConnect,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                  Text(
                    l10n.assistantConnectTail,
                    style: TextStyle(fontSize: 12, color: kTextSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
