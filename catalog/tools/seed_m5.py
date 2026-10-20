#!/usr/bin/env python3
"""Genera los recursos de M5: devocional diario y Factbook.

- `devotional.daily`: 366 secciones fechadas (`dayofyear.MM.DD`), con una
  lectura rotativa de 30 reflexiones propias y el texto del versículo tomado
  de la RV1909 (dominio público).
- `factbook.core`: artículos propios de temas bíblicos (resumen, etiquetas,
  temas relacionados y referencias) con el mismo formato de bloques que el
  lector.

Las secciones van **embebidas** en `sections.json` (no hay un archivo por
sección): son recursos pequeños y así el panel resuelve el día o el tema con
una sola petición. El servidor y los assets de la app comparten el formato.

Uso:  python3 catalog/tools/seed_m5.py
"""
from __future__ import annotations

import json
import shutil
from datetime import date, timedelta
from pathlib import Path

from build_catalog import build_index

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "catalog" / "data"
ASSETS = ROOT / "app" / "assets" / "catalog"

MONTHS = [
    "enero", "febrero", "marzo", "abril", "mayo", "junio",
    "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre",
]


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )


# ------------------------------------------------------------------ devocional

# 30 lecturas propias; se rotan a lo largo del año. Cada una tiene su
# referencia para que el versículo acompañe al tema.
READINGS = [
    (
        "La fidelidad de Dios",
        "LAM.3.22",
        [
            "Las misericordias del Señor se renuevan cada mañana. Lo que ayer parecía perdido puede recibir hoy un comienzo distinto, porque su fidelidad no depende de nuestro ánimo ni de nuestras fuerzas.",
            "Detente un momento a recordar una ocasión en la que Dios sostuvo tu camino. La memoria del cuidado recibido alimenta la confianza para el día que empieza.",
        ],
    ),
    (
        "Un refugio seguro",
        "PSA.46.1",
        [
            "Cuando todo alrededor se mueve, Dios sigue siendo un lugar al que podemos volver. No promete una vida sin temblores, pero sí una presencia firme en medio de ellos.",
            "Busca hoy un espacio de silencio para poner delante de él lo que te inquieta. Nombrar la preocupación es el primer paso para soltarla.",
        ],
    ),
    (
        "La paz que sobrepasa",
        "PHP.4.7",
        [
            "La paz de Dios no es la ausencia de problemas, sino una calma que convive con ellos. Llega cuando dejamos de intentar controlarlo todo y confiamos el resultado a sus manos.",
            "Antes de responder al próximo mensaje o tomar la próxima decisión, respira y recuerda que no estás solo en esa tarea.",
        ],
    ),
    (
        "Caminar por fe",
        "2CO.5.7",
        [
            "No siempre veremos el final del camino antes de dar el primer paso. La fe no elimina las preguntas; nos enseña a caminar con ellas sin perder de vista a quien nos guía.",
            "Pregúntate qué pequeño paso puedes dar hoy aunque no tengas todas las respuestas. La obediencia suele crecer de a poco.",
        ],
    ),
    (
        "El cuidado del Pastor",
        "PSA.23.1",
        [
            "Ser guiado por el buen Pastor significa que el camino no se recorre en soledad. Él conoce los pastos, las sombras y las subidas, y no abandona a su rebaño en la mitad de la travesía.",
            "Agradece hoy un cuidado concreto que hayas recibido y piensa cómo puedes ofrecer ese mismo cuidado a alguien más.",
        ],
    ),
    (
        "Perdón y libertad",
        "1JN.1.9",
        [
            "El perdón de Dios no es una recompensa por portarnos bien, sino un regalo que nos libera para empezar de nuevo. Confesar no es informar a Dios de algo que ignore, sino abrirle la puerta a lo que ya conoce.",
            "Si hay algo que te pesa, ponlo en palabras delante de él y recibe la libertad que ofrece. Luego extiende ese mismo gesto a quien te haya ofendido.",
        ],
    ),
    (
        "La alegría de servir",
        "MRK.10.45",
        [
            "Jesús mostró que la grandeza se mide por el servicio. Servir no es perder valor, sino descubrir que nuestra vida se ensancha cuando deja de girar alrededor de nosotros mismos.",
            "Busca hoy una manera sencilla de aliviar la carga de otra persona, sin esperar reconocimiento.",
        ],
    ),
    (
        "Esperanza en la espera",
        "ISA.40.31",
        [
            "Esperar no es quedarse quieto: es renovar la confianza una y otra vez mientras el tiempo pasa. Dios trabaja también en los silencios y en los días que parecen no traer novedades.",
            "Si hoy te toca esperar, entrega ese tiempo a Dios y pídele fuerzas para no endurecer el corazón.",
        ],
    ),
    (
        "La fuerza en la debilidad",
        "2CO.12.9",
        [
            "Reconocer nuestros límites no nos aleja de Dios; nos acerca a su gracia. A veces es en la fragilidad donde mejor se ve que la fuerza que nos sostiene viene de él.",
            "No escondas hoy tu cansancio detrás de una sonrisa. Compártelo con Dios y con alguien de confianza.",
        ],
    ),
    (
        "Un corazón agradecido",
        "1TH.5.18",
        [
            "La gratitud cambia la manera de mirar el día. No niega lo difícil, pero impide que lo difícil ocupe toda la escena.",
            "Anota tres cosas pequeñas por las que puedes dar gracias hoy. Hazlo antes de que termine el día.",
        ],
    ),
    (
        "La luz en la oscuridad",
        "JHN.8.12",
        [
            "La luz de Cristo no borra de golpe todas las sombras, pero nos permite dar el siguiente paso sin tropezar. Donde él está, siempre hay una dirección hacia la vida.",
            "Si algo te parece hoy demasiado oscuro, pide luz para el tramo que tienes delante, no para todo el camino.",
        ],
    ),
    (
        "Amor que transforma",
        "1CO.13.4",
        [
            "El amor bíblico es paciente antes que sentimental; se nota en la forma de escuchar, de esperar y de hablar. No busca ganar la discusión, sino cuidar el vínculo.",
            "Elige hoy una relación concreta y practica una sola cosa: escuchar sin interrumpir.",
        ],
    ),
    (
        "La sabiduría del silencio",
        "PRO.10.19",
        [
            "No toda palabra dicha a tiempo es necesaria. El silencio prudente deja espacio para escuchar, para pensar y para que otros también se expresen.",
            "Antes de opinar sobre algo que no te corresponde, prueba a guardar silencio y observar.",
        ],
    ),
    (
        "Guerra contra la ansiedad",
        "MAT.6.34",
        [
            "La ansiedad suele vivir en el mañana: imagina escenas que todavía no ocurrieron y las sufre como si ya fueran reales. Jesús nos invita a habitar el día de hoy con sus fuerzas disponibles.",
            "Cuando la mente se adelante, vuelve a lo que tienes delante y haz la próxima cosa pequeña que te toca.",
        ],
    ),
    (
        "El valor de la humildad",
        "PHP.2.3",
        [
            "La humildad no es pensar poco de uno mismo, sino pensar menos en uno mismo. Es la disposición a reconocer el valor del otro y a aprender de quien tenemos al lado.",
            "Pide hoy perdón por una actitud o agradece un consejo que normalmente pasarías por alto.",
        ],
    ),
    (
        "Perseverar con gozo",
        "JAS.1.2",
        [
            "Las pruebas no son buenas en sí mismas, pero Dios puede producir algo bueno a través de ellas. La perseverancia se forma en los días en que seguimos adelante sin aplausos.",
            "Mira una dificultad actual y pregúntate qué puede estar enseñándote, sin negar el dolor que causa.",
        ],
    ),
    (
        "La comunión de los santos",
        "HEB.10.24",
        [
            "La fe se sostiene también en compañía. Animarnos unos a otros no es un extra opcional, sino parte del camino que Dios nos dio.",
            "Escribe hoy a alguien que necesite ánimo, aunque no sepas exactamente qué decir.",
        ],
    ),
    (
        "El poder de la oración",
        "JAS.5.16",
        [
            "Orar es mantener abierta la conversación con Dios, no un discurso perfecto. La oración sincera reconoce lo que hay y confía en que él escucha.",
            "Dedica unos minutos a orar por una persona concreta, sin apuro y sin distracciones.",
        ],
    ),
    (
        "Renovados cada mañana",
        "EZK.36.26",
        [
            "Dios no se conforma con retocar lo que estamos acostumbrados a mostrar; ofrece un corazón nuevo. Esa promesa nos invita a no resignarnos a ser siempre los mismos.",
            "Pide hoy un cambio concreto en tu manera de tratar a alguien, y da el primer paso.",
        ],
    ),
    (
        "El buen combate",
        "1TI.6.12",
        [
            "La vida cristiana requiere decisiones valientes, pero no se gana con fuerza propia. Se sostiene con la fe que se renueva cada día y con la conciencia de aquello por lo que vale la pena luchar.",
            "Identifica hoy una convicción que estés tentado a abandonar por comodidad y sosténla con humildad.",
        ],
    ),
    (
        "La generosidad",
        "2CO.9.7",
        [
            "Dar con alegría es un acto de confianza: reconoce que lo que tenemos no es solo para nosotros. La generosidad no depende del monto, sino de la disposición del corazón.",
            "Comparte hoy algo que tengas: tiempo, atención, un recurso o una palabra.",
        ],
    ),
    (
        "El ejemplo de Jesús",
        "JHN.13.15",
        [
            "Jesús no solo enseñó el camino: lo recorrió primero. Su ejemplo nos invita a servir desde el lugar que ocupamos, sin esperar a tener el escenario perfecto.",
            "Piensa en una tarea que sueles evitar por considerarla inferior, y hazla hoy con la misma dignidad que las demás.",
        ],
    ),
    (
        "Descanso verdadero",
        "MAT.11.28",
        [
            "El descanso que Jesús ofrece no es una pausa para luego volver al mismo agotamiento. Es un reordenamiento del corazón que aprende a dejar de cargar lo que no le corresponde.",
            "Elige hoy una carga que puedas soltar y entrega a Dios lo que no está en tus manos.",
        ],
    ),
    (
        "Palabras que sanan",
        "PRO.12.18",
        [
            "Una palabra puede abrir una herida o cerrarla. La lengua sana cuando dice la verdad con amor, cuando no aprovecha la debilidad del otro para ganar ventaja.",
            "Revisa hoy una conversación difícil y pregúntate si tus palabras construyen o solo desahogan.",
        ],
    ),
    (
        "La promesa del consuelo",
        "JHN.14.26",
        [
            "No estamos solos frente a lo que no entendemos. El Espíritu consuela, recuerda y orienta, a veces sin que podamos explicar del todo cómo lo hace.",
            "Haz una pausa para pedir consuelo si hoy lo necesitas, y también para estar disponible para consolar a otro.",
        ],
    ),
    (
        "Firmes en la tormenta",
        "MAT.7.24",
        [
            "La casa firme no se construye el día de la tormenta, sino en las decisiones pequeñas de cada día. Escuchar y practicar la Palabra nos da raíces cuando el viento sopla.",
            "Pon en práctica hoy algo que ya sabes que corresponde hacer, aunque parezca pequeño.",
        ],
    ),
    (
        "El regalo de hoy",
        "PSA.118.24",
        [
            "Cada día es una oportunidad que no estaba garantizada. Recibirlo como regalo cambia la forma de habitarlo: no como una carrera por completarlo, sino como un tiempo para estar presentes.",
            "Detente a mirar algo bello que hoy tienes cerca y agradécelo.",
        ],
    ),
    (
        "Amar al prójimo",
        "LUK.10.27",
        [
            "Amar al prójimo comienza por notar quién está cerca. No se trata de un sentimiento abstracto, sino de acciones concretas hacia personas concretas, incluso cuando no las elegimos.",
            "Pregúntate hoy quién es tu prójimo más inmediato y qué necesita de ti.",
        ],
    ),
    (
        "La justicia y la misericordia",
        "MIC.6.8",
        [
            "Dios no pide gestos espectaculares, sino una vida coherente: actuar con justicia, amar la misericordia y caminar con humildad. Esas tres cosas se entrelazan y se notan en lo cotidiano.",
            "Revisa hoy una situación donde puedas ser justo y, al mismo tiempo, compasivo.",
        ],
    ),
    (
        "Mirar hacia arriba",
        "COL.3.2",
        [
            "Lo que ocupa nuestra atención termina moldeando nuestros deseos. Mirar hacia arriba no es ignorar la tierra, sino recordar quién le da sentido y dirección.",
            "Elige hoy una distracción que puedas soltar por un rato para prestar atención a lo que de verdad importa.",
        ],
    ),
]


def _inline_text(inlines) -> str:
    parts = []
    for inline in inlines:
        if inline.get("t") in ("text", "span"):
            parts.append(inline.get("v", ""))
        elif inline.get("t") == "line":
            parts.append(" ")
    return "".join(parts).strip()


def build_devotional() -> None:
    rv = DATA / "resources" / "bible.rv1909"
    manifest = read_json(rv / "manifest.json")
    books = {b["code"]: b["name"] for b in manifest["books"]}

    sections = []
    current = date(2024, 1, 1)  # año bisiesto: incluye 02.29
    reading_cache: dict[str, tuple[str, str]] = {}
    for index in range(366):
        day = current + timedelta(days=index)
        mmdd = f"{day.month:02d}.{day.day:02d}"
        theme, reference, paragraphs = READINGS[index % len(READINGS)]
        book_code, chapter, verse = reference.split(".")
        cache_key = f"{book_code}.{chapter}"
        if cache_key not in reading_cache:
            doc = read_json(rv / "sections" / f"{cache_key}.json")
            verse_text = ""
            for block in doc["blocks"]:
                if block.get("type") != "verseGroup":
                    continue
                for item in block["verses"]:
                    if item["n"] == int(verse):
                        verse_text = _inline_text(item["inlines"])
                        break
            reading_cache[cache_key] = verse_text
        verse_text = reading_cache[cache_key]
        if not verse_text:
            raise SystemExit(f"sin texto para {reference}")

        label = f"{books[book_code]} {chapter}:{verse}"
        blocks = [
            {
                "type": "heading",
                "text": f"{day.day} de {MONTHS[day.month - 1]}",
                "style": "section",
            },
            {
                "type": "paragraph",
                "inlines": [{"t": "span", "v": f"«{verse_text}»", "style": "italic"}],
            },
            {
                "type": "paragraph",
                "inlines": [{"t": "xref", "label": label, "ref": reference}],
            },
            {"type": "heading", "text": theme, "style": "section"},
            *[
                {"type": "paragraph", "inlines": [{"t": "text", "v": text}]}
                for text in paragraphs
            ],
        ]
        sections.append(
            {
                "id": f"dayofyear.{mmdd}",
                "day": mmdd,
                "title": f"{day.day} de {MONTHS[day.month - 1]}",
                "theme": theme,
                "reference": reference,
                "referenceLabel": label,
                "blocks": blocks,
            }
        )

    manifest = {
        "id": "devotional.daily",
        "resourceId": "devotional.daily",
        "type": "devotional",
        "title": "Devocional diario",
        "subtitle": "Una lectura para cada día",
        "abbrev": "DEV",
        "authors": ["Aletheia"],
        "language": "es",
        "publisher": "Aletheia",
        "edition": "2026",
        "license": {
            "kind": "original",
            "text": "Reflexiones propias; versículos de la RV1909 (dominio público)",
        },
        "description": (
            "Lectura diaria con un versículo de la Reina-Valera 1909 y una "
            "reflexión breve. Las 30 lecturas rotan a lo largo del año."
        ),
        "tags": ["Devocional", "Español"],
        "attributes": {"calendar": "MM.DD"},
        "stats": {"sections": len(sections)},
        "updatedAt": "2026-10-19T00:00:00Z",
        "books": [],
    }
    for dest in (DATA / "resources" / "devotional.daily", ASSETS / "devotional.daily"):
        write_json(dest / "manifest.json", manifest)
        write_json(dest / "sections.json", sections)
    print(f"devocional: {len(sections)} días")


# -------------------------------------------------------------------- factbook

MAPS = read_json(ROOT / "catalog" / "config" / "maps.json")["maps"]


ARTICLES = [
    {
        "id": "gracia",
        "title": "Gracia",
        "summary": "Favor inmerecido de Dios que sostiene, perdona y transforma.",
        "tags": ["Teología", "Salvación"],
        "related": ["fe", "justificacion", "amor"],
        "references": ["EPH.2.8", "ROM.3.24", "TIT.2.11"],
        "paragraphs": [
            "La gracia es el favor que Dios concede sin que lo hayamos ganado. No es un premio por méritos, sino un regalo que revela su carácter y abre la puerta a una relación con él.",
            "En el Nuevo Testamento, la gracia aparece unida a Jesucristo: por medio de él se ofrece perdón y vida nueva. Recibirla implica dejar de confiar en la propia suficiencia y aprender a vivir con gratitud.",
        ],
    },
    {
        "id": "fe",
        "title": "Fe",
        "summary": "Confianza activa en Dios, que se apoya en su carácter y sus promesas.",
        "tags": ["Teología", "Vida cristiana"],
        "related": ["esperanza", "gracia", "oracion"],
        "references": ["HEB.11.1", "ROM.10.17", "JAS.2.17"],
        "paragraphs": [
            "La fe bíblica no es un salto ciego, sino una confianza que responde a lo que Dios ha mostrado de sí mismo. Se apoya en su Palabra y se expresa en decisiones concretas.",
            "Creer no elimina las preguntas, pero cambia la manera de atravesarlas: en lugar de cargar todo en soledad, se camina con Dios y en comunidad.",
        ],
    },
    {
        "id": "esperanza",
        "title": "Esperanza",
        "summary": "Expectativa confiada en las promesas de Dios, sostenida incluso en la dificultad.",
        "tags": ["Teología", "Consuelo"],
        "related": ["fe", "amor", "reino-de-dios"],
        "references": ["ROM.15.13", "1PE.1.3", "HEB.6.19"],
        "paragraphs": [
            "La esperanza cristiana mira hacia el futuro de Dios sin escapar del presente. No es optimismo vacío, sino la certeza de que la última palabra no la tendrán el mal ni la muerte.",
            "Se cultiva en la oración, en la memoria de la fidelidad pasada y en la compañía de otros creyentes. A menudo crece precisamente cuando los recursos propios se agotan.",
        ],
    },
    {
        "id": "amor",
        "title": "Amor",
        "summary": "El centro del carácter de Dios y la marca que distingue a sus seguidores.",
        "tags": ["Teología", "Vida cristiana"],
        "related": ["gracia", "fe", "esperanza"],
        "references": ["1CO.13.4", "1JN.4.8", "JHN.13.35"],
        "paragraphs": [
            "El amor bíblico es más que un sentimiento: es una disposición que busca el bien del otro. Dios lo demuestra primero y luego invita a sus seguidores a practicarlo.",
            "Pablo lo describe con verbos concretos: es paciente, servicial, no envidia ni se jacta. Ese amor se aprende en lo cotidiano y se fortalece en la comunidad.",
        ],
    },
    {
        "id": "oracion",
        "title": "Oración",
        "summary": "Conversación con Dios que sostiene la vida de fe en lo personal y en lo comunitario.",
        "tags": ["Vida cristiana", "Práctica"],
        "related": ["fe", "amor", "santificacion"],
        "references": ["MAT.6.9", "PHP.4.6", "JAS.5.16"],
        "paragraphs": [
            "Orar es presentarse delante de Dios con lo que hay: gratitud, preguntas, necesidad y esperanza. No exige palabras perfectas, sino sinceridad y perseverancia.",
            "La oración también abre los ojos hacia los demás. Interceder por otros ensancha el corazón y nos recuerda que no estamos solos en el camino.",
        ],
    },
    {
        "id": "arrepentimiento",
        "title": "Arrepentimiento",
        "summary": "Cambio de mente y de rumbo que responde al llamado de Dios.",
        "tags": ["Teología", "Salvación"],
        "related": ["gracia", "fe", "perdon"],
        "references": ["ACT.3.19", "2CO.7.10", "JOL.2.13"],
        "paragraphs": [
            "Arrepentirse no es solo sentir culpa; es reconocer el rumbo equivocado y volver hacia Dios. Incluye un cambio de mente que se traduce en un cambio de vida.",
            "El arrepentimiento cristiano siempre ocurre en el horizonte de la gracia: no huimos de Dios hacia el perdón, sino que acudimos a él porque ya nos ofrece su misericordia.",
        ],
    },
    {
        "id": "justificacion",
        "title": "Justificación",
        "summary": "Declaración de justicia que Dios concede por gracia, mediante la fe en Cristo.",
        "tags": ["Teología", "Salvación"],
        "related": ["gracia", "fe", "santificacion"],
        "references": ["ROM.3.24", "ROM.5.1", "GAL.2.16"],
        "paragraphs": [
            "La justificación es una imagen judicial: el pecador es declarado justo por Dios. No se basa en obras humanas, sino en la obra de Cristo recibida por la fe.",
            "Sus frutos son la paz con Dios y una nueva libertad. Lejos de fomentar la indiferencia, la gratitud por haber sido aceptados impulsa una vida transformada.",
        ],
    },
    {
        "id": "santificacion",
        "title": "Santificación",
        "summary": "Proceso por el cual la vida se va conformando al carácter de Cristo.",
        "tags": ["Teología", "Vida cristiana"],
        "related": ["justificacion", "oracion", "amor"],
        "references": ["1TH.4.3", "HEB.12.14", "PHP.2.13"],
        "paragraphs": [
            "Ser santificado es ser apartado para Dios y, a la vez, ir siendo transformado. Comienza en la conversión, pero se desarrolla durante toda la vida.",
            "No depende solo del esfuerzo personal: Dios es quien produce el querer y el hacer. La disciplina espiritual —oración, Escritura, comunidad— es el espacio donde esa obra crece.",
        ],
    },
    {
        "id": "pacto",
        "title": "Pacto",
        "summary": "Vínculo establecido por Dios que define una relación de compromiso y promesa.",
        "tags": ["Teología", "Antiguo Testamento"],
        "related": ["gracia", "reino-de-dios", "esperanza"],
        "references": ["GEN.12.2", "EXO.19.5", "LUK.22.20"],
        "paragraphs": [
            "La historia bíblica se organiza en torno a una serie de pactos. Dios toma la iniciativa, promete bendición y llama a un pueblo a vivir de acuerdo con esa relación.",
            "El Nuevo Testamento presenta a Jesús como mediador de un pacto nuevo, en el que la promesa se abre a todas las naciones.",
        ],
    },
    {
        "id": "reino-de-dios",
        "title": "Reino de Dios",
        "summary": "El gobierno de Dios que irrumpe en la historia y alcanzará su plenitud al final.",
        "tags": ["Teología", "Evangelios"],
        "related": ["jesucristo", "esperanza", "pacto"],
        "references": ["MRK.1.15", "MAT.6.10", "LUK.17.21"],
        "paragraphs": [
            "Jesús anunció que el reino de Dios se había acercado. No se trataba de un territorio, sino del gobierno de Dios que irrumpe en la vida de las personas y de la sociedad.",
            "El reino ya está presente en la obra de Jesús, pero aún espera su consumación. Por eso la iglesia ora «venga tu reino» y vive como anticipo de esa realidad.",
        ],
    },
    {
        "id": "jesucristo",
        "title": "Jesucristo",
        "summary": "El Hijo de Dios encarnado, centro del Nuevo Testamento y de la fe cristiana.",
        "tags": ["Personas", "Teología"],
        "related": ["gracia", "reino-de-dios", "juan-el-bautista"],
        "references": ["JHN.1.1", "PHP.2.6", "HEB.1.3"],
        "map": "jesus",
        "paragraphs": [
            "El Nuevo Testamento presenta a Jesús de Nazaret como el Hijo de Dios hecho hombre. Nació en Belén, vivió en Galilea, enseñó sobre el reino de Dios y fue crucificado en Jerusalén.",
            "Los primeros cristianos confesaron que resucitó y que está vivo. En torno a su persona se articulan la salvación, la comunidad de fe y la esperanza del mundo.",
        ],
    },
    {
        "id": "juan-el-bautista",
        "title": "Juan el Bautista",
        "summary": "Profeta que preparó el camino para Jesús y bautizaba en el Jordán.",
        "tags": ["Personas", "Evangelios"],
        "related": ["jesucristo", "arrepentimiento", "reino-de-dios"],
        "references": ["MAT.3.1", "LUK.3.3", "JHN.1.29"],
        "paragraphs": [
            "Juan predicó en el desierto un bautismo de arrepentimiento y llamó a preparar el camino del Señor. Su mensaje sacudió a sus contemporáneos y atrajo a multitudes al Jordán.",
            "Señaló a Jesús como el cordero de Dios que quita el pecado del mundo. Su figura cierra el Antiguo Testamento y abre el tiempo del cumplimiento.",
        ],
    },
    {
        "id": "pablo",
        "title": "Pablo",
        "summary": "Apóstol de las naciones y autor de buena parte de las cartas del Nuevo Testamento.",
        "tags": ["Personas", "Nuevo Testamento"],
        "related": ["gracia", "justificacion", "jesucristo"],
        "references": ["ACT.9.15", "GAL.1.13", "2TI.4.7"],
        "map": "pablo",
        "paragraphs": [
            "Pablo persiguió a los primeros cristianos hasta que afirmó haber encontrado a Cristo resucitado. Desde entonces dedicó su vida a anunciar el evangelio entre judíos y gentiles.",
            "Sus cartas abordan la gracia, la justificación por la fe, la vida en comunidad y la esperanza. Su influencia en la formación del pensamiento cristiano es decisiva.",
        ],
    },
    {
        "id": "pedro",
        "title": "Pedro",
        "summary": "Discípulo de Jesús y líder destacado de la iglesia primitiva.",
        "tags": ["Personas", "Nuevo Testamento"],
        "related": ["jesucristo", "pablo", "fe"],
        "references": ["MAT.16.16", "JHN.21.17", "ACT.2.14"],
        "paragraphs": [
            "Pedro fue uno de los primeros discípulos llamados por Jesús. Su carácter impulsivo lo llevó a confesar a Cristo como el Hijo de Dios y, poco después, a negarlo.",
            "El Nuevo Testamento lo muestra restaurado y predicando en Pentecostés. Las cartas que llevan su nombre animan a los creyentes a perseverar en medio del sufrimiento.",
        ],
    },
    {
        "id": "maria",
        "title": "María",
        "summary": "Madre de Jesús, ejemplo de fe y disponibilidad ante el llamado de Dios.",
        "tags": ["Personas", "Evangelios"],
        "related": ["jesucristo", "belen", "fe"],
        "references": ["LUK.1.38", "LUK.1.46", "JHN.19.25"],
        "paragraphs": [
            "María recibió el anuncio del ángel con pregunta y confianza. Su respuesta —«hágase según tu palabra»— expresa una fe que se entrega sin conocer todos los detalles.",
            "Acompañó a Jesús desde su nacimiento hasta la cruz. Su canto de alabanza, el Magníficat, celebra la justicia y la misericordia de Dios.",
        ],
    },
    {
        "id": "jerusalen",
        "title": "Jerusalén",
        "summary": "Ciudad central de la historia bíblica, sede del templo y de la pasión de Jesús.",
        "tags": ["Lugares", "Historia"],
        "related": ["belen", "jesucristo", "pacto"],
        "references": ["2SA.5.6", "PSA.122.2", "LUK.19.41"],
        "map": "jerusalen",
        "paragraphs": [
            "Jerusalén aparece en el Antiguo Testamento como la ciudad de David y el lugar del templo. Fue centro del culto y escenario de numerosos acontecimientos políticos y proféticos.",
            "En los Evangelios, Jesús entra en Jerusalén, enseña en el templo y es crucificado fuera de sus muros. La ciudad encarna tanto la esperanza de Israel como su resistencia al mensaje de Dios.",
        ],
    },
    {
        "id": "belen",
        "title": "Belén",
        "summary": "Pequeña ciudad de Judá asociada con David y el nacimiento de Jesús.",
        "tags": ["Lugares", "Evangelios"],
        "related": ["jesucristo", "maria", "jerusalen"],
        "references": ["MIC.5.2", "LUK.2.4", "MAT.2.1"],
        "map": "belen",
        "paragraphs": [
            "Belén era una aldea modesta a unos kilómetros de Jerusalén. El Antiguo Testamento la vinculó con la dinastía de David y la anunció como lugar del futuro gobernante de Israel.",
            "Los Evangelios de Mateo y Lucas sitúan allí el nacimiento de Jesús, una señal de que Dios elige lo pequeño para cumplir sus propósitos.",
        ],
    },
    {
        "id": "galilea",
        "title": "Galilea",
        "summary": "Región del norte donde creció Jesús y comenzó su ministerio público.",
        "tags": ["Lugares", "Evangelios"],
        "related": ["jesucristo", "pedro", "reino-de-dios"],
        "references": ["ISA.9.1", "MAT.4.18", "JHN.2.11"],
        "map": "galilea",
        "paragraphs": [
            "Galilea, con el lago de Genesaret en su centro, fue el escenario de la mayor parte del ministerio de Jesús. Allí llamó a sus primeros discípulos y realizó numerosos milagros.",
            "La región era diversa y estaba lejos del centro religioso de Jerusalén. Que el Mesías surgiera de Galilea sorprendió a muchos y subraya el alcance universal del evangelio.",
        ],
    },
    {
        "id": "nazaret",
        "title": "Nazaret",
        "summary": "Ciudad de Galilea donde Jesús creció y fue anunciado por el ángel Gabriel.",
        "tags": ["Lugares", "Evangelios", "Galilea"],
        "related": ["jesucristo", "maria", "galilea"],
        "references": ["LUK.1.26", "LUK.4.16", "MAT.2.23"],
        "map": "galilea",
        "paragraphs": [
            "Nazaret era una pequeña población de Galilea, lejos de los centros de poder de Jerusalén. Allí vivió la familia de Jesús y allí regresó después de la huida a Egipto.",
            "En la sinagoga de Nazaret, Jesús leyó el texto de Isaías y anunció que la buena noticia se cumplía en él. Sus vecinos lo conocían como el hijo del carpintero, y su rechazo anticipó la oposición que encontraría en otros lugares.",
        ],
    },
    {
        "id": "cafarnaun",
        "title": "Cafarnaún",
        "summary": "Pueblo pesquero junto al mar de Galilea, centro del ministerio de Jesús.",
        "tags": ["Lugares", "Evangelios", "Galilea"],
        "related": ["jesucristo", "pedro", "mar-de-galilea"],
        "references": ["MAT.4.13", "MRK.1.21", "JHN.6.59"],
        "map": "mar-de-galilea",
        "paragraphs": [
            "Cafarnaún estaba en la orilla norte del mar de Galilea, junto a una importante ruta comercial. Jesús lo convirtió en su centro de actividad durante el ministerio en Galilea.",
            "Allí llamó a Pedro, Andrés, Santiago y Juan; enseñó en la sinagoga, sanó a enfermos y realizó la multiplicación de los panes. A pesar de tantas señales, el Evangelio registra que la ciudad no respondió plenamente a su mensaje.",
        ],
    },
    {
        "id": "roma",
        "title": "Roma",
        "summary": "Capital del imperio romano y destino final del viaje de Pablo.",
        "tags": ["Lugares", "Nuevo Testamento", "Iglesia primitiva"],
        "related": ["pablo", "corinto", "efeso"],
        "references": ["ACT.28.16", "ROM.1.7", "PHP.1.13"],
        "map": "roma",
        "paragraphs": [
            "Roma era el centro político y militar del Mediterráneo. La iglesia de la ciudad existía antes de la llegada de Pablo, y a ella dirigió una de sus cartas más extensas.",
            "Hechos termina con Pablo en Roma, predicando bajo arresto domiciliario. La tradición cristiana conserva allí su martirio y la memoria de Pedro, aunque el Nuevo Testamento no describe los detalles de sus muertes.",
        ],
    },
    {
        "id": "efeso",
        "title": "Éfeso",
        "summary": "Ciudad de Asia Menor, sede de una iglesia importante y lugar de la enseñanza de Pablo.",
        "tags": ["Lugares", "Nuevo Testamento", "Iglesia primitiva"],
        "related": ["pablo", "roma", "atenas"],
        "references": ["ACT.19.1", "EPH.1.1", "REV.2.1"],
        "map": "efeso",
        "paragraphs": [
            "Éfeso era un puerto próspero y un centro religioso famoso por el templo de Artemisa. Pablo permaneció allí durante varios años y la iglesia creció en medio de un ambiente hostil.",
            "La carta a los Efesios presenta a la iglesia como un cuerpo reconciliado en Cristo. En Apocalipsis, la comunidad de Éfeso recibe elogio por su trabajo y una advertencia por haber abandonado su primer amor.",
        ],
    },
    {
        "id": "corinto",
        "title": "Corinto",
        "summary": "Ciudad griega donde Pablo fundó una iglesia y a la que dirigió varias cartas.",
        "tags": ["Lugares", "Nuevo Testamento", "Iglesia primitiva"],
        "related": ["pablo", "atenas", "efeso"],
        "references": ["ACT.18.1", "1CO.1.2", "2CO.1.1"],
        "map": "corinto",
        "paragraphs": [
            "Corinto estaba en el istmo que unía el Peloponeso con Grecia y contaba con dos puertos. Su prosperidad y su mezcla cultural plantearon a la iglesia preguntas sobre identidad, libertad y vida en común.",
            "Pablo trabajó allí como artesano y predicó durante más de un año. Las cartas a los Corintios muestran una comunidad viva, con dones y conflictos, a la que el apóstol llama a vivir el evangelio con humildad y amor.",
        ],
    },
    {
        "id": "atenas",
        "title": "Atenas",
        "summary": "Centro cultural de Grecia; Pablo anunció el evangelio en el Areópago.",
        "tags": ["Lugares", "Nuevo Testamento", "Historia"],
        "related": ["pablo", "corinto", "efeso"],
        "references": ["ACT.17.16", "ACT.17.22", "1TH.3.1"],
        "map": "atenas",
        "paragraphs": [
            "Atenas conservaba prestigio por su filosofía, sus escuelas y sus monumentos. Pablo recorrió la ciudad, observó sus altares y discutió en la sinagoga y en la plaza pública.",
            "En el Areópago, el apóstol presentó al Dios desconocido como el Creador que llama a todos a arrepentirse. Algunos se burlaron, otros quisieron oírlo de nuevo y unos pocos creyeron.",
        ],
    },
    {
        "id": "damasco",
        "title": "Damasco",
        "summary": "Ciudad de Siria donde Saulo fue llamado por Cristo y comenzó a predicar.",
        "tags": ["Lugares", "Nuevo Testamento", "Iglesia primitiva"],
        "related": ["pablo", "jerusalen", "atenas"],
        "references": ["ACT.9.3", "ACT.9.20", "GAL.1.17"],
        "map": "damasco",
        "paragraphs": [
            "Damasco era un cruce de rutas comerciales al norte de Israel. Saulo viajaba hacia allí con cartas para perseguir a los discípulos cuando una luz lo detuvo y escuchó la voz de Jesús.",
            "Ananías lo visitó, oró por él y Saulo recuperó la vista. Después de ser bautizado, comenzó a proclamar en las sinagogas que Jesús es el Hijo de Dios, para asombro de quienes lo conocían como perseguidor.",
        ],
    },
    {
        "id": "jerico",
        "title": "Jericó",
        "summary": "Ciudad del valle del Jordán asociada con la conquista de Josué y la conversión de Zaqueo.",
        "tags": ["Lugares", "Antiguo Testamento", "Evangelios"],
        "related": ["rio-jordan", "jerusalen", "jesus"],
        "references": ["JOS.6.20", "LUK.19.1", "HEB.11.30"],
        "map": "jerico",
        "paragraphs": [
            "Jericó se encuentra en un oasis del valle del Jordán, cerca del lugar donde Israel cruzó el río. El libro de Josué narra la caída de sus murallas después de siete días de marcha y clamor.",
            "En tiempos de Jesús, Jericó era una ciudad de paso hacia Jerusalén. Allí Zaqueo, un recaudador de impuestos, subió a un árbol para ver a Jesús y recibió una invitación que transformó su vida.",
        ],
    },
    {
        "id": "samaria",
        "title": "Samaria",
        "summary": "Región entre Galilea y Judea; Jesús conversó allí con la mujer samaritana.",
        "tags": ["Lugares", "Evangelios", "Historia"],
        "related": ["jesus", "jerusalen", "galilea"],
        "references": ["JHN.4.4", "JHN.4.5", "ACT.8.5"],
        "map": "samaria",
        "paragraphs": [
            "Samaria ocupaba la zona montañosa entre Galilea y Judea. Sus habitantes tenían su propio templo en el monte Gerizim y una relación tensa con los judíos de Jerusalén.",
            "Jesús atravesó Samaria y conversó con una mujer junto al pozo de Sicar. La conversación pasó del agua del pozo al don del Espíritu y terminó con muchos samaritanos creyendo en él.",
        ],
    },
    {
        "id": "monte-sinai",
        "title": "Monte Sinaí",
        "summary": "Montaña donde Moisés recibió la ley y Israel ratificó la alianza con Dios.",
        "tags": ["Lugares", "Antiguo Testamento", "Historia"],
        "related": ["egipto", "rio-jordan", "pacto"],
        "references": ["EXO.19.20", "EXO.20.1", "HEB.12.18"],
        "map": "sinai",
        "paragraphs": [
            "El monte Sinaí, también llamado Horeb, es el escenario de la teofanía del éxodo. Dios llamó a Moisés desde la zarza ardiente y más tarde entregó las tablas de la ley en medio de fuego, humo y temblor.",
            "La alianza del Sinaí forma al pueblo de Israel como nación consagrada. El Nuevo Testamento recuerda el monte como imagen de la ley y lo contrasta con el monte Sion y la gracia de Cristo.",
        ],
    },
    {
        "id": "mar-de-galilea",
        "title": "Mar de Galilea",
        "summary": "Lago de agua dulce en Galilea, escenario de la llamada de los discípulos y de varios milagros.",
        "tags": ["Lugares", "Evangelios", "Galilea"],
        "related": ["cafarnaun", "jesus", "galilea"],
        "references": ["MAT.4.18", "MRK.4.39", "JHN.21.1"],
        "map": "mar-de-galilea",
        "paragraphs": [
            "El mar de Galilea, también llamado lago de Genesaret o Tiberíades, está rodeado de colinas y era rico en pesca. Varios discípulos de Jesús eran pescadores de sus orillas.",
            "En el lago, Jesús calmó la tormenta, caminó sobre las aguas y apareció a sus discípulos después de la resurrección. El agua se convierte así en escenario de miedo, asombro y misión.",
        ],
    },
    {
        "id": "rio-jordan",
        "title": "Río Jordán",
        "summary": "Río del valle del rift donde Jesús fue bautizado por Juan.",
        "tags": ["Lugares", "Evangelios", "Antiguo Testamento"],
        "related": ["jerico", "mar-de-galilea", "juan-el-bautista"],
        "references": ["MAT.3.13", "JOS.3.17", "2KI.5.14"],
        "map": "jordan",
        "paragraphs": [
            "El Jordán nace en el norte y desciende hasta el mar Muerto, atravesando el valle del rift. Israel cruzó el río al entrar en la tierra prometida, y Naamán fue sanado al sumergirse en sus aguas.",
            "Juan el Bautista predicó junto al Jordán y bautizó a Jesús. Para los primeros cristianos, el río recordaba el bautismo, la purificación y el comienzo de la misión pública del Mesías.",
        ],
    },
    {
        "id": "egipto",
        "title": "Egipto",
        "summary": "Tierra donde Israel fue esclavo y donde José y María llevaron a Jesús para protegerlo.",
        "tags": ["Lugares", "Antiguo Testamento", "Evangelios"],
        "related": ["monte-sinai", "jose", "jesus"],
        "references": ["GEN.46.3", "EXO.1.8", "MAT.2.13"],
        "map": "exodo",
        "paragraphs": [
            "Egipto, junto al Nilo, fue refugio y también lugar de esclavitud para Israel. José llegó allí vendido como esclavo y terminó administrando el país durante el hambre.",
            "Siglos después, Moisés guió al pueblo fuera de Egipto. En el Evangelio de Mateo, Egipto vuelve a aparecer como refugio: José y María llevan allí a Jesús para escapar de Herodes.",
        ],
    },
    {
        "id": "judea",
        "title": "Judea",
        "summary": "Región del sur de Israel, con Jerusalén como centro; escenario de la infancia y pasión de Jesús.",
        "tags": ["Lugares", "Evangelios", "Historia"],
        "related": ["jerusalen", "belen", "jesus"],
        "references": ["LUK.1.5", "MAT.2.1", "ACT.1.8"],
        "map": "jerusalen",
        "paragraphs": [
            "Judea era la región montañosa del sur, con Jerusalén, Belén y el desierto como lugares centrales. En tiempos de Jesús estaba bajo dominio romano y gobernada por Herodes el Grande y sus sucesores.",
            "El Evangelio de Lucas sitúa en Judea los anuncios del nacimiento de Juan y de Jesús. Allí se desarrollan la pasión, la resurrección y el testimonio inicial de la iglesia.",
        ],
    },
    # Se puede ampliar el Factbook añadiendo entradas con la misma forma.
]


def build_factbook() -> None:
    sections = []
    for article in ARTICLES:
        blocks = [
            {"type": "heading", "text": article["title"], "style": "section"},
            *[
                {"type": "paragraph", "inlines": [{"t": "text", "v": text}]}
                for text in article["paragraphs"]
            ],
        ]
        map_key = article.get("map")
        if map_key:
            blocks.append({"type": "map", **MAPS[map_key]})
        sections.append(
            {
                "id": article["id"],
                "kind": "topic",
                "title": article["title"],
                "summary": article["summary"],
                "tags": article["tags"],
                "related": article["related"],
                "references": article["references"],
                "blocks": blocks,
            }
        )

    manifest = {
        "id": "factbook.core",
        "resourceId": "factbook.core",
        "type": "factbook",
        "title": "Enciclopedia bíblica",
        "subtitle": "Temas, personas y lugares",
        "abbrev": "FB",
        "authors": ["Aletheia"],
        "language": "es",
        "publisher": "Aletheia",
        "license": {"kind": "original", "text": "Contenido propio de Aletheia"},
        "description": (
            "Artículos breves sobre temas, personas y lugares de la Biblia, "
            "con referencias, temas relacionados y mapas esquemáticos. Contenido propio."
        ),
        "tags": ["Factbook", "Temas", "Lugares", "Mapas", "Español"],
        "stats": {"sections": len(sections)},
        "updatedAt": "2026-10-19T00:00:00Z",
        "books": [],
    }
    for dest in (DATA / "resources" / "factbook.core", ASSETS / "factbook.core"):
        write_json(dest / "manifest.json", manifest)
        write_json(dest / "sections.json", sections)
    print(f"factbook: {len(sections)} artículos")


def update_indexes() -> None:
    catalog_path = DATA / "catalog.json"
    catalog = read_json(catalog_path)
    known = {entry["id"] for entry in catalog["resources"]}
    for rid in ("devotional.daily", "factbook.core"):
        if rid not in known:
            catalog["resources"].append({"id": rid, "path": f"resources/{rid}"})
    write_json(catalog_path, catalog)

    index_path = ASSETS / "index.json"
    index = read_json(index_path)
    by_id = {entry["id"]: entry for entry in index}
    for rid in ("devotional.daily", "factbook.core"):
        manifest = read_json(ASSETS / rid / "manifest.json")
        by_id[rid] = manifest
    write_json(index_path, list(by_id.values()))
    manifests = [
        read_json(DATA / entry["path"] / "manifest.json")
        for entry in catalog["resources"]
    ]
    build_index(DATA, manifests)
    print(f"índices: {len(catalog['resources'])} recursos, {len(by_id)} locales")


def main() -> int:
    build_devotional()
    build_factbook()
    update_indexes()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
