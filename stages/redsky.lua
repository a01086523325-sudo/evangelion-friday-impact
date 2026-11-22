-- 붉은 석양 옥상 스테이지
function onCreate()
    makeLuaSprite('sky', 'stages/redsky/sky', -660, -420)
    setScrollFactor('sky', 0.15, 0.15)
    addLuaSprite('sky', false)

    makeLuaSprite('cityFar', 'stages/redsky/city_far', -660, 90)
    setScrollFactor('cityFar', 0.35, 0.35)
    addLuaSprite('cityFar', false)

    makeLuaSprite('cityNear', 'stages/redsky/city_near', -660, 150)
    setScrollFactor('cityNear', 0.6, 0.6)
    addLuaSprite('cityNear', false)

    makeLuaSprite('floor', 'stages/redsky/floor', -660, 560)
    addLuaSprite('floor', false)

    makeLuaSprite('rail', 'stages/redsky/rail', -660, 470)
    setScrollFactor('rail', 0.9, 0.9)
    addLuaSprite('rail', false)
end
