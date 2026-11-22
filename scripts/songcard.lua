-- 곡 시작 시 제목 카드
local cards = {
    ['piano-duet'] = {'Piano Duet', 'Shinji Ikari  &  Kaoru Nagisa'},
    ['daiku']      = {'Daiku',      'Shinji Ikari  &  Kaoru Nagisa'},
    ['tabris']     = {'Tabris',     'Shinji Ikari  vs  Kaoru Nagisa'},
    ['anta-baka']  = {'Anta Baka',  'Shinji Ikari  &  Asuka Langley'},
    ['hedgehog-dilemma'] = {'Hedgehog Dilemma', 'Shinji Ikari  &  Asuka Langley'},
    ['sortie']     = {'Sortie',     'Shinji Ikari  vs  Asuka Langley'},
    ['unit-zero']  = {'Unit Zero',  'Shinji Ikari  &  Rei Ayanami'},
    ['smile']      = {'Smile',      'Shinji Ikari  &  Rei Ayanami'},
    ['blue-moon']  = {'Blue Moon',  'Shinji Ikari  vs  Rei Ayanami'},
    ['birthday-party'] = {'Birthday Party', 'Happy Birthday, Kaoru!'},
}

function onCreatePost()
    local slug = string.lower(songName):gsub(' ', '-')
    local c = cards[slug]
    if c == nil then return end
    makeLuaText('cardTitle', c[1], 900, 190, 250)
    setTextSize('cardTitle', 64)
    setTextAlignment('cardTitle', 'center')
    setObjectCamera('cardTitle', 'camOther')
    setProperty('cardTitle.alpha', 0)
    addLuaText('cardTitle')

    makeLuaText('cardSub', c[2], 900, 190, 335)
    setTextSize('cardSub', 28)
    setTextAlignment('cardSub', 'center')
    setTextColor('cardSub', 'C8C0E0')
    setObjectCamera('cardSub', 'camOther')
    setProperty('cardSub.alpha', 0)
    addLuaText('cardSub')
end

function onSongStart()
    doTweenAlpha('cardTitleIn', 'cardTitle', 1, 0.7, 'quadOut')
    doTweenAlpha('cardSubIn', 'cardSub', 1, 0.7, 'quadOut')
    runTimer('cardOut', 3.2)
end

function onTimerCompleted(tag)
    if tag == 'cardOut' then
        doTweenAlpha('cardTitleOut', 'cardTitle', 0, 1.0, 'quadIn')
        doTweenAlpha('cardSubOut', 'cardSub', 0, 1.0, 'quadIn')
    end
end
