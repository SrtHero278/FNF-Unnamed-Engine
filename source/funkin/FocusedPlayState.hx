package funkin;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxStringUtil;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

import Paths;
import Options;
import menus.TitleState;
import funkin.HUD;
import funkin.Song;
import funkin.Note;
import funkin.Character;
import copyPasted.MusicBeat;
import copyPasted.Conductor;

using StringTools;

class BareBonesPlayState extends MusicBeatState {
    public var paused:Bool = false;
    public var onCountdown:Bool = true;

    public var SONG:Song;

    public var hitEnablesZoom:Bool = true;
    public var sectionZooms:Bool = false;

    public var player:Character;
    public var opponent:Character;

    public var hud:HUD;

    public var health:Float = 1;

    public function pauseStuff(resuming:Bool) {
        if (!resuming) {
            paused = true;
            SONG.inst.pause();
            SONG.voices.pause();
            super.openSubState(new menus.PauseSubState());
        } else {
            paused = false;
            if (!onCountdown) {
                SONG.inst.play();
                SONG.voices.play();
            }
        }
    }
}

class FocusedPlayState extends BareBonesPlayState {
	public static var instance:BareBonesPlayState;

    //public var paused:Bool = false; //When a substate is currently open.
    var failed:Bool = false;
    //public var onCountdown:Bool = true;

    //public var SONG:Song;
    var lastSectionStep:Int = 0;
    var sectionLength:Null<Int> = 16;
    var curSection:Int = 0;

    public var defaultZoom:Float = 1;
    public var defaultHudZoom:Float = 1;
    //public var hitEnablesZoom:Bool = true;
    //public var sectionZooms:Bool = false;
    public var zoomResets:Bool = true;

    //public var player:Character;
    //public var opponent:Character;

    //public var hud:HUD;

    public static var songData:Array<Array<String>> = [['Tutorial'], ['tutorial', 'hard']];
    //public var health:Float = 1;

    override public function create() {
        instance = this;

        Options.resetOptions();

        SONG = new Song(songData[0].shift().toLowerCase().replace(' ', '-').trim(), songData[1][0], songData[1][1]);
        if (SONG.error != null) {
            super.openSubState(new menus.ErrorSubState(SONG.error));
            paused = true;
            return;
        }

        Conductor.changeBPM(SONG.chart.bpm);
        Conductor.mapBPMChanges(SONG.chart);
        Conductor.songPosition = Conductor.crochet * -5;
        curBeat = -5;
        curStep = -20;

        player = new Character(770, 100);
        player.scrollFactor.set(1, 1);

        opponent = new Character(100, 100);
        opponent.scrollFactor.set(1, 1);

        hud = new HUD(instance);
        hud.songInfo = SONG.chart.song + " - " + songData[1][1].toUpperCase() + " - 0:00 / 0:00";
        add(hud);

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
                    var newNote:Note = new Note(note[0], note[2], strum.colors[1]);
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
    }

    override public function update(elapsed:Float) {
        if (!paused) {
            super.update(elapsed);

            if (zoomResets)
                hud.camHUD.zoom = FlxMath.lerp(defaultHudZoom, hud.camHUD.zoom, 0.95);

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
                    SONG.inst.pause();
                    SONG.voices.pause();
                    FlxG.sound.play(Paths.menuFile('gameOver/fnf_loss_sfx.ogg'));

                    failed = true;
                }

                if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.ENTER)
                    pauseStuff(false);
            } else {
                if (FlxG.keys.justPressed.ENTER) {
                    songData[0].insert(0, SONG.fileName);

                    FlxG.sound.pause();
                    FlxG.sound.play(Paths.menuFile('gameOver/gameOverEnd.ogg'));
                    FlxTween.tween(hud.camHUD, {alpha: 0}, 4.5, {ease: FlxEase.linear, onComplete: function(twn:FlxTween) {
                        FlxG.resetState();
                    }});
                } else if (FlxG.keys.justPressed.ESCAPE) {
                    FlxG.sound.pause();
                    FlxG.sound.play(Paths.menuFile('gameOver/gameOverExit.ogg'));
                    FlxTween.tween(hud.camHUD, {alpha: 0}, 4.5, {ease: FlxEase.linear, onComplete: function(twn:FlxTween) {
                        FlxG.switchState(new TitleState());
                    }});
                }
            }
        }
    }

    override public function beatHit() {
        if (curBeat % 4 == 0 && curBeat > 0) {
            if (Math.abs(Conductor.songPosition - SONG.inst.time) > 10) { // Not sure if it causes lag so checking if it's 10 miliseconds early/late.
                SONG.voices.pause();

                SONG.inst.play();
                Conductor.songPosition = SONG.inst.time;
                SONG.voices.time = Conductor.songPosition;
                SONG.voices.play();
            }
        }
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
                    
                    if (SONG.chart.notes[curSection].changeBPM && SONG.chart.notes[curSection].bpm != Conductor.bpm)
                        Conductor.changeBPM(SONG.chart.notes[curSection].bpm);
                }

                if (sectionZooms)
                    hud.camHUD.zoom += 0.03;
		    }
        }
    }

    function countdownTick(ticks:Int) {
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
                    
                    if (SONG.chart.notes[0].changeBPM && SONG.chart.notes[0].bpm != Conductor.bpm)
                        Conductor.changeBPM(SONG.chart.notes[0].bpm);
                }
		}
    }
}