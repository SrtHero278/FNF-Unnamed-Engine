package menus;

import Paths;
import Options;
import menus.OptionsState;
import copyPasted.MusicBeat;

#if sys
import sys.FileSystem;
import polymod.Polymod;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class TitleState extends MusicBeatState
{
    var options:Array<String> = ["play", "options"];
    var curOption:Int = 0;

    var optionDisplay:FlxSprite;
    var arrowLeft:FlxSprite;
    var arrowRight:FlxSprite;

    override public function create():Void
        {
            Options.resetOptionCatagory("optimization");
            #if sys
            if (FileSystem.exists("./mods")) {
                Paths.allMods = FileSystem.readDirectory('mods');

                var mods:Array<String> = ["+global+"];

                if (!FileSystem.exists("./mods/+global+")) {
                    trace("Global Mod Not Found. Creating New Directory.");
                    FileSystem.createDirectory("./mods/+global+");
                } else
                    Paths.allMods.remove("+global+");

                if (Paths.curMod != null) mods.push(Paths.curMod);

                Polymod.init({modRoot: "mods/", dirs: mods});
                options.push("mods");
            } else {
                trace("Mod Folder Not Found. Creating New Directory.");
                FileSystem.createDirectory("./mods");
                FileSystem.createDirectory("./mods/+global+");
            }
            #end

            FlxG.sound.playMusic(Paths.menuFile('title/music/title.ogg'), 1);

            var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.menuFile('title/images/bg.png'));
            bg.screenCenter(X);
            bg.antialiasing = Options.antialiasing;
            add(bg);

            var logoBack:FlxSprite = new FlxSprite().loadGraphic(Paths.menuFile('title/images/logo.png'));
            logoBack.screenCenter();
            logoBack.color = 0xFF000000;
            logoBack.antialiasing = Options.antialiasing;
            add(logoBack);

            var logo:FlxSprite = new FlxSprite().loadGraphic(Paths.menuFile('title/images/logo.png'));
            logo.screenCenter();
            logo.antialiasing = Options.antialiasing;
            add(logo);

            optionDisplay = new FlxSprite(0, 600).loadGraphic(Paths.menuFile('title/images/play.png'));
            optionDisplay.screenCenter(X);
            optionDisplay.antialiasing = Options.antialiasing;
            add(optionDisplay);

            arrowLeft = new FlxSprite(0, 600).loadGraphic(Paths.menuFile('title/images/arrow.png'));
            arrowLeft.x = optionDisplay.x - arrowLeft.width;
            arrowLeft.antialiasing = Options.antialiasing;
            add(arrowLeft);

            arrowRight = new FlxSprite(0, 600).loadGraphic(Paths.menuFile('title/images/arrow.png'));
            arrowRight.x = optionDisplay.x + optionDisplay.width;
            arrowRight.antialiasing = Options.antialiasing;
            arrowRight.flipX = true;
            add(arrowRight);

            var updateIcon:FlxSprite = new FlxSprite(10, 10, Paths.menuFile("title/images/updateIcon.png"));
            updateIcon.antialiasing = Options.antialiasing;
            add(updateIcon);
            
            FlxTween.tween(updateIcon.scale, {x: 0.9, y: 0.9}, 1, {ease: FlxEase.quadInOut, type: PINGPONG});
            FlxTween.tween(logoBack, {y: logoBack.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG});
            FlxTween.tween(logo, {y: logo.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.1});
			FlxTween.color(optionDisplay, 2, 0xFF00FFFF, 0xFF0000FF, {ease: FlxEase.linear, type: PINGPONG});
        }

        override public function update(elapsed:Float):Void
            {
                optionDisplay.y = FlxMath.lerp(600, optionDisplay.y, elapsed * 10);
                var scaleLerp:Float = FlxMath.lerp(1, arrowLeft.scale.y, elapsed * 10);
                arrowLeft.scale.set(scaleLerp, scaleLerp);
                arrowRight.scale.set(scaleLerp, scaleLerp);

                if (FlxG.keys.justPressed.LEFT) {
                    FlxG.sound.play(Paths.menuFile('sounds/scroll.ogg'), 1);
                    curOption--;
                    if (curOption < 0)
                        curOption = options.length - 1;
                    optionDisplay.loadGraphic(Paths.menuFile('title/images/' + options[curOption] + '.png'));
                    optionDisplay.y = 575;
                    optionDisplay.screenCenter(X);
                    arrowLeft.x = optionDisplay.x - arrowLeft.width;
                    arrowRight.x = optionDisplay.x + optionDisplay.width;
                    arrowLeft.scale.set(0.75, 0.75);
                } else if (FlxG.keys.justPressed.RIGHT) {
                    FlxG.sound.play(Paths.menuFile('sounds/scroll.ogg'), 1);
                    curOption++;
                    if (curOption > options.length - 1)
                        curOption = 0;
                    optionDisplay.loadGraphic(Paths.menuFile('title/images/' + options[curOption]));
                    optionDisplay.y = 575;
                    optionDisplay.screenCenter(X);
                    arrowLeft.x = optionDisplay.x - arrowLeft.width;
                    arrowRight.x = optionDisplay.x + optionDisplay.width;
                    arrowRight.scale.set(0.75, 0.75);
                } else if (FlxG.keys.justPressed.ENTER) {
                    switch (options[curOption]) {
                        case "play":
                            FlxG.sound.play(Paths.menuFile('title/sounds/confirm.ogg'), 1);
                            super.openSubState(new menus.WeekSubState());
                        case "mods":
                            FlxG.sound.play(Paths.menuFile('title/sounds/confirm.ogg'), 1);
                            super.openSubState(new menus.ModsSubState());
                        case "options":
                            FlxG.sound.play(Paths.menuFile('title/sounds/confirm.ogg'), 1);

                            FlxTween.tween(FlxG.camera, {alpha: 0}, 0.5, {ease: FlxEase.linear, 
                                onComplete: function(twn:FlxTween) {
                                    FlxG.switchState(new OptionsState());
                                }});
                    }
                }
            }
}