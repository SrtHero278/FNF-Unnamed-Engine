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

class GameplaySettings extends MusicBeatSubstate {
    var selected:Int = 0;

    var options:Array<MenuOption> = [
        {
            name: "Ghost Tapping",
            jsonName: "ghostTapping",
            description: "If disabled, will make you miss if you press a key without a note.",
            type: OptionType.BOOL,
            value: true,
            min: 0,
            max: 1,
            updateFunc: function(text:FlxText, option:MenuOption, selected:Bool, elapsed:Float) {
                if ((FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.A || FlxG.keys.justPressed.D || FlxG.keys.justPressed.ENTER) && selected) {
                    option.value = (!option.value);
                    var onOffText:String = (option.value) ? "Enabled" : "Disabled";
                    text.text = "Ghost Tapping: < " + onOffText + " >";
                }
            }
        },
        {
            name: "Input Offset",
            jsonName: "inputOffset",
            description: "Delays when you need to press a key to hit a note. (Higher Values means you have to hit later)",
            type: OptionType.INT,
            value: 0,
            min: -100,
            max: 100,
            updateFunc: function(text:FlxText, option:MenuOption, selected:Bool, elapsed:Float) {
                if (selected) {
                    var statements:Array<Bool> = [
                        ((FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D) || (FlxG.keys.pressed.SHIFT && (FlxG.keys.pressed.RIGHT || FlxG.keys.pressed.D))),
                        ((FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A) || (FlxG.keys.pressed.SHIFT && (FlxG.keys.pressed.LEFT || FlxG.keys.pressed.A))),
                        (FlxG.keys.justPressed.R),
                    ];
                    switch (statements.indexOf(true)) {
                        case 0:
                            option.value += 1;
                        case 1:
                            option.value -= 1;
                        case 2:
                            option.value = 0;
                    }
                    text.text = "Input Offset: < " + option.value + " >";
                }
            }
        },
        {
            name: "Accuracy Type",
            jsonName: "accType",
            description: "Changes how your accuracy is determined.",
            type: OptionType.STRING,
            value: "rating",
            min: 0,
            max: 2,
            updateFunc: function(text:FlxText, option:MenuOption, selected:Bool, elapsed:Float) {
                if (selected) {
                    var jsonOptions:Array<String> = ["rating", "hits", "ms"];
                    var optionIndex:Int = jsonOptions.indexOf(option.value);
                    var optionDisplay:Array<String> = ["Rating Based", "Hits / Total", "Milisecond Based"];
                    if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D) {
                        optionIndex += 1;
                        if (optionIndex >= jsonOptions.length)
                            optionIndex = 0;
                    } else if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A) {
                        optionIndex -= 1;
                        if (optionIndex < 0)
                            optionIndex = jsonOptions.length - 1;
                    }
                    option.value = jsonOptions[optionIndex];
                    text.text = "Accuracy Type: < " + optionDisplay[optionIndex] + " >";
                }
            }
        }
    ];
    var optionTexts:Array<FlxText> = [];
    var yValues:Array<Float> = []; //So the text can go schmoove.
    var descTxt:FlxText;
    var keyTxt:FlxText;

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
                case STRING:
                    var strings:Map<String, String> = [
                        "accType:rating" => "Rating Based",
                        "accType:hits" => "Hits / Passed",
                        "accType:ms" => "Milisecond Based"
                    ];
                    text.text += strings[option.jsonName + ":" + option.value] + " >";
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

        keyTxt = new FlxText(0, 715, 1280, "[SHIFT] - Hold to increase numbers faster by just holding [LEFT] or [RIGHT]. [R] - Reset Number", 30);
        keyTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        keyTxt.visible = (options[selected].type == OptionType.INT || options[selected].type == OptionType.FLOAT);
        keyTxt.y -= keyTxt.height;
        add(keyTxt);
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
                keyTxt.visible = (options[selected].type == OptionType.INT || options[selected].type == OptionType.FLOAT);
            case 1:
                selected += 1;
                if (selected >= options.length)
                    selected = 0;
                for (i in 0...yValues.length)
                    yValues[i] = 332 + 120 * (i - selected);
                descTxt.text = options[selected].description;
                keyTxt.visible = (options[selected].type == OptionType.INT || options[selected].type == OptionType.FLOAT);
            case 2:
                exiting = true;
                var daJson = {};
                for (option in options)
                    Reflect.setField(daJson, option.jsonName, option.value);
    
                #if sys
                File.saveContent("assets/settings/gameplay.json", Json.stringify(daJson, "\t"));
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