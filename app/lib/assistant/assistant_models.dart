/// Asistente de estudio (M6.4): plugin opcional de IA.
///
/// El original es un chat con IA de la cuenta (`Study Assistant`, ver
/// la evidencia de reconocimiento): sin sesión muestra
/// una invitación con preguntas de ejemplo deshabilitadas, el aviso de IA y el
/// botón para iniciar sesión. El clon reproduce esa estructura y deja el motor
/// de IA detrás de [StudyAssistantEngine]: sin proveedor conectado el panel
/// enseña el estado equivalente al «sin sesión»; con uno (pruebas o una
/// integración futura) aparece el chat con citas.
library;

/// Rol de un mensaje del chat.
enum AssistantRole { user, assistant }

/// Alcance de la consulta (el original ofrece «All books»).
enum AssistantScope { allBooks, bible }

/// Un mensaje del chat.
class AssistantMessage {
  const AssistantMessage({
    required this.role,
    required this.text,
    this.references = const [],
    this.failed = false,
  });

  final AssistantRole role;
  final String text;

  /// Referencias citadas por la respuesta (tocarlas abre el lector).
  final List<String> references;

  /// La consulta falló: el panel muestra el aviso en el idioma de la interfaz.
  final bool failed;
}

/// Respuesta de un proveedor de IA.
class AssistantAnswer {
  const AssistantAnswer({required this.text, this.references = const []});

  final String text;
  final List<String> references;
}

/// Motor del asistente: cada proveedor de IA implementa esta interfaz.
///
/// El clon no trae ninguno conectado (el plugin es opcional); se inyecta con
/// `assistantEngineProvider`. Recibe la pregunta y el alcance, y devuelve texto
/// con citas de la biblioteca.
abstract class StudyAssistantEngine {
  /// Nombre visible del proveedor (se muestra en la barra del chat).
  String get name;

  Future<AssistantAnswer> ask({
    required String question,
    required AssistantScope scope,
  });
}
