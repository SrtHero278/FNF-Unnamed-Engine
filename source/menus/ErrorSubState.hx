package menus;

import Paths;
import menus.TitleState;
import copyPasted.MusicBeat;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class ErrorSubState extends MusicBeatSubstate {

    override public function new(errorMessage:String) {
        super();

        var text:FlxText = new FlxText(50, 0, 1180, errorMessage + "\n\nPress [ESCAPE] to go back to the title screen.");
        text.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
        text.screenCenter(Y);

        var box:FlxSprite = new FlxSprite(50, 50).loadGraphic(Paths.menuFile('error/error.png'));
        box.scale.set(1, 0.001);
        FlxTween.tween(box.scale, {y: (text.height + 10) / 620}, 0.1, {ease: FlxEase.circOut});

        var uhoh:FlxSprite = new FlxSprite(50, 0).loadGraphic(Paths.menuFile('error/uhoh.png'));
        uhoh.y = FlxG.height / 2 - uhoh.height;
        FlxTween.tween(uhoh, {y:  FlxG.height / 2 - (text.height + 5) - uhoh.height}, 0.2, {ease: FlxEase.circOut});

        add(box);
        add(uhoh);
        add(text);
    }

    override public function update(elapsed:Float) {
        if (FlxG.keys.justPressed.ESCAPE) {
            FlxG.switchState(new TitleState());
        }
    }
}