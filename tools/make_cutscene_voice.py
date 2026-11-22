#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
컷씬 대사를 한국어 음성(.ogg)으로 만들어 sounds/cutscene/ 에 저장합니다.
컷씬(scripts/story_cutscene.lua)은 이 파일들이 있으면 자동으로 읽어 주고, 없으면 말소리 효과음을 냅니다.

준비 (인터넷 연결 필요, 한 번만):
    pip install edge-tts
    ffmpeg 가 설치되어 있고 PATH 에 있어야 합니다.

사용:
    python tools/make_cutscene_voice.py            # 없는 파일만 생성
    python tools/make_cutscene_voice.py --force    # 전부 다시 생성
    python tools/make_cutscene_voice.py --dry-run  # 대사 목록과 파일 이름만 출력

대사를 고치면 scripts/story_cutscene.lua 의 sets 표만 수정하고 이 스크립트를 다시 실행하세요.
"""
import asyncio, os, re, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.dirname(HERE)
LUA = os.path.join(MOD, 'scripts', 'story_cutscene.lua')
OUT = os.path.join(MOD, 'sounds', 'cutscene')

# 캐릭터별 목소리 (edge-tts 한국어 음성). 필요하면 음성/높낮이(pitch)/속도(rate)를 바꿔 보세요.
VOICES = {
    'shinji': ('ko-KR-InJoonNeural', '+10Hz', '-8%'),
    'kaoru':  ('ko-KR-InJoonNeural', '-4Hz',  '-5%'),
    'asuka':  ('ko-KR-SunHiNeural',  '+12Hz', '+8%'),
    'rei':    ('ko-KR-SunHiNeural',  '-18Hz', '-18%'),
}


def parse_lines(path):
    src = open(path, encoding='utf-8').read()
    result = []
    for m in re.finditer(r"sets\['([^']+)'\]\s*=\s*\{(.*?)\n\}", src, re.S):
        slug = m.group(1).replace(' ', '-')
        n = 0
        for who, text in re.findall(r"\{\s*'(\w+)'\s*,\s*'((?:[^'\\]|\\.)*)'\s*\}", m.group(2)):
            n += 1
            result.append((slug, n, who, text.replace("\\'", "'")))
    return result


def clean(text):
    return text.replace('……', ', ').replace('…', ', ').strip()


async def synth(text, voice, pitch, rate, mp3):
    import edge_tts
    await edge_tts.Communicate(clean(text), voice, rate=rate, pitch=pitch).save(mp3)


def main():
    force = '--force' in sys.argv
    dry = '--dry-run' in sys.argv
    lines = parse_lines(LUA)
    if not lines:
        sys.exit('대사를 찾지 못했습니다: ' + LUA)
    os.makedirs(OUT, exist_ok=True)
    for slug, n, who, text in lines:
        out = os.path.join(OUT, f'{slug}_{n}.ogg')
        tag = '(있음)' if os.path.exists(out) else ''
        print(f'{slug}_{n}.ogg  [{who}] {text} {tag}')
        if dry or (os.path.exists(out) and not force):
            continue
        voice, pitch, rate = VOICES.get(who, VOICES['shinji'])
        with tempfile.TemporaryDirectory() as tmp:
            mp3 = os.path.join(tmp, 'v.mp3')
            asyncio.run(synth(text, voice, pitch, rate, mp3))
            subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', mp3, '-ac', '1',
                            '-c:a', 'libvorbis', '-q:a', '5', out], check=True)
    if not dry:
        print('완료: sounds/cutscene/ 에 음성 파일이 만들어졌습니다.')


if __name__ == '__main__':
    main()
