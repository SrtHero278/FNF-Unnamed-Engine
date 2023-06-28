package funkin;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import flixel.util.FlxStringUtil;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;

import Paths;
import Options;
import menus.TitleState;
import funkin.HUD;
import funkin.Song;
import funkin.Note;
import funkin.FNFLua;
import funkin.Character;
import funkin.FocusedPlayState.BareBonesPlayState;
import copyPasted.MusicBeat;
import copyPasted.Conductor;

using StringTools;

class PlayState extends BareBonesPlayState {
    //Psych uses this for lua but I'm using this for avoiding static var errors.
	public static var instance:BareBonesPlayState;

	public var luaSprites:Map<String, FlxSprite> = new Map(); // Lua storage.
	public var luaSounds:Map<String, FlxSound> = new Map();
	public var luaTweens:Map<String, FlxTween> = new Map();
	public var luaTimers:Map<String, FlxTimer> = new Map();
    public var curScriptPath:String; //For traces.

    //public var paused:Bool = false; //When a substate is currently open.
    var failed:Bool = false;
    //public var onCountdown:Bool = true;

    //public var SONG:Song;
    var lastSectionStep:Int = 0;
    var sectionLength:Null<Int> = 16;
    var curSection:Int = 0;
    public var songScripts:Array<FNFLua> = [];

    public var gameObjects:FlxTypedGroup<FlxBasic>;
    public var camOffsets:Array<Float> = [0, 0, 0, 0, 0, 0];
    public var curStage:String;
    public var stageScript:FNFLua;

    public var defaultZoom:Float = 1;
    public var defaultHudZoom:Float = 1;
    //public var hitEnablesZoom:Bool = true;
    //public var sectionZooms:Bool = false;
    public var zoomResets:Bool = true;
    var camGame:FlxCamera;
    var camPos:FlxObject;

    //public var player:Character;
    public var spectator:Character;
    //public var opponent:Character;
    public var canPreload:Bool = true;
    public var loadedChars:Map<String, MinimizedCharacter> = new Map();

    //public var hud:HUD;

    public static var songData:Array<Array<String>> = [['Tutorial'], ['tutorial', 'hard']];
    //public var health:Float = 1;
    var iconTween1:FlxTween;
    var iconTween2:FlxTween;

    override public function create() {
        instance = this;

        Options.resetOptions();

        SONG = new Song(songData[0].shift().toLowerCase().replace(' ', '-').trim(), songData[1][0], songData[1][1]);
        if (SONG.error != null) {
            super.openSubState(new menus.ErrorSubState(SONG.error));
            paused = true;
            return;
        }

        for (name in SONG.scriptNames) {
            var script = new FNFLua(name, this);
            if (script.error != null) {
                super.openSubState(new menus.ErrorSubState(script.error));
                paused = true;
                return;
            }
            songScripts.push(script);
        }
        Conductor.changeBPM(SONG.chart.bpm);
        Conductor.mapBPMChanges(SONG.chart);
        Conductor.songPosition = Conductor.crochet * -5;
        curBeat = -5;
        curStep = -20;

        camGame = new FlxCamera();
        FlxG.cameras.reset(camGame);
        FlxCamera.defaultCameras = [camGame];

        player = new Character(770, 100);
        player.scrollFactor.set(1, 1);

        spectator = new Character(400, 130);
        spectator.scrollFactor.set(0.95, 0.95);

        opponent = new Character(100, 100);
        opponent.scrollFactor.set(1, 1);

        gameObjects = new FlxTypedGroup();
        loadStage((SONG.chart.stage != null) ? SONG.chart.stage : "stage");
        add(gameObjects);
        if (stageScript.error != null)
            return;

        var playerChar:String = (SONG.chart.player1 != null) ? SONG.chart.player1 : "bf";
        var specChar:String = (SONG.chart.gfVersion != null) ? SONG.chart.gfVersion : "gf";
        var oppChar:String = (SONG.chart.player2 != null) ? SONG.chart.player2 : "pico";
        switchChar("player", playerChar);
        switchChar("spectator", specChar);
        switchChar("opponent", oppChar);

        hud = new HUD(instance);
        hud.songInfo = SONG.chart.song + " - " + songData[1][1].toUpperCase() + " - 0:00 / 0:00";
        add(hud);

        camPos = new FlxObject(player.cameraPos.x, player.cameraPos.y, 1, 1);
        add(camPos);
        FlxG.camera.follow(camPos, LOCKON, 0.04);
        FlxG.camera.zoom = defaultZoom;

        for (section in SONG.chart.notes) {
            if (section.sectionNotes.length > 0) {
                for (note in section.sectionNotes) {
                    var data:Int = Std.int(note[1] % 8);
                    if (section.mustHitSection) {
                        data = (data + 4) % 8;
                    }

                    var strum:NoteLane = hud.strums.members[data];
                    var defaultAnims:Array<Array<String>> = [["singLEFT", "singLEFTmiss"], ["singDOWN", "singDOWNmiss"], ["singUP", "singUPmiss"], ["singRIGHT", "singRIGHTmiss"]];
                    var newNote:Note = new Note(note[0], note[2], strum.colors[1], SONG.chart.speed);
                    newNote.arrow.angle = strum.strum.angle;
                    newNote.overlay.angle = strum.strumOverlay.angle;
                    if (section.altAnim)
                        newNote.hitAnim = defaultAnims[data % 4][0] + "-alt";
                    else
                        newNote.hitAnim = defaultAnims[data % 4][0];
                    newNote.missAnim = defaultAnims[data % 4][1];
                    strum.unspawnNotes.push(newNote);
                }
            }
        }

        luaCall("postCreate", []);
        canPreload = false;
    }

    override public function update(elapsed:Float) {
        if (!paused) {
            super.update(elapsed);

            if (zoomResets) {
                FlxG.camera.zoom = FlxMath.lerp(defaultZoom, FlxG.camera.zoom, 0.95);
                hud.camHUD.zoom = FlxMath.lerp(defaultHudZoom, hud.camHUD.zoom, 0.95);
            }

            Conductor.lastSongPos = Conductor.songPosition;
			Conductor.songPosition += FlxG.elapsed * 1000;
            for (beat in -4...1) {
                if (Conductor.lastSongPos < Conductor.crochet * beat && Conductor.songPosition >= Conductor.crochet * beat) {
                    countdownTick(-1 - beat);
                }
            }

			hud.songInfo = SONG.chart.song + " - " + songData[1][1].toUpperCase() + " - " + FlxStringUtil.formatTime(SONG.inst.time / 1000, false) + " / " + FlxStringUtil.formatTime(SONG.inst.length / 1000, false);

            if (!failed) {
                if (health > 2)
                    health = 2;
                else if (health <= 0) {
                    hud.infoTxt.cameras = [camGame];
                    hud.rankIcon.cameras = [camGame];
                    hud.infoTxt.scrollFactor.set(0, 0);
                    hud.rankIcon.scrollFactor.set(0, 0);
                    FlxTween.tween(hud.camHUD, {alpha: 0}, 1, {ease: FlxEase.quartInOut, onComplete: function(twn:FlxTween) {
                        hud.strums.forEach(function(strum:NoteLane) {
                            strum.destroy();
                            hud.strums.remove(strum);
                        });
                    }});

                    defaultZoom = 1;
                    camPos.setPosition(player.cameraPos.x, player.cameraPos.y);
                    var darken = new FlxSprite();
                    darken.makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
                    darken.scrollFactor.set(0, 0);
                    darken.alpha = 0;
                    add(darken);
                    FlxTween.tween(darken, {alpha: 0.5}, 0.25, {ease: FlxEase.quartInOut});

                    gameObjects.remove(player, false);
                    add(player);
                    player.oofOwieMyBones();
                    spectator.playAnim('sad');
                    spectator.deathAnimsOnly = true;

                    SONG.inst.pause();
                    SONG.voices.pause();
                    FlxG.sound.play(Paths.menuFile('gameOver/fnf_loss_sfx.ogg'));

                    failed = true;
                    luaCall("onFail", []);
                }

                if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.ENTER)
                    pauseStuff(false);
            } else {
                if (player.animation.curAnim.name == "firstDeath" && player.animation.curAnim.finished) {
                    player.playAnim("deathLoop");
                    FlxG.sound.pause();
                    FlxG.sound.playMusic(Paths.menuFile('gameOver/gameOver.ogg'));
                }
                if (spectator.animation.curAnim.name == "sad" && !spectator.animation.curAnim.looped && spectator.animation.curAnim.finished)
                    spectator.animation.play("sad", true);

                if (FlxG.keys.justPressed.ENTER) {
                    songData[0].insert(0, SONG.fileName);

                    player.playAnim("deathConfirm");
                    spectator.deathAnimsOnly = false;
                    spectator.playAnim("cheer", true);
                    spectator.deathAnimsOnly = true;

                    FlxG.sound.pause();
                    FlxG.sound.play(Paths.menuFile('gameOver/gameOverEnd.ogg'));
                    FlxTween.tween(camGame, {alpha: 0}, 4.5, {ease: FlxEase.linear, onComplete: function(twn:FlxTween) {
                        FlxG.resetState();
                    }});
                } else if (FlxG.keys.justPressed.ESCAPE) {
                    player.playAnim("deathConfirm");

                    FlxG.sound.pause();
                    FlxG.sound.play(Paths.menuFile('gameOver/gameOverExit.ogg'));
                    FlxTween.tween(camGame, {alpha: 0}, 4.5, {ease: FlxEase.linear, onComplete: function(twn:FlxTween) {
                        FlxG.switchState(new TitleState());
                    }});
                }
            }
            luaSet("songPos", Conductor.songPosition);
            luaCall("update", [elapsed, failed]);
        }
    }

    override public function beatHit() {
        player.dance((curBeat % 2 == 0));
        spectator.dance((curBeat % 2 == 0));
        opponent.dance((curBeat % 2 == 0));

        if (curBeat % 4 == 0 && curBeat > 0) {
            if (Math.abs(Conductor.songPosition - SONG.inst.time) > 10) { // Not sure if it causes lag so checking if it's 10 miliseconds early/late.
                SONG.voices.pause();

                SONG.inst.play();
                Conductor.songPosition = SONG.inst.time;
                SONG.voices.time = Conductor.songPosition;
                SONG.voices.play();
            }
        }

        if (iconTween1 != null) {
            iconTween1.cancel();
            iconTween2.cancel();
        }

        hud.iconP1.scale.set(hud.scales[0] * 1.2, hud.scales[1] * 1.2);
        hud.iconP2.scale.set(hud.scales[2] * 1.2, hud.scales[3] * 1.2);
        iconTween1 = FlxTween.tween(hud.iconP1.scale, {x: hud.scales[0], y: hud.scales[1]}, 0.1);
        iconTween2 = FlxTween.tween(hud.iconP2.scale, {x: hud.scales[2], y: hud.scales[3]}, 0.1);

        luaSet("curBeat", curBeat);
        luaCall("beatHit", []);
    }

    override public function stepHit() {
        if (!failed) {
            super.stepHit();

		    if (curStep - lastSectionStep >= sectionLength) {
                curSection++;
                lastSectionStep += sectionLength;
                if (SONG.chart.notes[curSection] != null) {
                    sectionLength = SONG.chart.notes[curSection].lengthInSteps; //I feel like this should be used in the code more.
                    if (sectionLength == null)
                        sectionLength = 16;
                    luaSet("sectionData", SONG.chart.notes[curSection]);

                    var camX:Float = (SONG.chart.notes[curSection].mustHitSection) ? player.cameraPos.x : opponent.cameraPos.x;
                    var camY:Float = (SONG.chart.notes[curSection].mustHitSection) ? player.cameraPos.y : opponent.cameraPos.y;
                    camPos.setPosition(camX, camY);
                    
                    if (SONG.chart.notes[curSection].changeBPM && SONG.chart.notes[curSection].bpm != Conductor.bpm) {
                        Conductor.changeBPM(SONG.chart.notes[curSection].bpm);
                        luaSet("bpm", SONG.chart.notes[curSection].bpm);
                    }
                } else
                    sectionLength = 16;

                if (sectionZooms) {
                    FlxG.camera.zoom += 0.015;
                    hud.camHUD.zoom += 0.03;
                }

                luaSet("curSection", curSection);
                luaCall("sectionHit", []);
		    }

            luaSet("curStep", curStep);
            luaCall("stepHit", []);
        }
    }
    
    public function switchChar(char:String, name:String) {
        switch (char) {
            case "opponent" | "dad":
                if (loadedChars.exists(name)) {
                    opponent.loadMinimized(name, loadedChars.get(name), false, [camOffsets[4], camOffsets[5]]);
                } else if (canPreload || Options.canSwitchToUnpreloadedChars) {
                    var minChar:MinimizedCharacter = opponent.loadCharacter(name, false, [camOffsets[4], camOffsets[5]]);
                    loadedChars.set(name, minChar);
                    if (opponent.error != null) {
                        super.openSubState(new menus.ErrorSubState(opponent.error));
                        paused = true;
                        return;
                    }
                }
            case "spectator" | "girlfriend" | "gf":
                if (loadedChars.exists(name)) {
                    spectator.loadMinimized(name, loadedChars.get(name), false, [camOffsets[2], camOffsets[3]]);
                } else if (canPreload || Options.canSwitchToUnpreloadedChars) {
                    var minChar:MinimizedCharacter = spectator.loadCharacter(name, false, [camOffsets[2], camOffsets[3]]);
                    loadedChars.set(name, minChar);
                    if (spectator.error != null) {
                        super.openSubState(new menus.ErrorSubState(spectator.error));
                        paused = true;
                        return;
                    }
                }
            default:
                if (loadedChars.exists(name)) {
                    player.loadMinimized(name, loadedChars.get(name), true, [camOffsets[0], camOffsets[1]]);
                } else if (canPreload || Options.canSwitchToUnpreloadedChars) {
                    var minChar:MinimizedCharacter = player.loadCharacter(name, true, [camOffsets[0], camOffsets[1]]);
                    loadedChars.set(name, minChar);
                    if (player.error != null) {
                        super.openSubState(new menus.ErrorSubState(player.error));
                        paused = true;
                        return;
                    }
                }
        }
        if (!canPreload)
            hud.resetHealthbar();
    }

    public function loadStage(stage:String) {
        if (!canPreload && !Options.canSwitchStages) return;
        curStage = stage;
        gameObjects.forEach(function(item:FlxBasic) {
            if (item != player && item != spectator && item != opponent)
                item.destroy();
        });
        gameObjects.clear();

        player.x -= player.x - player.oldOffsets[0] - 770;
        player.y -= player.y - player.oldOffsets[1] - 100;
        spectator.x -= spectator.x - spectator.oldOffsets[0] - 400;
        spectator.y -= spectator.y - spectator.oldOffsets[1] - 130;
        opponent.x -= opponent.x - opponent.oldOffsets[0] - 100;
        opponent.y -= opponent.y - opponent.oldOffsets[1] - 100;

        stageScript = new FNFLua(Paths.stageFile(curStage + '/build.lua'), this);
        if (stageScript.error != null) {
            super.openSubState(new menus.ErrorSubState(stageScript.error));
            paused = true;
        }
    }

    public function addChar(char:String, x:Float, y:Float) {
        switch (char) {
            case "player" | "boyfriend" | "bf":
                player.x += x - 770;
                player.y += y - 100;
                gameObjects.add(player);
            case "spectator" | "girlfriend" | "gf":
                spectator.x += x - 400;
                spectator.y += y - 130;
                gameObjects.add(spectator);
            case "opponent" | "dad":
                opponent.x += x - 100;
                opponent.y += y - 100;
                gameObjects.add(opponent);
        }
    }

    function countdownTick(ticks:Int) {
		player.dance((Math.abs(ticks % 2) == 1) ? true : false);
		spectator.dance((Math.abs(ticks % 2) == 1) ? true : false);
		opponent.dance((Math.abs(ticks % 2) == 1) ? true : false);
		switch (ticks) {
			case 3:
				FlxG.sound.play(Paths.uiFile("countdown/intro3.ogg"), 1);
			case 2:
				FlxG.sound.play(Paths.uiFile("countdown/intro2.ogg"), 1);
				hud.countdown.loadGraphic(Paths.uiFile("countdown/ready.png"));
				hud.countdown.alpha = 1;
				hud.countdown.screenCenter();
				FlxTween.tween(hud.countdown, {alpha: 0}, Conductor.crochet / 1000, {ease: FlxEase.cubeInOut});
			case 1:
				FlxG.sound.play(Paths.uiFile("countdown/intro1.ogg"), 1);
				hud.countdown.loadGraphic(Paths.uiFile("countdown/set.png"));
				hud.countdown.alpha = 1;
				hud.countdown.screenCenter();
				FlxTween.tween(hud.countdown, {alpha: 0}, Conductor.crochet / 1000, {ease: FlxEase.cubeInOut});
			case 0:
				FlxG.sound.play(Paths.uiFile("countdown/introGo.ogg"), 1);
				hud.countdown.loadGraphic(Paths.uiFile("countdown/go.png"));
				hud.countdown.alpha = 1;
				hud.countdown.screenCenter();
				FlxTween.tween(hud.countdown, {alpha: 0}, Conductor.crochet / 1000, {
					ease: FlxEase.cubeInOut,
					onComplete: function(twn:FlxTween) {
						hud.countdown.destroy();
					}
				});
			case -1:
				onCountdown = false;
				SONG.inst.play();
				SONG.voices.play();
				SONG.inst.onComplete = function() {
					if (songData[0].length > 0)
						FlxG.resetState();
					else
						FlxG.switchState(new TitleState());
				};
                if (SONG.chart.notes[0] != null) {
                    sectionLength = SONG.chart.notes[curSection].lengthInSteps;
                    if (sectionLength == null)
                        sectionLength = 16;
                    luaSet("sectionData", SONG.chart.notes[0]);

                    var camX:Float = (SONG.chart.notes[0].mustHitSection) ? player.cameraPos.x : opponent.cameraPos.x;
                    var camY:Float = (SONG.chart.notes[0].mustHitSection) ? player.cameraPos.y : opponent.cameraPos.y;
                    camPos.setPosition(camX, camY);
                    
                    if (SONG.chart.notes[curSection].changeBPM && SONG.chart.notes[curSection].bpm != Conductor.bpm) {
                        Conductor.changeBPM(SONG.chart.notes[curSection].bpm);
                        luaSet("bpm", SONG.chart.notes[curSection].bpm);
                    }
                }
                luaSet("curSection", 0);
                luaCall("sectionHit", []);
                luaCall("startSong", []);
		}
    }

    public function luaCall(functionName:String, args:Array<Dynamic>) {
        curScriptPath = stageScript.filePath;
        stageScript.state.call(functionName, args);
        for (script in songScripts) {
            curScriptPath = script.filePath;
            script.state.call(functionName, args);
        }
    }

    public function luaSet(varName:String, value:Dynamic) {
        stageScript.state.setGlobalVar(varName, value);
        for (script in songScripts)
            script.state.setGlobalVar(varName, value);
    }
}