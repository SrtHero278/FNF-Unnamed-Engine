package menus;

import Options;
import menus.TitleState;
import copyPasted.MusicBeat;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

typedef MenuOption = {
    var name:String;
    var jsonName:String;
    var description:String;
    var type:OptionType;
    var value:Dynamic;
    var min:Float;
    var max:Float;

    var updateFunc:FlxText->MenuOption->Bool->Float->Void;
}

enum OptionType {
    BOOL;
    INT;
    FLOAT;
    STRING;
}

class OptionsState extends MusicBeatState {

    var list:FlxText;
    public var bg:FlxSprite;
    var options:Array<String> = ["notefield", "gameplay", "optimization"];
    var optionValues:Array<Array<String>> = [
        ["Notefield Customization", "Change the colors, Change your keybinds, or move and rotate your notes!\nYou can change your notefield to however you want it!"],
        ["Gameplay Settings", "Settings to change up the way you play!"],
        ["Optimization", "someone help please my pc is burning"]
    ];
    var curOption:Int = 0;

    override public function create() {
        super.create();

        FlxG.sound.playMusic(Paths.menuFile('options/music.ogg'), 1);

        list = new FlxText(0, 0, FlxG.width, "[UP/DOWN]\n\n", 32);
        list.setFormat(Paths.font("vcr.ttf"), 32, 0xFFFFFFFF, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
        list.borderSize = 1.5;
        add(list);
        for (option in 0...options.length) {
            if (curOption == option)
                list.text += ">>> " + optionValues[option][0] + " <<<\n";
            else
                list.text += optionValues[option][0] + "\n";
        }
        list.text += "\n" + optionValues[curOption][1];
        list.screenCenter(Y);

        bg = new FlxSprite();
        bg.loadGraphic(Paths.menuFile('options/menuBGs/notefield.png'));
        bg.alpha = 0.5;
        add(bg);
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        switch ([(FlxG.keys.justPressed.ENTER), (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN), (FlxG.keys.justPressed.ESCAPE)].indexOf(true)) {
            case 0:
                FlxTween.tween(bg, {alpha: 1}, 0.25, {onComplete: function(twn:FlxTween) {
                    Options.resetOptionCatagory(options[curOption]);
                    switch (options[curOption]) {
                        case "notefield":
                            openASubState(new menus.ArrowSubState(this));
                        case "gameplay":
                            openASubState(new menus.GameplaySettings(this));
                        case "optimization":
                            openASubState(new menus.OptimizationSettings(this));
                    }
                }});
            case 1:
                curOption += (FlxG.keys.justPressed.UP) ? -1 : 1;
                if (curOption < 0)
                    curOption = options.length - 1;
                else if (curOption >= options.length)
                    curOption = 0;
    
                FlxG.sound.play(Paths.menuFile('sounds/scroll.ogg'), 1);
    
                list.text = "[UP/DOWN]\n\n";
                for (option in 0...options.length) {
                    if (curOption == option)
                        list.text += ">>> " + optionValues[option][0] + " <<<\n";
                    else
                        list.text += optionValues[option][0] + "\n";
                }
                list.text += "\n" + optionValues[curOption][1];
                list.screenCenter(Y);
    
                bg.loadGraphic(Paths.menuFile('options/menuBGs/' + options[curOption]));
            case 2:
                FlxTween.tween(FlxG.camera, {alpha: 0}, 0.5,
                    {onComplete: function(twn:FlxTween) {
                        FlxG.switchState(new TitleState());
                    }});
        }
    }

    function openASubState(daSubState:FlxSubState) { //Just so it can work with the tween.
        super.openSubState(daSubState);
    }
}