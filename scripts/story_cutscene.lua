-- 스토리 모드 첫 곡(Piano Duet / Anta Baka / Unit Zero) 시작 전 한글 컷씬
-- Enter/Space: 다음 대사 (타자 중이면 한 번에 표시)   ESC: 건너뛰기
-- 대사 음성: sounds/cutscene/<곡이름>_<번호>.ogg 가 있으면 그 음성을 읽어 주고,
--            없으면 캐릭터별 말소리 효과음(babble)이 재생됩니다. (tools/make_cutscene_voice.py 로 음성 생성)
local FONT = 'NotoSansKR-Medium.otf'

local sets = {}
sets['piano duet'] = {
    {'kaoru',  '안녕, 신지 군. 이런 곳에서 만나다니 신기하네.'},
    {'shinji', '카오루 군…? 여긴 어떻게 알고 왔어?'},
    {'kaoru',  '노랫소리가 들렸거든. 네 노래는 듣고 있으면 마음이 편해져.'},
    {'shinji', '내 노래가…? 난 그냥 다 잊고 싶어서 부른 건데.'},
    {'kaoru',  '그래도 괜찮아. 하지만 오늘만큼은 나랑 같이 불러 주지 않을래?'},
    {'shinji', '같이…? 난 잘 못 하는데… 박자도 자꾸 틀리고.'},
    {'kaoru',  '틀려도 돼. 박자가 어긋나도 마음이 닿으면, 그게 노래니까.'},
    {'shinji', '……알았어. 딱 한 곡만이야.'},
    {'kaoru',  '고마워. 그럼 가볍게 시작해 볼까? 첫 곡은 피아노 듀엣이야.'},
    {'shinji', '좋아. 마이크 잡았어… 해 볼게!'},
}

sets['anta baka'] = {
    {'asuka',  '거기 너, 바보 신지! 어디 가는 거야?'},
    {'shinji', '아, 아스카… 그냥 산책 중이었는데.'},
    {'asuka',  '산책? 한가해 보이네. 마침 잘됐다, 나랑 노래 대결 어때?'},
    {'shinji', '노래 대결…? 난 그런 거 못 해.'},
    {'asuka',  '해 보기도 전에 포기부터 해? 너 바보야?'},
    {'shinji', '……알았어. 딱 한 번만 해 볼게.'},
    {'asuka',  '흥, 진작 그럴 것이지. 이 천재 아스카 님의 노래를 똑똑히 들어 두라고!'},
    {'shinji', '왠지 부담스럽네… 그래도 도망치진 않을 거야.'},
    {'asuka',  '좋아, 그 기세야. 시작한다!'},
}
sets['unit zero'] = {
    {'rei',    '……안녕, 이카리 군.'},
    {'shinji', '아야나미…? 여긴 어쩐 일이야?'},
    {'rei',    '노랫소리가 들렸어. 그 소리가… 따뜻했어.'},
    {'shinji', '그, 그냥 아무것도 아니야. 부끄럽게 만들지 말아 줘.'},
    {'rei',    '부끄러운 거야? 잘 모르겠어. 하지만… 더 듣고 싶어.'},
    {'shinji', '……그럼 같이 부를래?'},
    {'rei',    '같이… 응. 해 볼게.'},
}
local lines = {}

local names  = { kaoru = '카오루', shinji = '신지', asuka = '아스카', rei = '레이' }
local colors = { kaoru = 'B8B0E8', shinji = 'D08A7A', asuka = 'E8604C', rei = '9CC8F0' }

local built, active, allow = false, false, false
local idx, shown, typing = 0, 0, false
local currentKey, curWho, usingVoice = '', '', false
local chars = {}

local function splitChars(s)
    local t = {}
    for c in string.gmatch(s, '[%z\1-\127\194-\244][\128-\191]*') do t[#t + 1] = c end
    return t
end

local function buildUI()
    if built then return end
    built = true
    makeLuaSprite('dlgDim', '', 0, 0)
    makeGraphic('dlgDim', 1280, 720, '000000')
    setObjectCamera('dlgDim', 'camOther')
    setProperty('dlgDim.alpha', 0)
    addLuaSprite('dlgDim', true)

    makeLuaSprite('dlgBox', '', 80, 470)
    makeGraphic('dlgBox', 1120, 190, '12102A')
    setObjectCamera('dlgBox', 'camOther')
    setProperty('dlgBox.alpha', 0)
    addLuaSprite('dlgBox', true)

    makeLuaSprite('dlgNameBox', '', 100, 436)
    makeGraphic('dlgNameBox', 190, 48, '5B4FA8')
    setObjectCamera('dlgNameBox', 'camOther')
    setProperty('dlgNameBox.alpha', 0)
    addLuaSprite('dlgNameBox', true)

    makeLuaText('dlgName', '', 190, 100, 443)
    setTextFont('dlgName', FONT)
    setTextSize('dlgName', 28)
    setTextAlignment('dlgName', 'center')
    setObjectCamera('dlgName', 'camOther')
    setProperty('dlgName.alpha', 0)
    addLuaText('dlgName')

    makeLuaText('dlgText', '', 1040, 120, 505)
    setTextFont('dlgText', FONT)
    setTextSize('dlgText', 32)
    setTextAlignment('dlgText', 'left')
    setObjectCamera('dlgText', 'camOther')
    setProperty('dlgText.alpha', 0)
    addLuaText('dlgText')

    makeLuaText('dlgHint', 'Enter 다음   ESC 건너뛰기', 400, 780, 625)
    setTextFont('dlgHint', FONT)
    setTextSize('dlgHint', 20)
    setTextColor('dlgHint', '9A94C0')
    setTextAlignment('dlgHint', 'right')
    setObjectCamera('dlgHint', 'camOther')
    setProperty('dlgHint.alpha', 0)
    addLuaText('dlgHint')
end

local function showLine(i)
    idx = i
    local who, text = lines[i][1], lines[i][2]
    setTextString('dlgName', names[who])
    setProperty('dlgNameBox.color', getColorFromHex(colors[who]))
    setTextString('dlgText', '')
    cameraSetTarget(who == 'shinji' and 'boyfriend' or 'dad')
    chars = splitChars(text)
    shown, typing = 0, true
    curWho = who
    stopSound('cutVoice')
    local key = currentKey .. '_' .. i
    if checkFileExists('sounds/cutscene/' .. key .. '.ogg') then
        usingVoice = true
        playSound('cutscene/' .. key, 1, 'cutVoice')
    else
        usingVoice = false
    end
    runTimer('dlgType', 0.035, #chars)
end

local function finishLine()
    cancelTimer('dlgType')
    typing = false
    shown = #chars
    setTextString('dlgText', table.concat(chars))
end

local function endCutscene()
    if not active then return end
    active = false
    cancelTimer('dlgType')
    stopSound('cutVoice')
    for _, tag in ipairs({'dlgDim', 'dlgBox', 'dlgNameBox', 'dlgName', 'dlgText', 'dlgHint'}) do
        doTweenAlpha(tag .. 'Out', tag, 0, 0.5, 'quadOut')
    end
    setProperty('camHUD.alpha', 1)
    allow = true
    runTimer('dlgGo', 0.55)
end

function onStartCountdown()
    if not allow and isStoryMode and not seenCutscene and sets[string.lower(songName)] ~= nil then
        lines = sets[string.lower(songName)]
        currentKey = string.gsub(string.lower(songName), ' ', '-')
        math.randomseed(os.time())
        buildUI()
        active = true
        setProperty('camHUD.alpha', 0)
        doTweenAlpha('dlgDimIn', 'dlgDim', 0.35, 0.6, 'quadOut')
        doTweenAlpha('dlgBoxIn', 'dlgBox', 0.88, 0.6, 'quadOut')
        doTweenAlpha('dlgNameBoxIn', 'dlgNameBox', 1, 0.6, 'quadOut')
        doTweenAlpha('dlgNameIn', 'dlgName', 1, 0.6, 'quadOut')
        doTweenAlpha('dlgTextIn', 'dlgText', 1, 0.6, 'quadOut')
        doTweenAlpha('dlgHintIn', 'dlgHint', 1, 0.6, 'quadOut')
        runTimer('dlgStart', 0.8)
        return Function_Stop
    end
    return Function_Continue
end

function onTimerCompleted(tag, loops, loopsLeft)
    if tag == 'dlgStart' then
        showLine(1)
    elseif tag == 'dlgType' then
        shown = shown + 1
        local t = {}
        for k = 1, shown do t[k] = chars[k] end
        setTextString('dlgText', table.concat(t))
        if not usingVoice and shown % 2 == 1 and chars[shown] ~= ' ' then
            playSound('cutscene/babble_' .. curWho .. '_' .. math.random(1, 4), 0.45)
        end
        if shown >= #chars then typing = false end
    elseif tag == 'dlgGo' then
        setProperty('inCutscene', false)
        startCountdown()
    end
end

function onUpdate(elapsed)
    if not active or idx == 0 then return end
    if keyJustPressed('back') then
        endCutscene()
    elseif keyJustPressed('accept') then
        if typing then
            finishLine()
        elseif idx < #lines then
            showLine(idx + 1)
        else
            endCutscene()
        end
    end
end

-- 컷씬 도중 ESC로 일시정지 창이 뜨지 않게 막음
function onPause()
    if active then return Function_Stop end
    return Function_Continue
end

-- 치트 스크립트(cheat_asuka.lua)가 호출: 컷씬 음성·타이핑·진행을 즉시 중단
function onCheatStart()
    if not active then return end
    active = false
    cancelTimer('dlgStart')
    cancelTimer('dlgType')
    cancelTimer('dlgGo')
    stopSound('cutVoice')
    for _, tag in ipairs({'dlgDim', 'dlgBox', 'dlgNameBox', 'dlgName', 'dlgText', 'dlgHint'}) do
        setProperty(tag .. '.alpha', 0)
    end
end
