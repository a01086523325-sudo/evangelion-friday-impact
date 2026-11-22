local myScore = 0
local myMisses = 0
local myHits = 0
local totalNotes = 0
local fakeRating = 0
local fakeFC = 'Clear'

function onCreatePost()
    -- 원본 스코어 텍스트와 봇플레이 문구를 숨깁니다.
    setProperty('scoreTxt.visible', false)
    setProperty('botplayTxt.visible', false)

    -- 기존 scoreTxt의 위치, 가로폭, 크기, 정렬을 100% 똑같이 복사합니다.
    makeLuaText('fakeScoreHud', '', getProperty('scoreTxt.width'), getProperty('scoreTxt.x'), getProperty('scoreTxt.y'))
    setTextSize('fakeScoreHud', getProperty('scoreTxt.size'))
    setTextBorder('fakeScoreHud', 1.25, '000000')
    setTextAlignment('fakeScoreHud', 'center')
    setObjectCamera('fakeScoreHud', 'hud')
    
    -- 화면 렌더링 추가
    addLuaText('fakeScoreHud')
end

function goodNoteHit(id, noteData, noteType, isSustainNote)
    if botPlay then
        if not isSustainNote then
            myHits = myHits + 1
            totalNotes = totalNotes + 1
            myScore = myScore + 350
        else
            myScore = myScore + 20 -- 롱노트 점수
        end
    end
end

function noteMiss(id, noteData, noteType, isSustainNote)
    if botPlay then
        myMisses = myMisses + 1
        totalNotes = totalNotes + 1
        if myScore > 0 then myScore = myScore - 10 end
    end
end

function onUpdatePost(elapsed)
    -- 화면 위치 강제 고정 (노트가 밀려도 위치가 흔들리지 않게 고정)
    setProperty('fakeScoreHud.x', getProperty('scoreTxt.x'))
    setProperty('fakeScoreHud.y', getProperty('scoreTxt.y'))

    -- 실시간 정확도 % 계산
    if totalNotes > 0 then
        fakeRating = (myHits / totalNotes) * 100
    else
        fakeRating = 0
    end

    -- 실시간 콤보 등급(FC) 계산
    if myMisses == 0 and myHits > 0 then
        fakeFC = 'SFC'
    elseif myMisses < 10 and myHits > 0 then
        fakeFC = 'GFC'
    elseif myMisses >= 10 then
        fakeFC = 'Clear'
    else
        fakeFC = 'N/A'
    end

    -- 텍스트 기본 포맷
    local ratingString = '?'
    if totalNotes > 0 then
        ratingString = string.format("%.2f%%", fakeRating) .. ' [' .. fakeFC .. ']'
    end

    -- 출력 (기존 레이팅 자리로 덮어씌우기)
    setTextString('fakeScoreHud', 'Score: ' .. myScore .. ' | Misses: ' .. myMisses .. ' | Rating: ' .. ratingString)
end
