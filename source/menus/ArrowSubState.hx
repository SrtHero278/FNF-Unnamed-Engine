package menus;

import Paths;
import Options;
import menus.OptionsState;
import copyPasted.MusicBeat;

import haxe.Json;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxAngle;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import flixel.input.keyboard.FlxKey;
import flixel.addons.ui.FlxUI9SliceSprite;
import flash.geom.Rectangle;
#if sys
import sys.io.File;
#end

using StringTools;

typedef StrumValues = {
    var position:Array<Float>;
    var scale:Array<Float>;
    var angle:Float;
    var direction:Float;
    var alpha:Float;
    var color:String;
}

class ArrowSubState extends MusicBeatSubstate {
    var strums:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
    var curMode:String = "none";
    var selectedArrow:Int = -1;
    var indicator:FlxSprite;
    var note:FlxSprite;
    var overlay:FlxSprite;

    var controls:FlxText;
    var modeInfo:FlxText;

    var opponentNotes:Array<StrumValues>;
    var playerNotes:Array<StrumValues>;
    var keybinds:Array<String>;
    var arrowBinds:Array<String> = ["LEFT", "DOWN", "UP", "RIGHT"];

    var colorMode = "rgb";
    var uiBG:FlxUI9SliceSprite;
    var alphaText:FlxText;
    var colorText:FlxText;
    var alphaSlider:FlxSprite;
    var colorSlider1:FlxSprite;
    var colorSlider2:FlxSprite;
    var colorSlider3:FlxSprite;
    var colorBG1:FlxSprite;
    var colorBG2:FlxSprite;
    var colorBG3:FlxSprite;
    var keybindText:FlxText;
    var keybindButton:FlxSprite;
    var keybindInfo:FlxText;
    var keybindError:FlxTimer;

    var OptionState:OptionsState;

    public function new(optionState:OptionsState) {
        super();

        OptionState = optionState;

        opponentNotes = Options.opponentNotes;
        playerNotes = Options.playerNotes;
        keybinds = Options.keybinds;

        for (i in 0...4) {
            var daOpLane:FlxSprite = new FlxSprite(opponentNotes[i].position[0], opponentNotes[i].position[1], Paths.menuFile('options/notefield/strum.png'));
            daOpLane.angle = opponentNotes[i].angle;
            daOpLane.alpha = opponentNotes[i].alpha;
            daOpLane.color = 0xFFBFBFBF;
            daOpLane.scale.set(opponentNotes[i].scale[0], opponentNotes[i].scale[1]);
            updateThenRecenter(daOpLane);
            strums.insert(i, daOpLane);

            var daPlLane:FlxSprite = new FlxSprite(playerNotes[i].position[0], playerNotes[i].position[1], Paths.menuFile('options/notefield/strum.png'));
            daPlLane.angle = playerNotes[i].angle;
            daPlLane.alpha = playerNotes[i].alpha;
            daPlLane.color = 0xFFBFBFBF;
            daPlLane.scale.set(playerNotes[i].scale[0], playerNotes[i].scale[1]);
            updateThenRecenter(daPlLane);
            strums.insert(i + 4, daPlLane);
        }
        add(strums);

        indicator = new FlxSprite(-1000, -1000, Paths.menuFile('options/notefield/unknownIndicator'));
        indicator.scale.set(0.7, 0.7);
        updateThenRecenter(indicator);
        add(indicator);

        controls = new FlxText(0, 0, FlxG.width, "[A] - Alpha, Keybind, and Color | [S] - Scale and Position | [D] - Direction and Angle | [1-8] - Select Note | [P] - Presets", 16);
        controls.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(controls);

        modeInfo = new FlxText(0, 0, FlxG.width, "You have not selected a mode yet. If you see a question mark in front of your selected arrow, that's why.", 16);
        modeInfo.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        modeInfo.y = FlxG.height - modeInfo.height * 1.5;
        add(modeInfo);

        note = new FlxSprite(-1000, -1000);
        note.frames = Paths.sparrowAtlas('noteskins/default/normal/NOTE_assets', 'UI');
        note.animation.addByPrefix('arrow', 'arrow0', 24, false);
        note.animation.play('arrow');
        note.color = 0xFF00FFFF;
        note.scale.set(0.7, 0.7);
        note.visible = false;
        updateThenRecenter(note);
        add(note);

        overlay = new FlxSprite(-1000, -1000);
        overlay.frames = Paths.sparrowAtlas('noteskins/default/normal/NOTE_assets', 'UI');
        overlay.animation.addByPrefix('overlay', 'arrow overlay', 24, false);
        overlay.animation.play('overlay');
        overlay.scale.set(0.7, 0.7);
        overlay.visible = false;
        updateThenRecenter(overlay);
        add(overlay);

        uiBG = new FlxUI9SliceSprite(0, 0, Paths.menuFile("options/notefield/uiBG"), new Rectangle(0, 0, 500, 270));
        uiBG.visible = false;
        uiBG.screenCenter();
        add(uiBG);

        alphaText = new FlxText(uiBG.x, uiBG.y + 6, 500, "Note's Alpha: 100% (Click the gradient)", 16);
        alphaText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
        alphaText.visible = false;
        add(alphaText);

        alphaSlider = new FlxSprite(uiBG.x + 10, uiBG.y + 30, Paths.menuFile("options/notefield/gradientSlider"));
        alphaSlider.visible = false;
        add(alphaSlider);

        colorText = new FlxText(uiBG.x, alphaSlider.y + 36, 500, "Red: 255 | Green: 255 | Blue: 255", 16);
        colorText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
        colorText.visible = false;
        add(colorText);

        colorBG1 = new FlxSprite(uiBG.x + 10, alphaSlider.y + 60, Paths.menuFile("options/notefield/gradientBG"));
        colorBG1.color = FlxColor.fromRGB(0, 255, 255);
        colorBG1.visible = false;
        add(colorBG1);

        colorBG2 = new FlxSprite(uiBG.x + 10, colorBG1.y + 40, Paths.menuFile("options/notefield/gradientBG"));
        colorBG2.color = FlxColor.fromRGB(255, 0, 255);
        colorBG2.visible = false;
        add(colorBG2);

        colorBG3 = new FlxSprite(uiBG.x + 10, colorBG2.y + 40, Paths.menuFile("options/notefield/gradientBG"));
        colorBG3.color = FlxColor.fromRGB(255, 255, 0);
        colorBG3.visible = false;
        add(colorBG3);

        colorSlider1 = new FlxSprite(uiBG.x + 10, colorBG1.y, Paths.menuFile("options/notefield/gradientSlider"));
        colorSlider1.visible = false;
        add(colorSlider1);

        colorSlider2 = new FlxSprite(uiBG.x + 10, colorBG2.y, Paths.menuFile("options/notefield/gradientSlider"));
        colorSlider2.visible = false;
        add(colorSlider2);

        colorSlider3 = new FlxSprite(uiBG.x + 10, colorBG3.y, Paths.menuFile("options/notefield/gradientSlider"));
        colorSlider3.visible = false;
        add(colorSlider3);

        keybindText = new FlxText(uiBG.x, colorBG3.y + 36, 500, "Current Keybind: A (Unchangeable Bind: LEFT)", 16);
        keybindText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
        keybindText.visible = false;
        add(keybindText);
        
        keybindButton = new FlxSprite(uiBG.x + 10, colorBG3.y + 60);
        keybindButton.loadGraphic(Paths.menuFile("options/notefield/keybindButton"), true, 480, 30);
        keybindButton.animation.add('button', [0, 1, 2], 1);
        keybindButton.animation.play("button");
        keybindButton.visible = false;
        add(keybindButton);

        keybindInfo = new FlxText(uiBG.x, keybindButton.y + 6, 500, "Click here to set keybind", 16);
        keybindInfo.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
        keybindInfo.visible = false;
        add(keybindInfo);

        keybindError = new FlxTimer();
    }

    var exiting:Bool = false;
    override public function update(elapsed:Float) {
        super.update(elapsed);
        
        if (exiting) return;
        if (curMode != "extras:keybind" && curMode != "preset:") {
            var keys:Array<Bool> = [
                FlxG.keys.justPressed.ONE, FlxG.keys.justPressed.TWO, FlxG.keys.justPressed.THREE, FlxG.keys.justPressed.FOUR, 
                FlxG.keys.justPressed.FIVE, FlxG.keys.justPressed.SIX, FlxG.keys.justPressed.SEVEN, FlxG.keys.justPressed.EIGHT,
                FlxG.keys.justPressed.A, FlxG.keys.justPressed.S, FlxG.keys.justPressed.D, FlxG.keys.justPressed.P, FlxG.keys.justPressed.ESCAPE
            ];
            var keyPress = keys.indexOf(true);
            if (keyPress != -1) {
                switch (keyPress) {
                    case 8:
                        if (selectedArrow != -1) {
                            if (!curMode.startsWith("extras"))
                                curMode = "extras:unclicked";
                            indicator.visible = false;
                            modeInfo.text = "This is mainly for properties that mainly only work in a menu like style.\n[SHIFT] - 5 * 5 Snapping | [CTRL] - 10 * 10 Snapping | [ALT] - Switch Color Mode\n(WARNING: HSB Mode is slightly broken when Sat/Brt is below 20/10%)\n";
                            modeInfo.y = FlxG.height - modeInfo.height / 1.3;
                            note.visible = true;
                            overlay.visible = true;
                            note.x = 1040;
                            overlay.x = 1040;
                            note.y = 360;
                            overlay.y = 360;
                            for (thing in [uiBG, alphaText, alphaSlider, colorText, colorSlider1, colorSlider2, colorSlider3, colorBG1, colorBG2, colorBG3, keybindText, keybindButton, keybindInfo])
                                thing.visible = true;
                        }
                    case 9:
                        if (!curMode.startsWith("position"))
                            curMode = "position:unclicked";
                        indicator.visible = true;
                        indicator.loadGraphic(Paths.menuFile('options/notefield/scaleIndicator'));
                        modeInfo.text = "SCALING - Click inside the lines to scale the arrow | [SHIFT] - Uniform Scaling | [CTRL] - 0.05 * 0.05 Snapping\nPOSITIONING - Click outside the lines to move the arrow | [SHIFT] - 10 * 10 Snapping | [CTRL] - 5 * 5 Snapping\n";
                        modeInfo.y = FlxG.height - modeInfo.height / 1.5;
                        note.visible = false;
                        overlay.visible = false;
                        for (thing in [uiBG, alphaText, alphaSlider, colorText, colorSlider1, colorSlider2, colorSlider3, colorBG1, colorBG2, colorBG3, keybindText, keybindButton, keybindInfo])
                            thing.visible = false;
                    case 10:
                        if (!curMode.startsWith("angle"))
                            curMode = "angle:unclicked";
                        indicator.visible = true;
                        indicator.loadGraphic(Paths.menuFile('options/notefield/angleIndicator'));
                        modeInfo.text = "DIRECTION - Click outside the circle to rotate the colored arrow around the gray arrow | [SHIFT] - 10 * 10 Snapping\nANGLE - Click inside the circle to rotate the gray arrow | [SHIFT] - 10 * 10 Snapping\n";
                        modeInfo.y = FlxG.height - modeInfo.height / 1.5;
                        note.visible = true;
                        overlay.visible = true;
                        for (thing in [uiBG, alphaText, alphaSlider, colorText, colorSlider1, colorSlider2, colorSlider3, colorBG1, colorBG2, colorBG3, keybindText, keybindButton, keybindInfo])
                            thing.visible = false;
                        
                        if (selectedArrow != -1) {
                            note.angle = strums.members[selectedArrow].angle;
                            overlay.angle = strums.members[selectedArrow].angle;
        
                            var direction:Float = (selectedArrow >= 4) ? playerNotes[selectedArrow - 4].direction : opponentNotes[selectedArrow].direction;
                            note.x = strums.members[selectedArrow].x + 110 * Math.sin(direction * Math.PI / -180);
                            note.y = strums.members[selectedArrow].y + 110 * Math.cos(direction * Math.PI / 180);
                            overlay.x = note.x;
                            overlay.y = note.y;
                        }
                    case 11:
                        curMode = "preset:";
                        indicator.loadGraphic(Paths.menuFile('options/notefield/unknownIndicator'));
                        indicator.setPosition(-1000, -1000);
                        note.setPosition(-1000, -1000);
                        overlay.setPosition(-1000, -1000);
                        uiBG.visible = true;
                        alphaText.visible = true;
                        alphaText.text = "Press a key to choose a preset\n\n[UP] - Upscroll\n[DOWN] - Downscroll\n[U] - Center Upscroll\n[D] - Center Downscroll\n\n[ESC] - Cancel\n";
                        alphaText.size = 24;
                        alphaText.screenCenter(Y);
                        modeInfo.text = "Modifies positions, scales, and directions of the arrows based on a selected preset.";
                        modeInfo.y = FlxG.height - modeInfo.height * 1.5;
        
                        selectedArrow = 0;
                        for (i in 0...8)
                            strums.members[i].color = 0xFFFFFFFF;
        
                        for (thing in [alphaSlider, colorText, colorSlider1, colorSlider2, colorSlider3, colorBG1, colorBG2, colorBG3, keybindText, keybindButton, keybindInfo])
                            thing.visible = false;
                    case 12:
                        exiting = true;
                        #if sys
                        File.saveContent("assets/settings/notefield.json", Json.stringify({opponentNotes: opponentNotes, playerNotes: playerNotes, keybinds: keybinds}, "\t"));
                        #end
                        FlxTween.tween(OptionState.bg, {alpha: 0.5}, 0.25, {onComplete: function(twn:FlxTween) {
                            close();
                        }});
                        return;
                    default:
                        selectNote(keyPress);
                }
            }
        }

        if (selectedArrow != -1) {
            var position = FlxG.mouse.getScreenPosition(FlxG.camera);
            var strum:FlxSprite = strums.members[selectedArrow];
            switch (curMode.substring(0, curMode.indexOf(":"))) {
                case "position":
                    if (FlxG.mouse.justPressed && curMode.endsWith(":unclicked")) {
                        if (position.x >= indicator.x - indicator.width * 0.5 && position.x <= indicator.x + indicator.width * 0.5 
                        && position.y >= indicator.y - indicator.height * 0.5 && position.y <= indicator.y + indicator.height * 0.5) {
                            if (position.y >= indicator.y - indicator.height / 4 && position.y <= indicator.y + indicator.height / 4)
                                curMode = "position:scaleX";
                            else if (position.x >= indicator.x - indicator.width / 4 && position.x <= indicator.x + indicator.width / 4)
                                curMode = "position:scaleY";
                            else
                                curMode = "position:moving";
                        } else
                            curMode = "position:moving";
                    } else if (FlxG.mouse.pressed && curMode.endsWith(":moving")) {
                        strum.x = position.x;
                        strum.y = position.y;
                        if (FlxG.keys.pressed.SHIFT) {
                            strum.x = Math.floor(strum.x / 10) * 10;
                            strum.y = Math.floor(strum.y / 10) * 10;
                        } else if (FlxG.keys.pressed.CONTROL) {
                            strum.x = Math.floor(strum.x / 5) * 5;
                            strum.y = Math.floor(strum.y / 5) * 5;
                        }
    
                        if (selectedArrow >= 4)
                            playerNotes[selectedArrow - 4].position = [strum.x, strum.y];
                        else
                            opponentNotes[selectedArrow].position = [strum.x, strum.y];
    
                        indicator.x = strum.x;
                        indicator.y = strum.y;
                    } else if (FlxG.mouse.pressed && curMode.endsWith(":scaleX")) {
                        strum.scale.x = (position.x - indicator.x) / 230;
                        if (FlxG.keys.pressed.CONTROL)
                            strum.scale.x = Math.floor(strum.scale.x * 20) / 20;
                        if (FlxG.keys.pressed.SHIFT)
                            strum.scale.y = strum.scale.x;
                        if (selectedArrow >= 4)
                            playerNotes[selectedArrow - 4].scale = [strum.scale.x, strum.scale.y];
                        else
                            opponentNotes[selectedArrow].scale = [strum.scale.x, strum.scale.y];
                        updateThenRecenter(strum);
                        note.scale.set(strum.scale.x, strum.scale.y);
                        overlay.scale.set(note.scale.x, note.scale.y);
                        updateThenRecenter(note);
                        updateThenRecenter(overlay);
                    } else if (FlxG.mouse.pressed && curMode.endsWith(":scaleY")) {
                        strum.scale.y = (position.y - indicator.y) / 230;
                        if (FlxG.keys.pressed.CONTROL)
                            strum.scale.y = Math.floor(strum.scale.y * 20) / 20;
                        if (FlxG.keys.pressed.SHIFT)
                            strum.scale.x = strum.scale.y;
                        if (selectedArrow >= 4)
                            playerNotes[selectedArrow - 4].scale = [strum.scale.x, strum.scale.y];
                        else
                            opponentNotes[selectedArrow].scale = [strum.scale.x, strum.scale.y];
                        updateThenRecenter(strum);
                        note.scale.set(strum.scale.x, strum.scale.y);
                        overlay.scale.set(note.scale.x, note.scale.y);
                        updateThenRecenter(note);
                        updateThenRecenter(overlay);
                    } else if (FlxG.mouse.justReleased)
                        curMode = "position:unclicked";
                case "angle":
                    if (FlxG.mouse.justPressed && curMode.endsWith(":unclicked")) {
                        if (position.x >= indicator.x - indicator.width * 0.5 && position.x <= indicator.x + indicator.width * 0.5
                        && position.y >= indicator.y - indicator.height * 0.5 && position.y <= indicator.y + indicator.height * 0.5)
                            curMode = "angle:moving";
                        else
                            curMode = "angle:direction";
                    } else if (FlxG.mouse.pressed && curMode.endsWith(":moving")) {
                        //strum.angle = (FlxAngle.angleBetweenPoint(indicator, new FlxPoint(position.x, position.y), true) + 180) % 360;
                        strum.angle = (FlxAngle.angleBetweenMouse(indicator, true) + 180) % 360;
                        if (FlxG.keys.pressed.SHIFT)
                            strum.angle = Math.floor(strum.angle / 10) * 10;
                        if (selectedArrow >= 4)
                            playerNotes[selectedArrow - 4].angle = strum.angle;
                        else
                            opponentNotes[selectedArrow].angle = strum.angle;
                        note.angle = strum.angle;
                        overlay.angle = strum.angle;
                    } else if (FlxG.mouse.pressed && curMode.endsWith(":direction")) {
                        //var angle = (FlxAngle.angleBetweenPoint(strum, new FlxPoint(position.x, position.y), true) + 270) % 360;
                        var angle = (FlxAngle.angleBetweenMouse(strum, true) + 270) % 360;
                        if (FlxG.keys.pressed.SHIFT)
                            angle = Math.floor(angle / 10) * 10;
                        if (selectedArrow >= 4)
                            playerNotes[selectedArrow - 4].direction = angle;
                        else
                            opponentNotes[selectedArrow].direction = angle;
                        note.x = strum.x + 110 * Math.sin(angle * Math.PI / -180);
                        note.y = strum.y + 110 * Math.cos(angle * Math.PI / 180);
                        overlay.x = note.x;
                        overlay.y = note.y;
                    } else if (FlxG.mouse.justReleased)
                        curMode = "angle:unclicked";
                case "extras":
                    if (FlxG.mouse.overlaps(keybindButton) && selectedArrow >= 4) {
                        keybindButton.animation.curAnim.curFrame = 1;
                        keybindInfo.color = 0xFF000000;
                    } else {
                        keybindButton.animation.curAnim.curFrame = 0;
                        keybindInfo.color = 0xFFFFFFFF;
                    }
    
                    if (FlxG.mouse.justPressed && curMode.endsWith("unclicked") && position.x >= alphaSlider.x && position.x <= alphaSlider.x + alphaSlider.width) {
                        if (position.y >= alphaSlider.y && position.y <= alphaSlider.y + alphaSlider.height)
                            curMode = "extras:alpha";
                        else if (position.y >= colorSlider1.y && position.y <= colorSlider1.y + colorSlider1.height)
                            curMode = "extras:color1";
                        else if (position.y >= colorSlider2.y && position.y <= colorSlider2.y + colorSlider2.height)
                            curMode = "extras:color2";
                        else if (position.y >= colorSlider3.y && position.y <= colorSlider3.y + colorSlider3.height)
                            curMode = "extras:color3";
                        else if (position.y >= keybindButton.y && position.y <= keybindButton.y + keybindButton.height && selectedArrow >= 4) {
                            curMode = "extras:keybind";
                            keybindInfo.text = "Press a key to assign a keybind (ESC to cancel)";
                        }
                    } else if (FlxG.mouse.pressed) {
                        switch (curMode.substring(curMode.indexOf(":"), curMode.length)) {
                            case ":alpha":
                                var daAlpha:Float = FlxMath.roundDecimal(FlxMath.bound((position.x - alphaSlider.width + 80) / alphaSlider.width, 0, 1), 2);
                                if (FlxG.keys.pressed.CONTROL)
                                    daAlpha = Math.floor(daAlpha * 10) / 10;
                                else if (FlxG.keys.pressed.SHIFT)
                                    daAlpha = Math.floor(daAlpha * 20) / 20;
                                if (selectedArrow >= 4)
                                    playerNotes[selectedArrow - 4].alpha = daAlpha;
                                else
                                    opponentNotes[selectedArrow].alpha = daAlpha;
                                strum.alpha = daAlpha;
                                note.alpha = daAlpha;
                                overlay.alpha = daAlpha;
                                alphaText.text = "Note's Alpha: " + daAlpha * 100 + "% (Click the gradient)";
                            case ":color1":
                                if (colorMode == "rgb") {
                                    var daColor:Int = Std.int(FlxMath.bound((position.x - colorSlider1.width + 80) / colorSlider1.width * 255, 0, 255));
                                    if (FlxG.keys.pressed.CONTROL)
                                        daColor = Math.floor(daColor / 10) * 10;
                                    else if (FlxG.keys.pressed.SHIFT)
                                        daColor = Math.floor(daColor / 5) * 5;
                                    note.color = FlxColor.fromRGB(daColor, note.color.green, note.color.blue);
                                } else {
                                    var daColor:Float = Math.round(FlxMath.bound((position.x - colorSlider1.width + 80) / colorSlider1.width * 360, 0, 360));
                                    if (FlxG.keys.pressed.CONTROL)
                                        daColor = Math.floor(daColor / 10) * 10;
                                    else if (FlxG.keys.pressed.SHIFT)
                                        daColor = Math.floor(daColor / 5) * 5;
                                    var daSat = (note.color.saturation > 0) ? note.color.saturation : 0.2;
                                    var daBrt = (note.color.brightness > 0) ? note.color.brightness : 0.1;
                                    note.color = FlxColor.fromHSB(daColor, daSat, daBrt);
                                }
                            case ":color2":
                                if (colorMode == "rgb") {
                                    var daColor:Int = Std.int(FlxMath.bound((position.x - colorSlider2.width + 80) / colorSlider2.width * 255, 0, 255));
                                    if (FlxG.keys.pressed.CONTROL)
                                        daColor = Math.floor(daColor / 10) * 10;
                                    else if (FlxG.keys.pressed.SHIFT)
                                        daColor = Math.floor(daColor / 5) * 5;
                                    note.color = FlxColor.fromRGB(note.color.red, daColor, note.color.blue);
                                } else {
                                    var daColor:Float = FlxMath.roundDecimal(FlxMath.bound((position.x - colorSlider2.width + 80) / colorSlider2.width, 0, 1), 2);
                                    if (FlxG.keys.pressed.CONTROL)
                                        daColor = Math.floor(daColor * 10) / 10;
                                    else if (FlxG.keys.pressed.SHIFT)
                                        daColor = Math.floor(daColor * 20) / 20;
                                    note.color = FlxColor.fromHSB(note.color.hue, daColor, (note.color.brightness > 0) ? note.color.brightness : 0.1);
                                }
                            case ":color3":
                                if (colorMode == "rgb") {
                                    var daColor:Int = Std.int(FlxMath.bound((position.x - colorSlider3.width + 80) / colorSlider3.width * 255, 0, 255));
                                    if (FlxG.keys.pressed.CONTROL)
                                        daColor = Math.floor(daColor / 10) * 10;
                                    else if (FlxG.keys.pressed.SHIFT)
                                        daColor = Math.floor(daColor / 5) * 5;
                                    note.color = FlxColor.fromRGB(note.color.red, note.color.green, daColor);
                                } else {
                                    var daColor:Float = FlxMath.roundDecimal(FlxMath.bound((position.x - colorSlider3.width + 80) / colorSlider3.width, 0, 1), 2);
                                    if (FlxG.keys.pressed.CONTROL)
                                        daColor = Math.floor(daColor * 10) / 10;
                                    else if (FlxG.keys.pressed.SHIFT)
                                        daColor = Math.floor(daColor * 20) / 20;
                                    var daSat = (note.color.saturation > 0) ? note.color.saturation : 0;
                                    note.color = FlxColor.fromHSB(note.color.hue, daSat, daColor);
                                }
                        }
                    } else if (curMode.endsWith("keybind")) {
                        keybindButton.animation.curAnim.curFrame = 2;
                        keybindInfo.color = 0xFF000000;
    
                        if (FlxG.keys.justPressed.ANY) {
                            var daKey:Int = FlxG.keys.firstJustPressed();
                            if (daKey > 0 && !(daKey >= 37 && daKey <= 40) && !keybinds.contains(FlxKey.toStringMap.get(daKey))) {
                                if (!keybindError.finished)
                                    keybindError.cancel();
                                curMode = "extras:unclicked";
                                keybindInfo.text = "Click here to set keybind";
                                if (daKey != 27) {
                                    keybinds[selectedArrow % 4] = FlxKey.toStringMap.get(daKey);
                                    keybindText.text = "Current Keybind: " + getCustomName(keybinds[selectedArrow % 4]) + " (Unchangeable Bind: " + arrowBinds[selectedArrow % 4] + ")";
                                }
                            } else if (daKey >= 37 && daKey <= 40) {
                                keybindInfo.text = "Arrow keys are a secondary unchangable set!";
                                keybindError.start(2, function(tmr:FlxTimer) {
                                    keybindInfo.text = "Press a key to assign a keybind (ESC to cancel)";
                                });
                            } else if (keybinds.contains(FlxKey.toStringMap.get(daKey))) {
                                keybindInfo.text = "Another arrow is binded to this key!";
                                keybindError.start(2, function(tmr:FlxTimer) {
                                    keybindInfo.text = "Press a key to assign a keybind (ESC to cancel)";
                                });
                            }
                        }
                    } else if (FlxG.mouse.justReleased)
                        curMode = "extras:unclicked";
    
                    if (FlxG.keys.justPressed.ALT) {
                        if (colorMode == "hsb") {
                            colorBG1.loadGraphic(Paths.menuFile("options/notefield/gradientBG"));
                            colorSlider1.loadGraphic(Paths.menuFile("options/notefield/gradientSlider"));
                            colorSlider1.alpha = 1;
    
                            colorBG1.color = FlxColor.fromRGB(0, note.color.green, note.color.blue);
                            colorBG2.color = FlxColor.fromRGB(note.color.red, 0, note.color.blue);
                            colorBG3.color = FlxColor.fromRGB(note.color.red, note.color.green, 0);
                            colorSlider1.color = FlxColor.fromRGB(255, note.color.green, note.color.blue);
                            colorSlider2.color = FlxColor.fromRGB(note.color.red, 255, note.color.blue);
                            colorSlider3.color = FlxColor.fromRGB(note.color.red, note.color.green, 255);
                            colorText.text = 'Red: ${note.color.red} | Green: ${note.color.green} | Blue: ${note.color.blue}';
    
                            colorMode = "rgb";
                        } else {
                            colorBG1.loadGraphic(Paths.menuFile("options/notefield/hueSlider"));
                            colorSlider1.loadGraphic(Paths.menuFile("options/notefield/gradientBG"));
                            colorSlider1.color = 0xFFFFFFFF;
    
                            colorBG1.color = FlxColor.fromHSB(0, 0, note.color.brightness);
                            colorBG2.color = FlxColor.fromHSB(note.color.hue, 0, note.color.brightness);
                            colorBG3.color = FlxColor.fromHSB(note.color.hue, note.color.saturation, 0);
                            colorSlider1.alpha = 1 - note.color.saturation;
                            colorSlider2.color = FlxColor.fromHSB(note.color.hue, 1, note.color.brightness);
                            colorSlider3.color = FlxColor.fromHSB(note.color.hue, note.color.saturation, 1);
                            var daSat = (note.color.saturation >= 0) ? note.color.saturation : 0;
                            colorText.text = 'Hue: ${Std.int(note.color.hue)} | Sat: ' + Std.int(daSat * 100) + '% | Brt: ${Std.int(note.color.brightness * 100)}%';
    
                            colorMode = "hsb";
                        }
                    }
    
                    if (FlxG.mouse.pressed && curMode.contains("color")) {
                        if (selectedArrow >= 4)
                            playerNotes[selectedArrow - 4].color = note.color.toHexString(false, false);
                        else
                            opponentNotes[selectedArrow].color = note.color.toHexString(false, false);
    
                        if (colorMode == "rgb") {
                            colorBG1.color = FlxColor.fromRGB(0, note.color.green, note.color.blue);
                            colorBG2.color = FlxColor.fromRGB(note.color.red, 0, note.color.blue);
                            colorBG3.color = FlxColor.fromRGB(note.color.red, note.color.green, 0);
                            colorSlider1.color = FlxColor.fromRGB(255, note.color.green, note.color.blue);
                            colorSlider2.color = FlxColor.fromRGB(note.color.red, 255, note.color.blue);
                            colorSlider3.color = FlxColor.fromRGB(note.color.red, note.color.green, 255);
                            colorText.text = 'Red: ${note.color.red} | Green: ${note.color.green} | Blue: ${note.color.blue}';
                        } else {
                            colorBG1.color = FlxColor.fromHSB(0, 0, note.color.brightness);
                            colorBG2.color = FlxColor.fromHSB(note.color.hue, 0, note.color.brightness);
                            colorBG3.color = FlxColor.fromHSB(note.color.hue, note.color.saturation, 0);
                            colorSlider1.alpha = 1 - note.color.saturation;
                            colorSlider2.color = FlxColor.fromHSB(note.color.hue, 1, note.color.brightness);
                            colorSlider3.color = FlxColor.fromHSB(note.color.hue, note.color.saturation, 1);
                            var daSat = (note.color.saturation >= 0) ? note.color.saturation : 0;
                            colorText.text = 'Hue: ${Std.int(note.color.hue)} | Sat: ' + Std.int(daSat * 100) + '% | Brt: ${Std.int(note.color.brightness * 100)}%';
                        }
                    }
                case "preset":
                    var keyIndex = [FlxG.keys.justPressed.UP, FlxG.keys.justPressed.DOWN, FlxG.keys.justPressed.U, FlxG.keys.justPressed.D].indexOf(true);
                    var values = [
                        {
                            pos: [155, 795, 105],
                            opOffset: 0,
                            scale: [0.7, 0.7],
                            direction: 0
                        },
                        {
                            pos: [155, 795, 625],
                            opOffset: 0,
                            scale: [0.7, 0.7],
                            direction: 180
                        },
                        {
                            pos: [105, 475, 105],
                            opOffset: -40,
                            scale: [0.45, 0.7],
                            direction: 0
                        },
                        {
                            pos: [105, 475, 625],
                            opOffset: -40,
                            scale: [0.45, 0.7],
                            direction: 180
                        }
                    ];
                    if (keyIndex != -1) {
                        var daValues = values[keyIndex];
                        for (strumID in 0...4) {
                            strums.members[strumID].x = daValues.pos[0] + (110 + daValues.opOffset) * strumID;
                            strums.members[strumID].y = daValues.pos[2];
                            strums.members[strumID].scale.set(daValues.scale[0], daValues.scale[0]);
                            updateThenRecenter(strums.members[strumID]);
                            opponentNotes[strumID].position = [strums.members[strumID].x, daValues.pos[2]];
                            opponentNotes[strumID].scale = [daValues.scale[0], daValues.scale[0]];
                            opponentNotes[strumID].direction = daValues.direction;

                            strums.members[strumID + 4].x = daValues.pos[1] + 110 * strumID;
                            strums.members[strumID + 4].y = daValues.pos[2];
                            strums.members[strumID + 4].scale.set(daValues.scale[1], daValues.scale[1]);
                            updateThenRecenter(strums.members[strumID + 4]);
                            playerNotes[strumID].position = [strums.members[strumID + 4].x, daValues.pos[2]];
                            playerNotes[strumID].scale = [daValues.scale[1], daValues.scale[1]];
                            playerNotes[strumID].direction = daValues.direction;
                        }
                    }

                    if (FlxG.keys.anyJustPressed([FlxKey.ESCAPE, FlxKey.UP, FlxKey.DOWN, FlxKey.U, FlxKey.D])) {
                        curMode = "none";
                        uiBG.visible = false;
                        alphaText.visible = false;
                        alphaText.text = "Note Alpha: 100% (Click the gradient)";
                        alphaText.size = 16;
                        alphaText.y = uiBG.y + 6;
                        modeInfo.text = "You have not selected a mode yet. If you see a question mark in front of your selected arrow, that's why.";
                        modeInfo.y = FlxG.height - modeInfo.height * 1.5;
    
                        selectedArrow = -1;
                        for (i in 0...8)
                            strums.members[i].color = 0xFFBFBFBF;
                    }
            }
        }
    }

    function selectNote(k:Int) {
        for (i in 0...8)
            strums.members[i].color = 0xFFBFBFBF;

        selectedArrow = k;
        strums.members[selectedArrow].color = 0xFFFFFFFF;
        indicator.x = strums.members[selectedArrow].x;
        indicator.y = strums.members[selectedArrow].y;

        note.color = Paths.colorFromString((k >= 4) ? playerNotes[selectedArrow - 4].color : opponentNotes[selectedArrow].color);
        note.alpha = (k >= 4) ? playerNotes[selectedArrow - 4].alpha : opponentNotes[selectedArrow].alpha;
        overlay.alpha = (k >= 4) ? playerNotes[selectedArrow - 4].alpha : opponentNotes[selectedArrow].alpha;
        if (colorMode == "rgb") {
            colorBG1.color = FlxColor.fromRGB(0, note.color.green, note.color.blue);
            colorBG2.color = FlxColor.fromRGB(note.color.red, 0, note.color.blue);
            colorBG3.color = FlxColor.fromRGB(note.color.red, note.color.green, 0);
            colorSlider1.color = FlxColor.fromRGB(255, note.color.green, note.color.blue);
            colorSlider2.color = FlxColor.fromRGB(note.color.red, 255, note.color.blue);
            colorSlider3.color = FlxColor.fromRGB(note.color.red, note.color.green, 255);
            colorText.text = 'Red: ${note.color.red} | Green: ${note.color.green} | Blue: ${note.color.blue}';
        } else {
            colorBG1.color = FlxColor.fromHSB(0, 0, note.color.brightness);
            colorBG2.color = FlxColor.fromHSB(note.color.hue, 0, note.color.brightness);
            colorBG3.color = FlxColor.fromHSB(note.color.hue, note.color.saturation, 0);
            colorSlider1.alpha = 1 - note.color.saturation;
            colorSlider2.color = FlxColor.fromHSB(note.color.hue, 1, note.color.brightness);
            colorSlider3.color = FlxColor.fromHSB(note.color.hue, note.color.saturation, 1);
            colorText.text = 'Hue: ${Std.int(note.color.hue)} | Sat: ${Std.int(note.color.saturation * 100)}% | Brt: ${Std.int(note.color.brightness * 100)}%';
        }
        note.angle = strums.members[selectedArrow].angle;
        overlay.angle = strums.members[selectedArrow].angle;
        note.scale.set(strums.members[selectedArrow].scale.x, strums.members[selectedArrow].scale.y);
        overlay.scale.set(note.scale.x, note.scale.y);
        updateThenRecenter(note);
        updateThenRecenter(overlay);

        alphaText.text = "Note's Alpha: " + strums.members[selectedArrow].alpha * 100 + "% (Click the gradient)";
        if (selectedArrow >= 4) {
            keybindText.text = "Current Keybind: " + getCustomName(keybinds[selectedArrow % 4]) + " (Unchangeable Bind: " + arrowBinds[selectedArrow % 4] + ")";
            keybindInfo.text = "Click here to set keybind";
        } else {
            keybindText.text = "Set keybinds on player notes! (5-8)";
            keybindInfo.text = "Locked";
        }
        if (curMode.startsWith("angle")) {
            var direction:Float = (selectedArrow >= 4) ? playerNotes[selectedArrow - 4].direction : opponentNotes[selectedArrow].direction;
            note.x = strums.members[selectedArrow].x + 110 * Math.sin(direction * Math.PI / -180);
            note.y = strums.members[selectedArrow].y + 110 * Math.cos(direction * Math.PI / 180);
            overlay.x = note.x;
            overlay.y = note.y;
        } else if (curMode.startsWith("extras")) {
            note.x = 1040;
            overlay.x = 1040;
            note.y = 360;
            overlay.y = 360;
        }
    }

    function getCustomName(bind:String) {
        switch (bind) {
            case "ZERO": return "0";
            case "ONE": return "1";
            case "TWO": return "2";
            case "THREE": return "3";
            case "FOUR": return "4";
            case "FIVE": return "5";
            case "SIX": return "6";
            case "SEVEN": return "7";
            case "EIGHT": return "8";
            case "NINE": return "9";
            case "CONTROL": return "CTRL";
            case "NUMPADZERO": return "PAD-0";
            case "NUMPADONE": return "PAD-1";
            case "NUMPADTWO": return "PAD-2";
            case "NUMPADTHREE": return "PAD-3";
            case "NUMPADFOUR": return "PAD-4";
            case "NUMPADFIVE": return "PAD-5";
            case "NUMPADSIX": return "PAD-6";
            case "NUMPADSEVEN": return "PAD-7";
            case "NUMPADEIGHT": return "PAD-8";
            case "NUMPADNINE": return "PAD-9";
            case "NUMPADMULTIPLY": return "PAD-MULT";
            case "NUMPADPLUS": return "PAD-PLUS";
            case "NUMPADMINUS": return "PAD-MINUS";
            case "NUMPADPERIOD": return "PAD-PERIOD";
            default: return bind;
        }
    }
    
    function updateThenRecenter(sprite:FlxSprite) {
        sprite.updateHitbox();
        sprite.offset.set(0.5 * sprite.frameWidth, 0.5 * sprite.frameHeight);
    }
}