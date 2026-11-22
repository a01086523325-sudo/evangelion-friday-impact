-- 체력바 아이콘 프레임 강제 지정 (3프레임: 0 기본 / 1 패배 / 2 승리)
-- 체력 퍼센트(healthBar.percent)는 플레이어(P1) 기준 0~100
--   P1: 20 미만이면 패배, 80 초과면 승리
--   P2: 80 초과면 패배(플레이어가 이기는 중), 20 미만이면 승리
local function frameFor(percent, isPlayer)
    local mine = isPlayer and percent or (100 - percent)
    if mine < 20 then return 1 end
    if mine > 80 then return 2 end
    return 0
end

function onUpdatePost(elapsed)
    local percent = getProperty('healthBar.percent')
    setProperty('iconP1.animation.curAnim.curFrame', frameFor(percent, true))
    setProperty('iconP2.animation.curAnim.curFrame', frameFor(percent, false))
end
