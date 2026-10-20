import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'assistant_models.dart';

/// Proveedor de IA conectado; `null` (por defecto) = plugin sin configurar y
/// el panel muestra el estado «sin sesión» del original. `main()` no lo
/// sustituye todavía: conectar un proveedor es una decisión del usuario.
final assistantEngineProvider = Provider<StudyAssistantEngine?>((ref) => null);

/// Estado del chat del asistente.
class AssistantChatState {
  const AssistantChatState({
    this.messages = const [],
    this.busy = false,
  });

  final List<AssistantMessage> messages;
  final bool busy;

  AssistantChatState copyWith({
    List<AssistantMessage>? messages,
    bool? busy,
  }) =>
      AssistantChatState(
        messages: messages ?? this.messages,
        busy: busy ?? this.busy,
      );
}

/// Conversación del asistente (vive mientras dure la sesión de la app, como
/// las conversaciones del original).
class AssistantChatController extends Notifier<AssistantChatState> {
  @override
  AssistantChatState build() => const AssistantChatState();

  void clear() => state = const AssistantChatState();

  Future<void> ask(String question, AssistantScope scope) async {
    final text = question.trim();
    if (text.isEmpty || state.busy) return;
    state = AssistantChatState(
      messages: [
        ...state.messages,
        AssistantMessage(role: AssistantRole.user, text: text),
      ],
      busy: true,
    );

    final engine = ref.read(assistantEngineProvider);
    if (engine == null) {
      state = state.copyWith(busy: false);
      return;
    }

    AssistantMessage reply;
    try {
      final answer = await engine.ask(question: text, scope: scope);
      reply = AssistantMessage(
        role: AssistantRole.assistant,
        text: answer.text,
        references: answer.references,
      );
    } catch (_) {
      reply = const AssistantMessage(
        role: AssistantRole.assistant,
        text: '',
        failed: true,
      );
    }
    state = AssistantChatState(messages: [...state.messages, reply]);
  }
}

final assistantChatProvider =
    NotifierProvider<AssistantChatController, AssistantChatState>(
  AssistantChatController.new,
);
