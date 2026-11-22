-- 치트(봇플레이 / 연습 모드) 감지 → 아스카가 나와서 면박을 주고, 3초 뒤 게임 종료
-- 설치: mods/eva/scripts/cheat_asuka.lua
-- (컷씬 음성 중단: scripts/story_cutscene.lua 도 함께 교체해야 완전히 멈춥니다)
-- 필요 파일: images/characters/asuka.png+xml, fonts/NotoSansKR-Medium.otf (이미 모드에 있음),
--            sounds/asuka_bad_user_fast.ogg (아스카 목소리, 약 3초)

local ENABLED       = true   -- false 로 바꾸면 이 기능을 끕니다(테스트용)
local CHEAT_BOTPLAY = false   -- 봇플레이를 치트로 취급
local CHEAT_PRACTICE = true  -- 연습 모드를 치트로 취급
local QUIT_SECONDS  = 3      -- 아스카가 나오고 몇 초 뒤에 종료할지
-- 아스카 목소리: 'asuka_bad_user_fast'(약 3초, 3초 종료에 맞춤) / 'asuka_bad_user'(원본 6초, QUIT_SECONDS 를 6 이상으로)
local VOICE_SOUND   = 'asuka_bad_user_fast'
local VOICE_VOLUME  = 0.9999   -- 사실상 1.0. 이 값으로 '아스카 목소리'만 골라내서 남기고 나머지 소리를 모두 끔
local PAUSE_SONG    = true   -- 아스카가 나올 때 노래·노트 진행을 멈춤

local FONT = 'NotoSansKR-Medium.otf'
local triggered = false

local function isCheating()
    if CHEAT_BOTPLAY and getProperty('cpuControlled') == true then return true end
    if CHEAT_PRACTICE and getProperty('practiceMode') == true then return true end
    return false
end

local function quitGame()
    -- 환경에 따라 되는 방법이 다를 수 있어 순서대로 시도합니다
    pcall(function() os.exit(0) end)
    pcall(function() runHaxeCode("Sys.exit(0);") end)
    pcall(function() runHaxeCode("import lime.system.System; System.exit(0);") end)
end

-- 아스카 치트 방지 목소리(VOICE_VOLUME 으로 구분)만 빼고 모든 소리를 끔
-- 노래·보컬·컷씬 음성·말소리 효과음·메뉴 효과음 등 재생 중인 소리 전부
local function silenceAllExceptCheat()
    pcall(function()
        runHaxeCode([[
            for (s in FlxG.sound.list.members) {
                if (s != null && s.playing && Math.abs(s.volume - ]] .. VOICE_VOLUME .. [[) > 0.00005) s.stop();
            }
            if (FlxG.sound.music != null) FlxG.sound.music.pause();
        ]])
    end)
end
local silenceTimer = 0

-- 대사 출력(컷씬 대화창·타이핑, 생일 입력 창 글자)을 전부 숨기고 진행 타이머/트윈을 취소
local DIALOGUE_TAGS = {'dlgDim', 'dlgBox', 'dlgNameBox', 'dlgName', 'dlgText', 'dlgHint',
    'inDim', 'inPanelB', 'inPanel', 'inTitle', 'inSub', 'inBox1', 'inBox2', 'inBox3', 'inBox4',
    'inDigit1', 'inDigit2', 'inDigit3', 'inDigit4', 'inStatus', 'inHint'}
local DIALOGUE_TIMERS = {'dlgStart', 'dlgType', 'dlgGo', 'partyGo', 'partyStart', 'inReset'}

local function hideDialogue()
    for _, t in ipairs(DIALOGUE_TIMERS) do pcall(function() cancelTimer(t) end) end
    for _, t in ipairs(DIALOGUE_TAGS) do
        if luaSpriteExists(t) or luaTextExists(t) then
            pcall(function() cancelTween(t .. 'In') end)
            pcall(function() cancelTween(t .. 'Out') end)
            pcall(function() setProperty(t .. '.alpha', 0) end)
        end
    end
end

local function stopCutsceneVoice()
    -- 컷씬 대사 음성·말소리 중단 (story_cutscene.lua 의 onCheatStart 도 함께 호출)
    pcall(function() stopSound('cutVoice') end)
    pcall(function() cancelTimer('dlgType') end)
    pcall(function() callOnLuas('onCheatStart', {}) end)
end

local function pauseSong()
    -- 1) 게임 진행(노트 이동·박자)을 멈춤: PlayState 의 paused 가 true 면 Conductor 시간이 흐르지 않음
    pcall(function() setProperty('paused', true) end)
    -- 2) 노래 음원(반주·보컬)을 일시정지
    pcall(function()
        runHaxeCode([[
            if (FlxG.sound.music != null) FlxG.sound.music.pause();
            if (game.vocals != null) game.vocals.pause();
            if (game.opponentVocals != null) game.opponentVocals.pause();
        ]])
    end)
    -- 3) 혹시 위 방법이 막혀 있어도 소리는 나지 않게 볼륨 0
    pcall(function() setPropertyFromClass('flixel.FlxG', 'sound.music.volume', 0) end)
    pcall(function() setProperty('vocals.volume', 0) end)
end

local function makeBox(tag, w, h, color, x, y, alpha)
    makeLuaSprite(tag, '', x, y)
    makeGraphic(tag, w, h, color)
    setProperty(tag .. '.alpha', alpha)
    setObjectCamera(tag, 'other')
    addLuaSprite(tag, true)
end

-- 다른 창(2차 인증 창 등)보다 항상 위에 보이도록, 가장 위쪽 전용 카메라를 만들어 아스카 화면을 옮김
local CHEAT_TAGS = {'cheatDim', 'cheatAsuka', 'cheatBubbleBorder', 'cheatBubble', 'cheatText', 'cheatCount'}
local topTimer = 0

local function assignTopCamera()
    local list = ''
    for i, t in ipairs(CHEAT_TAGS) do list = list .. (i > 1 and ',' or '') .. "'" .. t .. "'" end
    pcall(function()
        runHaxeCode([[
            var cam = new FlxCamera();
            cam.bgColor = 0x00000000;
            cam.zoom = 1.0001;
            FlxG.cameras.add(cam, false);
            for (t in []] .. list .. [[]) {
                var o = game.getLuaObject(t);
                if (o != null) o.cameras = [cam];
            }
        ]])
    end)
end

local function keepOnTop()
    pcall(function()
        runHaxeCode([[
            for (c in FlxG.cameras.list) {
                if (c.zoom > 1.00005 && c.zoom < 1.00015) {
                    FlxG.cameras.remove(c, false);
                    FlxG.cameras.add(c, false);
                    break;
                }
            }
        ]])
    end)
end

local function triggerCheat()
    triggered = true
    setProperty('canPause', false)

    -- 컷씬 음성 중단 + 대사 출력 숨김
    stopCutsceneVoice()
    hideDialogue()

    -- 노래 일시정지
    if PAUSE_SONG then pauseSong() end

    -- 아스카 목소리 외 모든 소리 끄기 → 그 다음 아스카 목소리 재생
    silenceAllExceptCheat()
    pcall(function() playSound(VOICE_SOUND, VOICE_VOLUME, 'cheatVoice') end)

    -- 화면 어둡게
    makeBox('cheatDim', 1280, 720, '000000', 0, 0, 0)
    doTweenAlpha('cheatDimIn', 'cheatDim', 0.8, 0.25, 'quadOut')

    -- 아스카 등장 (왼쪽에서 올라옴)
    makeAnimatedLuaSprite('cheatAsuka', 'characters/asuka', 120, 140)
    addAnimationByPrefix('cheatAsuka', 'idle', 'idle', 6, true)
    objectPlayAnimation('cheatAsuka', 'idle', true)
    scaleObject('cheatAsuka', 1.45, 1.45)
    setProperty('cheatAsuka.alpha', 0)
    setObjectCamera('cheatAsuka', 'other')
    addLuaSprite('cheatAsuka', true)
    doTweenAlpha('cheatAsukaA', 'cheatAsuka', 1, 0.3, 'quadOut')
    doTweenY('cheatAsukaY', 'cheatAsuka', 50, 0.35, 'backOut')

    -- 말풍선
    makeBox('cheatBubbleBorder', 676, 296, '000000', 552, 156, 0)
    makeBox('cheatBubble', 664, 284, 'FFFFFF', 558, 162, 0)
    doTweenAlpha('cheatBubbleBorderA', 'cheatBubbleBorder', 1, 0.3, 'quadOut')
    doTweenAlpha('cheatBubbleA', 'cheatBubble', 1, 0.3, 'quadOut')

    local msg = '안타 바카?! 감히 내 파일을 조작하려 들다니, 한심하긴!'
    makeLuaText('cheatText', msg, 630, 575, 190)
    setTextFont('cheatText', FONT)
    setTextSize('cheatText', 36)
    setTextColor('cheatText', '000000')
    setTextAlignment('cheatText', 'left')
    setObjectCamera('cheatText', 'other')
    addLuaText('cheatText')

    makeLuaText('cheatCount', QUIT_SECONDS .. '초 뒤에 게임이 종료됩니다', 630, 575, 380)
    setTextFont('cheatCount', FONT)
    setTextSize('cheatCount', 28)
    setTextColor('cheatCount', 'D61C24')
    setTextAlignment('cheatCount', 'left')
    setObjectCamera('cheatCount', 'other')
    addLuaText('cheatCount')

    assignTopCamera()
    runTimer('cheatQuit', 1, QUIT_SECONDS)
end

-- 치트가 처음부터 켜져 있으면 카운트다운·노래 시작 자체를 막고 아스카를 먼저 띄움
-- (카운트다운이 끝나면 노래가 새로 재생되므로, 시작 전에 막지 않으면 노래가 아스카 창과 함께 켜짐)
function onStartCountdown()
    if ENABLED and isCheating() then
        if not triggered then triggerCheat() end
        return Function_Stop
    end
    return Function_Continue
end

-- 혹시 노래가 시작돼 버렸다면 다시 멈춤
function onSongStart()
    if triggered and PAUSE_SONG then pauseSong() end
end

function onUpdatePost(elapsed)
    if ENABLED and not triggered and isCheating() then
        triggerCheat()
    end
    if triggered then
        silenceTimer = silenceTimer + elapsed
        if silenceTimer > 0.05 then silenceTimer = 0; silenceAllExceptCheat(); hideDialogue() end   -- 새로 나는 소리·대사도 계속 끔
        topTimer = topTimer + elapsed
        if topTimer > 0.2 then topTimer = 0; keepOnTop() end   -- 0.2초마다 맨 위로 다시 올림
    end
end

function onTimerCompleted(tag, loops, loopsLeft)
    if tag == 'cheatQuit' then
        if loopsLeft <= 0 then
            quitGame()
        else
            setTextString('cheatCount', loopsLeft .. '초 뒤에 게임이 종료됩니다')
        end
    end
end
