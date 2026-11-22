-- 타브리스 스테이지: 붉은 밤
function onCreate()
    makeLuaSprite('sky', 'stages/lclnight/sky', -660, -420)
    setScrollFactor('sky', 0.15, 0.15)
    addLuaSprite('sky', false)

    makeLuaSprite('cross', 'stages/lclnight/cross', 380, -140)
    setScrollFactor('cross', 0.25, 0.25)
    addLuaSprite('cross', false)

    makeLuaSprite('city', 'stages/lclnight/city', -660, 120)
    setScrollFactor('city', 0.5, 0.5)
    addLuaSprite('city', false)

    makeLuaSprite('floor', 'stages/lclnight/floor', -660, 560)
    addLuaSprite('floor', false)
end

-- 비트마다 십자가 빛이 살짝 번쩍임
function onBeatHit()
    if curBeat % 2 == 0 then
        setProperty('cross.alpha', 1)
        doTweenAlpha('crossPulse', 'cross', 0.55, 0.45, 'quadOut')
    end
end
