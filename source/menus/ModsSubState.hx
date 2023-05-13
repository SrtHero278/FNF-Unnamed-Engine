package menus;

import Paths;
import copyPasted.MusicBeat;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class ModsSubState extends MusicBeatSubstate {

    var modList:FlxText;
    var selectedMod:Int = 0;

    public function new() {
        super();

        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		add(bg);
        FlxTween.tween(bg, {alpha: 0.6}, 0.25, {ease: FlxEase.quartInOut});

        modList = new FlxText(0, 0, FlxG.width, "[ENTER] - Load Mod | [SPACE] - Base Game | [UP/DOWN] - Scroll Through Mods\n\n", 20);
        modList.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
        modList.antialiasing = false;
        modList.screenCenter();
        add(modList);

        for (mod in 0...Paths.allMods.length) {
            if (selectedMod == mod)
                modList.text += ">>> " + Paths.allMods[mod] + " <<<\n";
            else
                modList.text += Paths.allMods[mod] + "\n";
        }
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (FlxG.keys.justPressed.ESCAPE) {
            FlxG.sound.play(Paths.menuFile('title/sounds/cancel.ogg'), 0.5);
            close();
        } else if (FlxG.keys.justPressed.UP) {
            FlxG.sound.play(Paths.menuFile('sounds/scroll.ogg'), 1);
            selectedMod--;
            if (selectedMod < 0)
                selectedMod = Paths.allMods.length - 1;

            modList.text = "[ENTER] - Load Mod | [SPACE] - Base Game | [UP/DOWN] - Scroll Through Mods\n\n";
            for (mod in 0...Paths.allMods.length) {
                if (selectedMod == mod)
                    modList.text += ">>> " + Paths.allMods[mod] + " <<<\n";
                else
                    modList.text += Paths.allMods[mod] + "\n";
            }
        } else if (FlxG.keys.justPressed.DOWN) {
            FlxG.sound.play(Paths.menuFile('sounds/scroll.ogg'), 1);
            selectedMod++;
            if (selectedMod > Paths.allMods.length - 1)
                selectedMod = 0;

            modList.text = "[ENTER] - Load Mod | [SPACE] - Base Game | [UP/DOWN] - Scroll Through Mods\n\n";
            for (mod in 0...Paths.allMods.length) {
                if (selectedMod == mod)
                    modList.text += ">>> " + Paths.allMods[mod] + " <<<\n";
                else
                    modList.text += Paths.allMods[mod] + "\n";
            }
        } else if (FlxG.keys.justPressed.SPACE) {
            Paths.curMod = null;
            FlxG.sound.play(Paths.menuFile('title/sounds/confirm.ogg'), 1);

            FlxTween.tween(FlxG.camera, {alpha: 0}, 0.5, {ease: FlxEase.linear, 
                onComplete: function(twn:FlxTween) {
                    FlxG.resetState();
                }});
        } else if (FlxG.keys.justPressed.ENTER) {
            Paths.curMod = Paths.allMods[selectedMod];
            FlxG.sound.play(Paths.menuFile('title/sounds/confirm.ogg'), 1);

            FlxTween.tween(FlxG.camera, {alpha: 0}, 0.5, {ease: FlxEase.linear, 
                onComplete: function(twn:FlxTween) {
                    FlxG.resetState();
                }});
        }
    }
}