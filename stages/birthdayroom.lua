-- 카오루 생일 파티 스테이지
-- 구성: 풍선·현수막이 걸린 방, 앞쪽 케이크 테이블, 가운데 카오루(gf 자리), 신지(플레이어),
--       아스카(상대) + 레이(스크립트로 추가한 보조 가수), 시작 전 생일 입력 전용 창
local FONT = 'NotoSansKR-Medium.otf'
local BLOW_MS = 43444
local BALLOONS = {
    {x=40, y=60, c='red', s=1.0},
    {x=130, y=20, c='blue', s=1.1},
    {x=210, y=90, c='yellow', s=0.9},
    {x=90, y=170, c='pink', s=1.0},
    {x=180, y=200, c='mint', s=0.85},
    {x=1130, y=40, c='purple', s=1.0},
    {x=1230, y=100, c='red', s=1.1},
    {x=1330, y=50, c='yellow', s=0.95},
    {x=1180, y=190, c='blue', s=0.9},
    {x=1290, y=210, c='pink', s=1.0},
}
local REI_SCALE = 0.4
local CANDLES = {205, 243, 280, 317, 355}

local balloons, confetti, flames = {}, {}, {}
local inputActive, allow, typed = false, false, ''
local partyT, blown, boost = 0, false, 1
local reiHold, reiSinging = 0, false
local reiAnims = {'singLEFT', 'singDOWN', 'singUP', 'singRIGHT'}
local digitKeys = {
    ZERO='0', ONE='1', TWO='2', THREE='3', FOUR='4', FIVE='5', SIX='6', SEVEN='7', EIGHT='8', NINE='9',
    NUMPADZERO='0', NUMPADONE='1', NUMPADTWO='2', NUMPADTHREE='3', NUMPADFOUR='4',
    NUMPADFIVE='5', NUMPADSIX='6', NUMPADSEVEN='7', NUMPADEIGHT='8', NUMPADNINE='9'
}
local digitOrder = {'ZERO','ONE','TWO','THREE','FOUR','FIVE','SIX','SEVEN','EIGHT','NINE',
    'NUMPADZERO','NUMPADONE','NUMPADTWO','NUMPADTHREE','NUMPADFOUR','NUMPADFIVE','NUMPADSIX','NUMPADSEVEN','NUMPADEIGHT','NUMPADNINE'}
local uiTags = {}
local cheatStopped = false   -- cheat_asuka.lua 가 치트를 감지하면 true

function onCreate()
    math.randomseed(os.time())
    makeLuaSprite('wall', 'stages/birthdayroom/wall', -260, -140)
    addLuaSprite('wall', false)
    makeLuaSprite('floor', 'stages/birthdayroom/floor', -260, 590)
    addLuaSprite('floor', false)
    makeLuaSprite('banner', 'stages/birthdayroom/banner', -160, -10)
    addLuaSprite('banner', false)

    for i, b in ipairs(BALLOONS) do
        local tag = 'balloon' .. i
        makeLuaSprite(tag, 'stages/birthdayroom/balloon_' .. b.c, b.x, b.y)
        scaleObject(tag, b.s, b.s)
        addLuaSprite(tag, false)
        balloons[i] = {tag = tag, y = b.y, ph = i * 0.9}
    end

    -- 보조 가수 레이 (상대 노트에 맞춰 노래함)
    -- rei.png 프레임이 518x1083 원본 크기라 characters/rei.json 의 scale(0.4)과 똑같이 줄여야 다른 캐릭터와 크기가 맞음
    makeAnimatedLuaSprite('rei', 'characters/rei', 102, 217)
    scaleObject('rei', REI_SCALE, REI_SCALE)
    addAnimationByPrefix('rei', 'idle', 'idle', 12, false)
    for _, a in ipairs(reiAnims) do addAnimationByPrefix('rei', a, a, 12, false) end
    addLuaSprite('rei', false)
    objectPlayAnimation('rei', 'idle', true)

    -- 앞쪽 케이크 테이블 + 촛불
    makeLuaSprite('table', 'stages/birthdayroom/table_cake', 360, 390)
    addLuaSprite('table', true)
    for i, cx in ipairs(CANDLES) do
        local tag = 'flame' .. i
        makeLuaSprite(tag, 'stages/birthdayroom/flame', 360 + cx - 20, 390 + 6 - 58)
        addLuaSprite(tag, true)
        flames[i] = {tag = tag, ph = i * 1.7}
    end

    -- 색종이
    local colors = {'FFD9A8', 'B8B0E8', 'FF8FA3', '8FD3FF', 'FFF29A', '9BE3C0'}
    for i = 1, 30 do
        local tag = 'confetti' .. i
        makeLuaSprite(tag, '', math.random(-120, 1400), math.random(-200, 700))
        makeGraphic(tag, 8, 12, colors[(i % #colors) + 1])
        addLuaSprite(tag, true)
        confetti[i] = {tag = tag, x = getProperty(tag .. '.x'), y = getProperty(tag .. '.y'),
                       v = math.random(50, 120), ph = math.random() * 6, spin = math.random(-200, 200)}
    end
end

------------------------------------------------------------------ 입력 전용 창
local function slotUpdate()
    for i = 1, 4 do
        local ch = string.sub(typed, i, i)
        setTextString('inDigit' .. i, ch)
        setProperty('inBox' .. i .. '.color', getColorFromHex((i == #typed + 1) and '5B4FA8' or '2D2766'))
    end
end

local function buildWindow()
    local function reg(tag) uiTags[#uiTags + 1] = tag end
    makeLuaSprite('inDim', '', 0, 0); makeGraphic('inDim', 1280, 720, '0B0920')
    setObjectCamera('inDim', 'camOther'); setProperty('inDim.alpha', 0.88); addLuaSprite('inDim', true); reg('inDim')
    makeLuaSprite('inPanelB', '', 370, 230); makeGraphic('inPanelB', 540, 260, '8F82F0')
    setObjectCamera('inPanelB', 'camOther'); addLuaSprite('inPanelB', true); reg('inPanelB')
    makeLuaSprite('inPanel', '', 376, 236); makeGraphic('inPanel', 528, 248, '1B1738')
    setObjectCamera('inPanel', 'camOther'); addLuaSprite('inPanel', true); reg('inPanel')

    local function txt(tag, str, w, x, y, size, color)
        makeLuaText(tag, str, w, x, y)
        setTextFont(tag, FONT); setTextSize(tag, size); setTextAlignment(tag, 'center'); setTextColor(tag, color)
        setObjectCamera(tag, 'camOther'); addLuaText(tag); reg(tag)
    end
    txt('inTitle', '카오루의 생일을 입력하세요', 540, 370, 252, 30, 'FFFFFF')
    txt('inSub', '월일 네 자리 숫자', 540, 370, 296, 18, 'B8B0E8')
    for i = 1, 4 do
        local x = 499 + (i - 1) * 74
        makeLuaSprite('inBox' .. i, '', x, 335); makeGraphic('inBox' .. i, 60, 76, 'FFFFFF')
        setProperty('inBox' .. i .. '.color', getColorFromHex('2D2766'))
        setObjectCamera('inBox' .. i, 'camOther'); addLuaSprite('inBox' .. i, true); reg('inBox' .. i)
        txt('inDigit' .. i, '', 60, x, 343, 46, 'FFFFFF')
    end
    txt('inStatus', '', 540, 370, 424, 20, 'FFD9A8')
    txt('inHint', 'Backspace 지우기      ESC 나가기', 540, 370, 458, 16, '9A94C0')
    slotUpdate()
end

local function closeWindow()
    for _, tag in ipairs(uiTags) do doTweenAlpha(tag .. 'Out', tag, 0, 0.6, 'quadOut') end
end

function onStartCountdown()
    if cheatStopped then return Function_Stop end   -- 치트 중이면 생일 입력 창을 띄우지 않음
    if not allow then
        buildWindow()
        inputActive = true
        setProperty('camHUD.alpha', 0)
        return Function_Stop
    end
    return Function_Continue
end

local function checkCode()
    if typed == '0913' then
        inputActive = false
        setTextString('inStatus', '생일 축하해, 카오루!')
        playSound('confirmMenu')
        cameraFlash('camOther', 'FFFFFF', 0.6)
        runTimer('partyGo', 0.9)
    else
        setTextString('inStatus', '다시 입력해 주세요')
        setTextColor('inStatus', 'FF8A8A')
        playSound('cancelMenu')
        cameraShake('camOther', 0.012, 0.25)
        typed = ''
        runTimer('inReset', 0.7)
    end
end

function onTimerCompleted(tag, loops, loopsLeft)
    if tag == 'partyGo' then
        closeWindow()
        setProperty('camHUD.alpha', 1)
        allow = true
        runTimer('partyStart', 0.7)
    elseif tag == 'partyStart' then
        startCountdown()
    elseif tag == 'inReset' then
        setTextString('inStatus', '')
        setTextColor('inStatus', 'FFD9A8')
        slotUpdate()
    end
end

function onPause()
    if inputActive then return Function_Stop end
    return Function_Continue
end

-- 치트 스크립트(cheat_asuka.lua)가 호출: 생일 입력 창을 닫고 입력·진행을 막음
function onCheatStart()
    cheatStopped = true
    inputActive = false
    for _, tag in ipairs(uiTags) do setProperty(tag .. '.alpha', 0) end
    cancelTimer('partyGo'); cancelTimer('partyStart'); cancelTimer('inReset')
end

------------------------------------------------------------------ 파티 연출
function onMoveCamera(focus)
    setProperty('camFollow.x', 640)
    setProperty('camFollow.y', 350)
end

function opponentNoteHit(id, direction, noteType, isSustainNote)
    objectPlayAnimation('rei', reiAnims[direction + 1], true)
    reiHold = 0.45
    reiSinging = true
end

function onBeatHit()
    if not reiSinging and curBeat % 2 == 0 then objectPlayAnimation('rei', 'idle', true) end
end

-- 카운트다운(레디·세트·고) 중에는 엔진이 onBeatHit 을 호출하지 않아서 레이가 멈춰 있었음
-- → 카운트다운 틱마다 idle 을 재생해 노래 중과 같은 박자(2틱마다)로 움직이게 함
function onCountdownTick(counter)
    if not reiSinging and counter % 2 == 0 then objectPlayAnimation('rei', 'idle', true) end
end

function onUpdate(elapsed)
    partyT = partyT + elapsed

    if inputActive then
        if keyboardJustPressed('ESCAPE') then
            playSound('cancelMenu')
            exitSong(false)
            return
        end
        if keyboardJustPressed('BACKSPACE') and #typed > 0 then
            typed = string.sub(typed, 1, #typed - 1)
            slotUpdate()
        end
        if #typed < 4 then
            for _, name in ipairs(digitOrder) do
                if keyboardJustPressed(name) then
                    typed = typed .. digitKeys[name]
                    playSound('scrollMenu')
                    slotUpdate()
                    break
                end
            end
        end
        if #typed == 4 and (keyboardJustPressed('ENTER') or true) then checkCode() end
    end

    for _, b in ipairs(balloons) do
        setProperty(b.tag .. '.y', b.y + math.sin(partyT * 1.1 + b.ph) * 10)
    end
    for _, c in ipairs(confetti) do
        c.y = c.y + c.v * boost * elapsed
        if c.y > 780 then c.y = -40; c.x = math.random(-120, 1400) end
        setProperty(c.tag .. '.y', c.y)
        setProperty(c.tag .. '.x', c.x + math.sin(partyT * 1.5 + c.ph) * 24)
        setProperty(c.tag .. '.angle', partyT * c.spin)
    end
    if not blown then
        for _, f in ipairs(flames) do
            local s = 1 + 0.12 * math.sin(partyT * 11 + f.ph)
            setProperty(f.tag .. '.scale.x', 1 / s)
            setProperty(f.tag .. '.scale.y', s)
        end
        if getSongPosition() >= BLOW_MS then
            blown = true
            for _, f in ipairs(flames) do doTweenAlpha(f.tag .. 'Out', f.tag, 0, 0.35, 'quadOut') end
            characterPlayAnim('gf', 'singUP', true)
            cameraFlash('camGame', 'FFFFFF', 0.5)
            boost = 3
        end
    end

    if reiSinging then
        reiHold = reiHold - elapsed
        if reiHold <= 0 then
            reiSinging = false
            objectPlayAnimation('rei', 'idle', true)
        end
    end
end
