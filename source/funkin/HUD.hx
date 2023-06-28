package funkin;

import openfl.events.KeyboardEvent;
import Paths;
import Options;
import funkin.NoteLane;
import funkin.FocusedPlayState.BareBonesPlayState;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.ui.FlxBar;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.input.keyboard.FlxKey;

using StringTools;

class HUD extends FlxTypedGroup<FlxBasic> {

    private var stateInstance:BareBonesPlayState;

    var judgeTween:FlxTween;
    var arrowTween:FlxTween;

    public var strums:FlxTypedGroup<NoteLane> = new FlxTypedGroup<NoteLane>();
    public var countdown:FlxSprite;
    public var camHUD:FlxCamera;

    public var rateValues:Array<Array<Float>> = [[150, 50, 0.25, -0.015], [130, 150, 0.5, 0.005], [80, 250, 0.75, 0.011], [45, 350, 1, 0.023]];
    public var rateNames:Array<String> = ["shit", "bad", "good", "sick"];
    var curJudge:String = "sick";
    var judgeDisplay:FlxSprite;
    var arrow:FlxSprite;
    public var combo:Int = 0;

    public var rankNames:Array<String> = ["fail", "crap", "basic", "amazing", "perfect"];
    public var rankAccs:Array<Float> = [0, 15, 40, 85, 100];
    public var songInfo:String = "Song - DIFF - 0:00 / 0:00";
    public var scoreInfo:String = "0 pts - 0 Misses - ?%\n";
    public var curRank:String = "perfect";
    public var rankIcon:FlxSprite;
    public var infoTxt:FlxText;
    public var score:Int = 0;
    public var misses:Int = 0;
    public var accStuff:Array<Float> = [0, 0, 0, 0]; //The fourth one is for ms acc. It's the average ms.

    public var healthBarBG:FlxSprite;
    public var healthBar:FlxBar;
    public var iconP1:FlxSprite;
    public var iconP2:FlxSprite;
    public var scales:Array<Float> = [1, 1, 1, 1];

    public function new(instance:BareBonesPlayState) {
        super();

        stateInstance = instance;

        camHUD = new FlxCamera();
        camHUD.bgColor.alpha = 0;
        FlxG.cameras.add(camHUD);

        if (Options.focused) {
            var bg = new FlxSprite(0, 0, Paths.uiFile("focusedBG.png"));
            bg.antialiasing = Options.antialiasing;
            bg.cameras = [camHUD];
            add(bg);
        }

        add(strums);
        var keys:Array<Array<Int>> = [
            [FlxKey.LEFT, FlxKey.fromString(Options.keybinds[0])],
            [FlxKey.DOWN, FlxKey.fromString(Options.keybinds[1])],
            [FlxKey.UP, FlxKey.fromString(Options.keybinds[2])],
            [FlxKey.RIGHT, FlxKey.fromString(Options.keybinds[3])]
        ];
        var missAnims = ["singLEFTmiss", "singDOWNmiss", "singUPmiss", "singRIGHTmiss"];
        for (i in 0...4) { // Opponent strums
            var daOpLane:NoteLane = new NoteLane(Options.opponentNotes[i], null, stateInstance.opponent, stateInstance);
            daOpLane.missAnim = missAnims[i];
            daOpLane.ID = i;
            strums.insert(i, daOpLane);

            var daPlLane:NoteLane = new NoteLane(Options.playerNotes[i], keys[i], stateInstance.player, stateInstance);
            daPlLane.missAnim = missAnims[i];
            daPlLane.ID = i + 4;
            strums.insert(i + 4, daPlLane);
        }

        countdown = new FlxSprite();
        countdown.alpha = 0;
        add(countdown);

        arrow = new FlxSprite();
        arrow.frames = Paths.sparrowAtlas('popups', "UI");
        arrow.animation.addByPrefix('arrow', 'arrow', 24, false);
        arrow.animation.play('arrow');
        arrow.scale.set(0.75, 0.75);
        arrow.updateHitbox();
        arrow.screenCenter();
        arrow.alpha = 0;
        add(arrow);

        judgeDisplay = new FlxSprite();
        judgeDisplay.frames = Paths.sparrowAtlas('popups', "UI");
        judgeDisplay.animation.addByPrefix('sick', 'sick', 24, false);
        judgeDisplay.animation.addByPrefix('good', 'good', 24, false);
        judgeDisplay.animation.addByPrefix('bad', 'bad', 24, false);
        judgeDisplay.animation.addByPrefix('shit', 'shit', 24, false);
        judgeDisplay.alpha = 0;
        add(judgeDisplay);

        healthBarBG = new FlxSprite(0, FlxG.height * 0.9);
        healthBarBG.loadGraphic(Paths.uiFile("defaultHealthBar.png"));
        healthBarBG.color = 0xFF3A3A3A;
        healthBarBG.screenCenter(X);
        add(healthBarBG);

        healthBar = new FlxBar(healthBarBG.x, healthBarBG.y, RIGHT_TO_LEFT, Std.int(healthBarBG.width), Std.int(healthBarBG.height), stateInstance, 'health', 0, 2);
        healthBar.createImageBar(null, Paths.uiFile("defaultHealthBar.png"), 0x00FFFFFF, 0xFFFFFFFF);
        healthBar.color = 0xFF66FF33;
        add(healthBar);

        if (!Options.focused) {
            iconP1 = new FlxSprite();
            iconP2 = new FlxSprite();
            resetHealthbar();
            iconP1.y = healthBar.y + healthBar.height / 2 - iconP1.height / 2;
            iconP2.y = healthBar.y + healthBar.height / 2 - iconP2.height / 2;
            iconP1.flipX = true;
            iconP1.cameras = [camHUD];
            iconP2.cameras = [camHUD];
            add(iconP1);
            add(iconP2);
        }

        rankIcon = new FlxSprite(FlxG.width, 0);
        rankIcon.loadGraphic(Paths.uiFile("perfect"));
        rankIcon.x -= rankIcon.width;
        add(rankIcon);

        infoTxt = new FlxText(rankIcon.x, 0, 0, songInfo + "\n" + scoreInfo, 16);
        infoTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
        infoTxt.x -= infoTxt.width;
        add(infoTxt);

        strums.cameras = [camHUD];
        countdown.cameras = [camHUD];

        judgeDisplay.cameras = [camHUD];
        arrow.cameras = [camHUD];

        rankIcon.cameras = [camHUD];
        infoTxt.cameras = [camHUD];

        healthBarBG.cameras = [camHUD];
        healthBar.cameras = [camHUD];

        FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
        FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, keyUp);
    }

    override public function destroy() {
        super.destroy();

        FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
        FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, keyUp);
    }

    function keyDown(event:KeyboardEvent) {
        for (strum in strums.members) {
            if (strum.keybinds != null && strum.keybinds.contains(event.keyCode))
                strum.press();
        }
    }

    function keyUp(event:KeyboardEvent) {
        for (strum in strums.members) {
            if (strum.keybinds != null && strum.keybinds.contains(event.keyCode))
                strum.release();
        }
    }

    public function rating(ms:Float) {

        var rateIndex:Int = 0;

        for (rating in 0...rateNames.length) {
            if (Math.abs(ms) <= rateValues[rating][0])
                rateIndex = rating;
        }
        curJudge = rateNames[rateIndex];
        switch (Options.accType) {
            case "rating":
                accStuff[1] += rateValues[rateIndex][2];
            case "hits":
                accStuff[1] += 1;
            case "ms":
                accStuff[1] += Math.abs(ms);
        }
        score += Std.int(rateValues[rateIndex][1]);
        stateInstance.health += rateValues[rateIndex][3];
        updateRank();
        
        if (judgeTween != null)
            judgeTween.cancel();

        judgeDisplay.animation.play(curJudge);
        judgeDisplay.alpha = 1;
        judgeDisplay.angle = FlxG.random.int(-20, 20, [-4, -3, -2, -1, 0, 1, 2, 3, 4]);
        judgeDisplay.scale.set(0.75, 0.75); //Mainly for the arrow position.
        judgeDisplay.updateHitbox();
        judgeDisplay.screenCenter();
        judgeDisplay.scale.set(0.01, 0.01);

        judgeTween = FlxTween.tween(judgeDisplay, {angle: -judgeDisplay.angle, "scale.x": 0.75, "scale.y": 0.75}, 0.5, {ease: FlxEase.circOut, onComplete: function(twn:FlxTween) {
            judgeTween = FlxTween.tween(judgeDisplay, {alpha: 0}, 0.25, {ease: FlxEase.circOut});
        }});

        if (curJudge != "sick") {
            if (arrowTween != null)
                arrowTween.cancel();
            if (ms > 0) { //Early
                arrow.flipX = false;
                arrow.x = judgeDisplay.x - arrow.width / 1.5;
            } else { //Late
                arrow.flipX = true;
                arrow.x = judgeDisplay.x + judgeDisplay.width - arrow.width / 1.5;
            }
            arrow.alpha = 1;
            judgeDisplay.angle = FlxG.random.int(-10, 10, [-2, -1, 0, 1, 2]);
            arrow.scale.set(0.01, 0.01);
            arrowTween = FlxTween.tween(arrow, {angle: -arrow.angle, "scale.x": 0.75, "scale.y": 0.75}, 0.5, {ease: FlxEase.circOut, onComplete: function(twn:FlxTween) {
                arrowTween = FlxTween.tween(arrow, {alpha: 0}, 0.25, {ease: FlxEase.circOut});
            }});
        }

        return curJudge;
    }

    var spin = false;
    override public function update(elapsed:Float) {
        super.update(elapsed);
    
        if (FlxG.keys.justPressed.F1) {
            spin = true;

            for (i in 0...8)
                strums.members[i].daValues.position = [640, 360];
        } else if (FlxG.keys.justPressed.F3) {
            spin = false;

            for (i in 0...4) {
                strums.members[i].daValues = Options.opponentNotes[i];
                strums.members[i + 4].daValues = Options.playerNotes[i];
            }
        }

        if (spin) {
            strums.forEach(function(strum:NoteLane) {
                strum.daValues.direction -= elapsed * 10;
            });
        }

        infoTxt.text = songInfo + "\n" + scoreInfo;
        infoTxt.x = rankIcon.x - infoTxt.width;

        if (!Options.focused) {
            iconP1.x = healthBar.x + healthBar.width * (1 - healthBar.percent / 100) - 26;
            iconP2.x = healthBar.x + healthBar.width * (1 - healthBar.percent / 100) - 128;
        }
    }

    public function updateRank() {
        accStuff[2]++;
        accStuff[0] = FlxMath.roundDecimal(accStuff[1] / accStuff[2], 4) * 100;
        if (Options.accType == "ms") {
            accStuff[3] = accStuff[1] / accStuff[2];
            accStuff[0] = 100 - FlxMath.roundDecimal(accStuff[3] / rateValues[0][0], 4) * 100; //This is supposed to be reverse lerping but since a is always 0, I just ended up with division.
        }
        scoreInfo = score + " pts - " + misses + " Misses - " + accStuff[0] + "%";
        if (misses == 1)
            scoreInfo.replace("Misses", "Miss");

        if (misses <= 0)
            scoreInfo += " [FC]";
        else if (misses < 10)
            scoreInfo += " [SDCB]";
        scoreInfo += "\n";

        var daRank:String = "f";

        for (rank in 0...rankNames.length) {
            if (accStuff[0] >= rankAccs[rank])
                daRank = rankNames[rank];
        }

        if (daRank != curRank) {
            rankIcon.loadGraphic(Paths.uiFile(daRank));
            curRank = daRank;
        }

        if (!Options.focused) {
            if (healthBar.percent >= 80) {
                iconP1.animation.play("winning");
                iconP2.animation.play("losing");
            } else if (healthBar.percent <= 20) {
                iconP1.animation.play("losing");
                iconP2.animation.play("winning");
            } else {
                iconP1.animation.play("normal");
                iconP2.animation.play("normal");
            }
        }
    }

    public function resetHealthbar() {
        if (stateInstance.player.healthBarGraphic.width == stateInstance.opponent.healthBarGraphic.width) {
            healthBarBG.loadGraphic(stateInstance.opponent.healthBarGraphic);
            healthBarBG.screenCenter(X);

            //i give empty bar a graphic and then remove it so it can reset barWidth since it's a private variable.
            healthBar.createImageBar(stateInstance.opponent.healthBarGraphic, stateInstance.player.healthBarGraphic, 0x00FFFFFF, 0xFFFFFFFF);
            healthBar.createColoredEmptyBar(0x00FFFFFF);
            healthBar.x = healthBarBG.x;
            healthBar.updateBar();
        }
        healthBarBG.color = stateInstance.opponent.healthColor;
        healthBar.color = stateInstance.player.healthColor;

        if (iconP1.frames == null || iconP1.frames != stateInstance.player.icon.frames)//It's annoying how i have to do this if statements just to make the animations play if it's the same icon.
            iconP1.loadGraphicFromSprite(stateInstance.player.icon);

        if (iconP2.frames == null || iconP2.frames != stateInstance.opponent.icon.frames)
            iconP2.loadGraphicFromSprite(stateInstance.opponent.icon);
        
        iconP1.setGraphicSize(150, 150);
        iconP2.setGraphicSize(150, 150);
        scales = [iconP1.scale.x, iconP1.scale.y, iconP2.scale.x, iconP2.scale.y];
    }
}