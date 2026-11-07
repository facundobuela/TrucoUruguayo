import 'voice_durations.dart';

/// Relaciona lo que dice un globo de texto con el audio que lo acompaña.
///
/// Los audios están en `assets/audio/voice/<player|rival>/<clave>.mp3` y se
/// generan con `tools/generate_audio.py` (o se reemplazan por grabaciones con
/// los mismos nombres).
class GameVoices {
  GameVoices._();

  static const Map<String, String> _byText = {
    // cantos
    '¡Envido!': 'envido',
    '¡Envido, envido!': 'envido_envido',
    '¡Real envido!': 'real_envido',
    '¡Falta envido!': 'falta_envido',
    '¡Flor!': 'flor',
    '¡Contraflor!': 'contraflor',
    '¡Truco!': 'truco',
    '¡Quiero retruco!': 'retruco',
    '¡Quiero vale cuatro!': 'vale_cuatro',
    // respuestas
    '¡Quiero!': 'quiero',
    '¡Quiero, dale!': 'quiero_dale',
    'No quiero': 'no_quiero',
    'No, no quiero': 'no_no_quiero',
    'Con flor me achico': 'con_flor_me_achico',
    // mazo y envido resuelto
    'Me voy al mazo': 'me_voy_al_mazo',
    'Al mazo': 'al_mazo',
    'Son buenas': 'son_buenas',
  };

  static final RegExp _tengo = RegExp(r'^Tengo (\d+)$');
  static final RegExp _florDe = RegExp(r'^Flor de (\d+)$');

  /// Rango de tantos con audio: envido de 0 a 59 y flor de 20 a 87.
  static const int envidoMax = 59;
  static const int florMin = 20;
  static const int florMax = 87;

  /// Clave del audio para el texto de un globo, o `null` si no tiene voz.
  static String? keyFor(String text) {
    final direct = _byText[text];
    if (direct != null) return direct;

    final tengo = _tengo.firstMatch(text);
    if (tengo != null) {
      final n = int.parse(tengo.group(1)!);
      return n <= envidoMax ? 'tengo_$n' : null;
    }
    final flor = _florDe.firstMatch(text);
    if (flor != null) {
      final n = int.parse(flor.group(1)!);
      return n >= florMin && n <= florMax ? 'flor_de_$n' : null;
    }
    return null;
  }

  /// Duración (ms) del audio de [key], o `null` si no se conoce.
  static int? durationMs(String key) => kVoiceDurationsMs[key];

  /// Todas las claves de voz que el juego puede pedir.
  static Iterable<String> get allKeys => kVoiceDurationsMs.keys;
}
