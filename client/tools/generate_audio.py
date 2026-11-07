#!/usr/bin/env python3
"""Genera los audios de la partida de Truco Uruguayo (efectos y voces).

⚠️  LOS AUDIOS GENERADOS SON MARCADORES DE POSICIÓN.
    - Los efectos se sintetizan con numpy (ruido filtrado + golpe grave).
    - Las voces usan el sintetizador espeak-ng (voz es-419, GPL-3): suenan
      robóticas. Para publicar la app conviene reemplazarlas por grabaciones
      reales (RF-20: "locuciones típicas con audio folclórico") usando
      EXACTAMENTE los mismos nombres de archivo.
    - NO se usan las voces MBROLA: su licencia prohíbe incorporarlas a un
      producto que se venda. La opción --engine mbrola existe sólo para
      probar en desarrollo; no subas ese resultado al repositorio.

Requisitos: espeak-ng, ffmpeg (con libmp3lame), python3 con numpy y scipy.

Uso (desde la carpeta client/):
    python3 tools/generate_audio.py
    python3 tools/generate_audio.py --only sfx      # sólo efectos
    python3 tools/generate_audio.py --only voice    # sólo voces
    python3 tools/generate_audio.py --manifest-only # sólo recalcular duraciones
                                                    # (úsalo si reemplazás las voces
                                                    #  por grabaciones reales)

Salida:
    assets/audio/sfx/*.wav
    assets/audio/voice/player/<clave>.mp3   (tu voz)
    assets/audio/voice/rival/<clave>.mp3    (voz del rival)

También genera lib/features/game/audio/voice_durations.dart con la duración real
de cada frase: el globo de texto dura lo que dura su voz.

Las claves de voz deben coincidir con lib/features/game/audio/game_voices.dart
(hay un test que lo verifica).
"""
import argparse
import os
import subprocess
import sys
import tempfile
import wave

import numpy as np
from scipy import signal

SR = 22050
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'audio')

# --------------------------------------------------------------------------
# Frases: clave -> texto que se pronuncia.
# --------------------------------------------------------------------------
PHRASES = {
    # cantos
    'envido': 'Envido',
    'envido_envido': 'Envido, envido',
    'real_envido': 'Real envido',
    'falta_envido': 'Falta envido',
    'flor': 'Flor',
    'contraflor': 'Contraflor',
    'truco': 'Truco',
    'retruco': 'Quiero retruco',
    'vale_cuatro': 'Quiero vale cuatro',
    # respuestas
    'quiero': 'Quiero',
    'quiero_dale': 'Quiero, dale',
    'no_quiero': 'No quiero',
    'no_no_quiero': 'No, no quiero',
    'con_flor_me_achico': 'Con flor me achico',
    # mazo
    'me_voy_al_mazo': 'Me voy al mazo',
    'al_mazo': 'Al mazo',
    # envido / flor resueltos
    'son_buenas': 'Son buenas',
}
for n in range(0, 60):          # envido: de 0 a 59 (dos piezas: 30 + 29)
    PHRASES[f'tengo_{n}'] = f'Tengo {n}'
for n in range(20, 88):         # flor: de 20 a 87 (tres piezas: 30 + 29 + 28)
    PHRASES[f'flor_de_{n}'] = f'Flor de {n}'

# Dos voces distintas para que se distinga quién habla.
VOICES = {
    'player': dict(voice='es-419+m3', speed=150, pitch=55),
    'rival': dict(voice='es-419+m7', speed=140, pitch=30),
}


def read_wav(path):
    with wave.open(path) as w:
        data = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16)
        return data.astype(np.float32) / 32768.0, w.getframerate()


def write_wav(path, x, sr=SR):
    x = np.clip(x, -1, 1)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes((x * 32767).astype(np.int16).tobytes())


def trim(x, thresh=0.03, pad=0.02):
    peak = np.abs(x).max()
    idx = np.where(np.abs(x) > thresh * peak)[0]
    if len(idx) == 0:
        return x
    a = max(0, idx[0] - int(pad * SR))
    b = min(len(x), idx[-1] + int(pad * SR))
    return x[a:b]


def fade(x, ms=8):
    n = int(SR * ms / 1000)
    x = x.copy()
    x[:n] *= np.linspace(0, 1, n)
    x[-n:] *= np.linspace(1, 0, n)
    return x


def normalize_rms(x, target=0.11, peak_max=0.92):
    rms = float(np.sqrt(np.mean(x ** 2))) or 1e-9
    g = target / rms
    g = min(g, peak_max / (np.abs(x).max() or 1e-9))
    return x * g


def to_mp3(wav_path, mp3_path):
    subprocess.run(
        ['ffmpeg', '-y', '-loglevel', 'error', '-i', wav_path,
         '-ac', '1', '-ar', str(SR), '-b:a', '48k', mp3_path],
        check=True)


def tts(text, cfg, engine):
    with tempfile.TemporaryDirectory() as d:
        out = os.path.join(d, 'o.wav')
        voice = cfg['voice']
        if engine == 'mbrola':  # SÓLO DESARROLLO: licencia no comercial
            voice = 'mb-mx1' if cfg is VOICES['player'] else 'mb-mx2'
        subprocess.run(
            ['espeak-ng', '-v', voice, '-s', str(cfg['speed']),
             '-p', str(cfg['pitch']), '-w', out, text],
            check=True, stderr=subprocess.DEVNULL)
        x, sr = read_wav(out)
    if sr != SR:
        x = signal.resample_poly(x, SR, sr)
    return x.astype(np.float32)


def make_voices(engine):
    for role, cfg in VOICES.items():
        out_dir = os.path.join(ROOT, 'voice', role)
        os.makedirs(out_dir, exist_ok=True)
        for key, text in PHRASES.items():
            x = fade(normalize_rms(trim(tts(text, cfg, engine))))
            with tempfile.TemporaryDirectory() as d:
                tmp = os.path.join(d, 'c.wav')
                write_wav(tmp, x)
                to_mp3(tmp, os.path.join(out_dir, key + '.mp3'))
        print(f'voz {role}: {len(PHRASES)} clips')


# --------------------------------------------------------------------------
# Manifiesto de duraciones (lo lee el controlador para sincronizar globos y voz)
# --------------------------------------------------------------------------
def probe_ms(path):
    out = subprocess.run(
        ['ffprobe', '-v', 'error', '-show_entries', 'format=duration',
         '-of', 'csv=p=0', path], capture_output=True, text=True, check=True)
    return int(float(out.stdout.strip()) * 1000) + 1


def write_manifest():
    keys = sorted({os.path.basename(f)[:-4]
                   for role in VOICES
                   for f in os.listdir(os.path.join(ROOT, 'voice', role))
                   if f.endswith('.mp3')})
    lines = [
        '// GENERADO por tools/generate_audio.py: no editar a mano.',
        '// Duración (ms) de cada frase hablada: el mayor valor entre tu voz y la del rival.',
        '',
        'const Map<String, int> kVoiceDurationsMs = {',
    ]
    for k in keys:
        ms = max(probe_ms(os.path.join(ROOT, 'voice', role, k + '.mp3'))
                 for role in VOICES)
        lines.append(f"  '{k}': {ms},")
    lines.append('};')
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib',
                        'features', 'game', 'audio', 'voice_durations.dart')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write('\n'.join(lines) + '\n')
    print(f'manifiesto: {len(keys)} frases')


# --------------------------------------------------------------------------
# Efectos
# --------------------------------------------------------------------------
def _bandpass(x, lo, hi):
    b, a = signal.butter(2, [lo / (SR / 2), hi / (SR / 2)], 'band')
    return signal.lfilter(b, a, x)


def card_place(seed):
    """Carta que cae sobre el paño: golpe seco + un poco de cuerpo grave."""
    rng = np.random.default_rng(seed)
    t = np.arange(int(0.20 * SR)) / SR
    noise = _bandpass(rng.standard_normal(len(t)), 1200 + 250 * seed, 5200)
    slap = noise * np.exp(-t / 0.014)
    slap /= np.abs(slap).max()
    f0 = 150 + 18 * seed
    body = np.sin(2 * np.pi * f0 * t * (1 - 0.5 * np.minimum(t / 0.08, 1))) * np.exp(-t / 0.032)
    tick = np.zeros_like(t)
    tick[: int(0.002 * SR)] = np.hanning(int(0.002 * SR) * 2)[: int(0.002 * SR)]
    x = 0.75 * slap + 0.65 * body + 0.4 * tick
    return fade(x / np.abs(x).max() * 0.85, 3)


def cards_to_deck():
    """Cartas que se juntan y se recogen: barrido de ruido + varios roces."""
    rng = np.random.default_rng(7)
    dur = 0.50
    t = np.arange(int(dur * SR)) / SR
    noise = rng.standard_normal(len(t))
    sweep = _bandpass(noise, 700, 4200)
    env = np.sin(np.pi * np.clip(t / dur, 0, 1)) ** 2 * (0.4 + 0.6 * (t / dur))
    x = 0.55 * sweep * env
    for pos in (0.04, 0.11, 0.19, 0.27, 0.36):  # roces de cartas
        i = int(pos * SR)
        n = int(0.025 * SR)
        burst = _bandpass(rng.standard_normal(n), 1800, 6000) * np.exp(-np.arange(n) / (0.006 * SR))
        x[i:i + n] += 0.5 * burst / (np.abs(burst).max() or 1)
    # golpecito final al apoyarse en el mazo
    i = int(0.42 * SR)
    n = int(0.06 * SR)
    tt = np.arange(n) / SR
    x[i:i + n] += 0.55 * np.sin(2 * np.pi * 120 * tt) * np.exp(-tt / 0.02)
    return fade(x / np.abs(x).max() * 0.8, 6)


def make_sfx():
    out_dir = os.path.join(ROOT, 'sfx')
    os.makedirs(out_dir, exist_ok=True)
    for i in range(1, 4):
        write_wav(os.path.join(out_dir, f'card_place_{i}.wav'), card_place(i))
    write_wav(os.path.join(out_dir, 'cards_to_deck.wav'), cards_to_deck())
    print('efectos: card_place_1..3.wav, cards_to_deck.wav')


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--only', choices=['sfx', 'voice'])
    ap.add_argument('--manifest-only', action='store_true')
    ap.add_argument('--engine', choices=['espeak', 'mbrola'], default='espeak')
    args = ap.parse_args()
    if args.engine == 'mbrola':
        print('AVISO: MBROLA es sólo para pruebas locales (licencia no comercial).',
              file=sys.stderr)
    if not args.manifest_only:
        if args.only in (None, 'sfx'):
            make_sfx()
        if args.only in (None, 'voice'):
            make_voices(args.engine)
    if args.manifest_only or args.only in (None, 'voice'):
        write_manifest()
