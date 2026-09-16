import 'package:flutter/foundation.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

/// Servicio de videollamada (Capa A de las notas del proyecto).
///
/// Usa el servidor público de Jitsi Meet (meet.jit.si), así que no requiere
/// backend propio ni credenciales: basta con que ambos usuarios entren a la
/// misma sala. Usamos el `conversacionId` del chat como nombre de sala, ya
/// que es único por par de usuarios.
class VideoCallService {
  static final JitsiMeet _jitsiMeet = JitsiMeet();

  /// Genera un nombre de sala válido para Jitsi a partir del id de la
  /// conversación (evita caracteres que Jitsi no acepta en nombres de sala).
  static String salaDesdeConversacion(String conversacionId) {
    final limpio = conversacionId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return 'talkia-$limpio';
  }

  /// Une al usuario actual a la videollamada de una conversación.
  ///
  /// [conversacionId] identifica la sala (compartida por ambos usuarios).
  /// [nombreUsuario] y [correoUsuario] se muestran a la otra persona en la
  /// llamada.
  static Future<void> iniciarLlamada({
    required String conversacionId,
    required String nombreUsuario,
    required String correoUsuario,
  }) async {
    final options = JitsiMeetConferenceOptions(
      serverURL: "https://meet.jit.si",
      room: salaDesdeConversacion(conversacionId),
      configOverrides: {
        "startWithAudioMuted": false,
        "startWithVideoMuted": false,
        "subject": "Talkia",
      },
      featureFlags: {
        // Oculta funciones que no necesitamos para una llamada 1 a 1 simple
        "invite.enabled": false,
        "add-people.enabled": false,
        "calendar.enabled": false,
        "chat.enabled": false,
        "live-streaming.enabled": false,
        "recording.enabled": false,
        "unsaferoomwarning.enabled": false,
        // Permite minimizar la llamada a una ventanita flotante (PiP) y
        // volver a la app: así queda visible la barra de subtítulos de
        // Talkia (que vive en la pantalla de Flutter, no dentro de Jitsi).
        "pip.enabled": true,
      },
      userInfo: JitsiMeetUserInfo(
        displayName: nombreUsuario,
        email: correoUsuario,
      ),
    );

    final listener = JitsiMeetEventListener(
      conferenceJoined: (url) {
        debugPrint("📹 Videollamada iniciada: $url");
      },
      conferenceTerminated: (url, error) {
        debugPrint("📹 Videollamada terminada: $url ${error ?? ''}");
      },
      participantJoined: (email, name, role, participantId) {
        debugPrint("📹 Se unió: $name");
      },
      participantLeft: (participantId) {
        debugPrint("📹 Participante salió: $participantId");
      },
      readyToClose: () {
        debugPrint("📹 Lista para cerrar");
      },
    );

    await _jitsiMeet.join(options, listener);
  }

  /// Cierra la videollamada activa, si hay una en curso.
  static Future<void> colgar() async {
    await _jitsiMeet.hangUp();
  }
}
