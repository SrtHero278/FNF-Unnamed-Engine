package menus;

import Paths;
import menus.OptionsState;
import copyPasted.MusicBeat.MusicBeatSubstate;

import haxe.Json;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
#if sys
import sys.io.File;
#end

class OptimizationSettings extends MusicBeatSubstate {
    var selected:Int = 0;

    var options:Array<MenuOption> = [
        {
            name: "Unpreloaded Chars",
            jsonName: "canSwitchToUnpreloadedChars",
            description: "If enabled, will allow the game to switch to any character, even if it wasn't preloaded yet.",
            type: OptionType.BOOL,
            value: true,
            min: 0,
            max: 1,
            updateFunc: function(text:FlxText, option:MenuOption, selected:Bool, elapsed:Float) {
                if ((FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.A || FlxG.keys.justPressed.D || FlxG.keys.justPressed.ENTER) && selected) {
                    option.value = (!option.value);
                    var onOffText:String = (option.value) ? "Enabled" : "Disabled";
                    text.text = "Unpreloaded Chars: < " + onOffText + " >";
                }
            }
        },
        {
            name: "Can Switch Stages",
            jsonName: "canSwitchStages",
            description: "If enabled, will allow the game to change the current stage you're playing.",
            type: OptionType.BOOL,
            value: true,
            min: 0,
            max: 1,
            updateFunc: function(text:FlxText, option:MenuOption, selected:Bool, elapsed:Float) {
                if ((FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.A || FlxG.keys.justPressed.D || FlxG.keys.justPressed.ENTER) && selected) {
                    option.value = (!option.value);
                    var onOffText:String = (option.value) ? "Enabled" : "Disabled";
                    text.text = "Can Switch Stages: < " + onOffText + " >";
                }
            }
        },
        {
            name: "Antialiasing",
            jsonName: "antialiasing",
            description: "If disabled, will make textures look less smoother and a bit more pixelated.",
            type: OptionType.BOOL,
            value: true,
            min: 0,
            max: 1,
            updateFunc: function(text:FlxText, option:MenuOption, selected:Bool, elapsed:Float) {
                if ((FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.A || FlxG.keys.justPressed.D || FlxG.keys.justPressed.ENTER) && selected) {
                    option.value = (!option.value);
                    var onOffText:String = (option.value) ? "Enabled" : "Disabled";
                    text.text = "Antialiasing: < " + onOffText + " >";
                }
            }
        },
        {
            name: "Focused Mode",
            jsonName: "focused",
            description: "PC still not doing good while playing? Try disabling everything except the HUD and gameplay!",
            type: OptionType.BOOL,
            value: true,
            min: 0,
            max: 1,
            updateFunc: function(text:FlxText, option:MenuOption, selected:Bool, elapsed:Float) {
                if ((FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.A || FlxG.keys.justPressed.D || FlxG.keys.justPressed.ENTER) && selected) {
                    option.value = (!option.value);
                    var onOffText:String = (option.value) ? "Enabled" : "Disabled";
                    text.text = "Focused Mode: < " + onOffText + " >";
                }
            }
        }
    ];
    var optionTexts:Array<FlxText> = [];
    var yValues:Array<Float> = []; //So the text can go schmoove.
    var descTxt:FlxText;

    var OptionState:OptionsState;

    public function new(optionState:OptionsState) {
        super();

        OptionState = optionState;

        for (option in options) {
            //Not so sure about the difference between fields and properties so getProperty it is.
            option.value = Reflect.getProperty(Options, option.jsonName);
            var text = new FlxText(50, 332 + 120 * optionTexts.length, 1280, option.name + ": < ", 60);
            switch (option.type) {
                case BOOL:
                    var onOffText:String = (option.value) ? "Enabled" : "Disabled";
                    text.text += onOffText + " >";
                default:
                    text.text += option.value + " >";
            }
            text.setFormat(Paths.font("vcr.ttf"), 60, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            text.borderSize = 2;
            add(text);
            optionTexts.push(text);
            yValues.push(text.y);
        }
        descTxt = new FlxText(55, 390, 1225, options[0].description, 20);
        descTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(descTxt);
    }

    var exiting:Bool = false;
    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (exiting) return;
        switch ([(FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W), (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S), (FlxG.keys.justPressed.ESCAPE)].indexOf(true)) {
            case 0:
                selected -= 1;
                if (selected < 0)
                    selected = options.length - 1;
                for (i in 0...yValues.length)
                    yValues[i] = 332 + 120 * (i - selected);
                descTxt.text = options[selected].description;
            case 1:
                selected += 1;
                if (selected >= options.length)
                    selected = 0;
                for (i in 0...yValues.length)
                    yValues[i] = 332 + 120 * (i - selected);
                descTxt.text = options[selected].description;
            case 2:
                exiting = true;
                var daJson = {};
                for (option in options)
                    Reflect.setField(daJson, option.jsonName, option.value);
    
                #if sys
                File.saveContent("assets/settings/optimization.json", Json.stringify(daJson, "\t"));
                #end
                FlxTween.tween(OptionState.bg, {alpha: 0.5}, 0.25, {onComplete: function(twn:FlxTween) {
                    close();
                }});
                return;
        }

        for (i=>option in options) {
            option.updateFunc(optionTexts[i], option, (selected == i), elapsed);

            optionTexts[i].y = FlxMath.lerp(yValues[i], optionTexts[i].y, 0.75);
            optionTexts[i].color = (i == selected) ? 0xFFFFFFFF : 0xFF888888;
        }
        descTxt.y = optionTexts[selected].y + optionTexts[selected].height + 2;
    }
}