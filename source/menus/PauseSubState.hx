package menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

import funkin.NoteLane;
import funkin.PlayState;
import funkin.FocusedPlayState;
import copyPasted.MusicBeat;

class PauseSubState extends MusicBeatSubstate {

    var options:Array<FlxSprite> = [];
    var curOption:Int = 0;
    var destinations:Array<Float> = [];
    var hudsCam:FlxCamera;
    var oldMousePos:FlxPoint;

    var selectScale:Float = 0.5;

    public function new() {
        super();

        if (Options.focused)
            hudsCam = FocusedPlayState.instance.hud.camHUD;
        else
            hudsCam = PlayState.instance.hud.camHUD;

        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bg.alpha = 0;
		add(bg);

        var paused:FlxSprite = new FlxSprite().loadGraphic(Paths.menuFile("pause/pause"));
        paused.scale.set(0.75, 0.75);
        paused.updateHitbox();
        paused.y -= paused.height;
        paused.screenCenter(X);
		add(paused);

        var resume:FlxSprite = new FlxSprite(0, FlxG.height).loadGraphic(Paths.menuFile("pause/resume"));
        resume.scale.set(0.5, 0.5);
        resume.updateHitbox();
        resume.screenCenter(X);
		add(resume);
        options.push(resume);

        var restart:FlxSprite = new FlxSprite(0, FlxG.height).loadGraphic(Paths.menuFile("pause/restart"));
        restart.color = 0xFFAAAAAA;
        restart.scale.set(0.5, 0.5);
        restart.updateHitbox();
        restart.screenCenter(X);
		add(restart);
        options.push(restart);

        var exit:FlxSprite = new FlxSprite(0, FlxG.height).loadGraphic(Paths.menuFile("pause/exit"));
        exit.color = 0xFFAAAAAA;
        exit.scale.set(0.5, 0.5);
        exit.updateHitbox();
        exit.screenCenter(X);
		add(exit);
        options.push(exit);

        bg.cameras = [hudsCam];
        paused.cameras = [hudsCam];
        resume.cameras = [hudsCam];
        restart.cameras = [hudsCam];
        exit.cameras = [hudsCam];

        destinations.push(FlxG.height - 10 - exit.height);
        destinations.push(destinations[0] - 10 - restart.height);
        destinations.push(destinations[1] - 10 - exit.height);
        FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
        FlxTween.tween(paused, {y: 10}, 0.5, {ease: FlxEase.circOut, startDelay: 0.2});
        FlxTween.tween(exit, {y: destinations[0]}, 0.5, {ease: FlxEase.circOut, startDelay: 0.2});
        FlxTween.tween(restart, {y: destinations[1]}, 0.5, {ease: FlxEase.circOut, startDelay: 0.2});
        FlxTween.tween(resume, {y: destinations[2]}, 0.5, {ease: FlxEase.circOut, startDelay: 0.2});
        FlxTween.tween(this, {selectScale: 0.6}, 2, {ease: FlxEase.linear, type: PINGPONG});
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (FlxG.keys.justPressed.ESCAPE) {
            if (Options.focused)
                FocusedPlayState.instance.pauseStuff(true);
            else
                PlayState.instance.pauseStuff(true);
            close();
        }

        var curMousePos:FlxPoint = FlxG.mouse.getScreenPosition(hudsCam);
        if (options.length > 0) {
            if (oldMousePos == null)
                oldMousePos = curMousePos;
            if (Math.abs(curMousePos.y - oldMousePos.y) >= 7.5) {//Wanted a bigger dead zone.
                for (op in 0...options.length) {
                    var option = options[op];
                    if (curMousePos.y >= option.y && curMousePos.y <= option.y + option.height)
                        curOption = op;
                }
                oldMousePos = curMousePos;
            }

            if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.UP) {
                curOption--;
                if (curOption < 0)
                    curOption = options.length - 1;
            } else if (FlxG.keys.justPressed.S || FlxG.keys.justPressed.DOWN) {
                curOption++;
                if (curOption > options.length - 1)
                    curOption = 0;
            }

            for (option in options) {
                option.color = 0xFFAAAAAA;
                option.scale.set(0.5, 0.5);
            }
            options[curOption].color = 0xFFFFFFFF;
            options[curOption].scale.set(selectScale, selectScale);

            if (FlxG.keys.justPressed.ENTER || FlxG.mouse.justPressed) {
                switch (curOption) {
                    case 0:
                        if (Options.focused)
                            FocusedPlayState.instance.pauseStuff(true);
                        else
                            PlayState.instance.pauseStuff(true);
                        close();
                    case 1:
                        if (Options.focused) {
                            FocusedPlayState.songData[0].insert(0, FocusedPlayState.instance.SONG.fileName);
                            FocusedPlayState.instance.hud.strums.forEach(function(strum:NoteLane) {
                                strum.destroy();
                                FocusedPlayState.instance.hud.strums.remove(strum);
                            });
                        } else {
                            PlayState.songData[0].insert(0, PlayState.instance.SONG.fileName);
                            PlayState.instance.hud.strums.forEach(function(strum:NoteLane) {
                                strum.destroy();
                                PlayState.instance.hud.strums.remove(strum);
                            });
                        }
                        FlxG.resetState();
                    case 2:
                        FlxG.switchState(new TitleState());
                }
            }
        }
    }
}