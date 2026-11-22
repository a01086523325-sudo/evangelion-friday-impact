// 카오루 생일 이스터에그
// 메인 메뉴에서 카오루의 생일(9월 13일 → 0913)을 키보드로 입력하면 생일 축하곡이 나옵니다.
// 인식하는 입력: 0913 / 20000913 (숫자열, 숫자패드 모두 가능)
// 노래 도중 ESC 또는 Backspace 를 누르면 멈추고 원래 메뉴 음악으로 돌아갑니다.

import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;

var typed:String = '';
var birthdayOn:Bool = false;
var codes:Array<String> = ['0913', '20000913'];
var shadowTxt:FlxText;
var mainTxt:FlxText;
var subTxt:FlxText;
var confetti:Array<FlxSprite> = [];

// 상단 검은색 바와 "카오루 생일 입력 (0913)" 안내 문구를 제어하기 위한 변수
var topBar:FlxSprite;
var topTxt:FlxText;

var initDelay:Float = 0.2; 

function onCreate()
{
    var font = Paths.font('NotoSansKR-Medium.otf');

    // [추가] 시작하자마자 뜨던 상단 검은색 배경 바 객체 생성 및 숨김(alpha = 0)
    topBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 60, 0xAA000000);
    topBar.scrollFactor.set();
    topBar.alpha = 0; 
    add(topBar);

    // [추가] 시작하자마자 뜨던 상단 안내 문구 객체 생성 및 숨김(alpha = 0)
    topTxt = new FlxText(0, 15, FlxG.width, '카오루 생일 입력 (0913)', 24);
    topTxt.setFormat(font, 24, 0xFFFFFFFF, 'center');
    topTxt.scrollFactor.set();
    topTxt.alpha = 0;
    add(topTxt);

    shadowTxt = new FlxText(3, 233, FlxG.width, 'Happy Birthday, Kaoru!', 56);
    shadowTxt.setFormat(font, 56, 0xFF000000, 'center');
    shadowTxt.scrollFactor.set();
    shadowTxt.alpha = 0;
    add(shadowTxt);

    mainTxt = new FlxText(0, 230, FlxG.width, 'Happy Birthday, Kaoru!', 56);
    mainTxt.setFormat(font, 56, 0xFFE8E4FF, 'center');
    mainTxt.scrollFactor.set();
    mainTxt.alpha = 0;
    add(mainTxt);

    subTxt = new FlxText(0, 305, FlxG.width, '카오루, 생일 축하해!   Freeplay > Birthday Party', 32);
    subTxt.setFormat(font, 32, 0xFFFFD9A8, 'center');
    subTxt.scrollFactor.set();
    subTxt.alpha = 0;
    add(subTxt);
}

function onUpdate(elapsed:Float)
{
    if (initDelay > 0) {
        initDelay -= elapsed;
        return;
    }

    if (birthdayOn)
    {
        if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE)
            stopBirthday();
        return;
    }

    if (FlxG.keys.justPressed.ANY)
    {
        var d:Int = -1;

        if (FlxG.keys.justPressed.ZERO) d = 0;
        else if (FlxG.keys.justPressed.ONE) d = 1;
        else if (FlxG.keys.justPressed.TWO) d = 2;
        else if (FlxG.keys.justPressed.THREE) d = 3;
        else if (FlxG.keys.justPressed.FOUR) d = 4;
        else if (FlxG.keys.justPressed.FIVE) d = 5;
        else if (FlxG.keys.justPressed.SIX) d = 6;
        else if (FlxG.keys.justPressed.SEVEN) d = 7;
        else if (FlxG.keys.justPressed.EIGHT) d = 8;
        else if (FlxG.keys.justPressed.NINE) d = 9;
        
        else if (FlxG.keys.justPressed.NUMPADZERO) d = 0;
        else if (FlxG.keys.justPressed.NUMPADONE) d = 1;
        else if (FlxG.keys.justPressed.NUMPADTWO) d = 2;
        else if (FlxG.keys.justPressed.NUMPADTHREE) d = 3;
        else if (FlxG.keys.justPressed.NUMPADFOUR) d = 4;
        else if (FlxG.keys.justPressed.NUMPADFIVE) d = 5;
        else if (FlxG.keys.justPressed.NUMPADSIX) d = 6;
        else if (FlxG.keys.justPressed.NUMPADSEVEN) d = 7;
        else if (FlxG.keys.justPressed.NUMPADEIGHT) d = 8;
        else if (FlxG.keys.justPressed.NUMPADNINE) d = 9;

        if (d < 0) {
            typed = '';
            return;
        }

        typed += Std.string(d);
        if (typed.length > 8) {
            typed = typed.substr(typed.length - 8);
        }

        for (c in codes)
        {
            if (StringTools.endsWith(typed, c))
            {
                startBirthday();
                break;
            }
        }
    }
}

function startBirthday()
{
    birthdayOn = true;
    typed = '';
    
    FlxG.sound.playMusic(Paths.music('kaoruBirthday'), 0.9, false);
    FlxG.sound.music.onComplete = stopBirthday;

    // [수정] 이스터에그 발동 시에만 상단바와 가이드 안내 문구가 서서히 나타나도록 트윈 추가
    FlxTween.tween(topBar, {alpha: 1}, 0.6);
    FlxTween.tween(topTxt, {alpha: 1}, 0.6);

    FlxTween.tween(shadowTxt, {alpha: 1}, 0.6);
    FlxTween.tween(mainTxt, {alpha: 1}, 0.6);
    FlxTween.tween(subTxt, {alpha: 1}, 0.6);

    var colors:Array<Int> = [0xFFFFD9A8, 0xFFB8B0E8, 0xFFFF8FA3, 0xFF8FD3FF, 0xFFFFF29A];
    for (i in 0...40)
    {
        var s:FlxSprite = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(-300, -20));
        s.makeGraphic(8, 12, colors[i % colors.length]);
        s.scrollFactor.set();
        add(s);
        confetti.push(s);
        
        FlxTween.tween(s, {y: FlxG.height + 30, angle: FlxG.random.float(-360, 360)}, FlxG.random.float(3.5, 7), {
            startDelay: FlxG.random.float(0, 4),
            onComplete: function(twn:FlxTween) {
                if (confetti.contains(s)) {
                    confetti.remove(s);
                    remove(s);
                    s.destroy();
                }
            }
        });
    }
}

function stopBirthday()
{
    if (!birthdayOn) return;
    birthdayOn = false;
    
    if (FlxG.sound.music != null) {
        FlxG.sound.music.onComplete = null;
    }
    FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7, true);

    // [수정] 종료 시 상단바와 가이드 안내 문구도 함께 사라지도록 처리
    FlxTween.tween(topBar, {alpha: 0}, 0.5);
    FlxTween.tween(topTxt, {alpha: 0}, 0.5);

    FlxTween.tween(shadowTxt, {alpha: 0}, 0.5);
    FlxTween.tween(mainTxt, {alpha: 0}, 0.5);
    FlxTween.tween(subTxt, {alpha: 0}, 0.5);
    
    for (s in confetti) {
        if (s != null) {
            FlxTween.cancelTweensOf(s);
            remove(s);
            s.destroy();
        }
    }
    confetti = [];
}
