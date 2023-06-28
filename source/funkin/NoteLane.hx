package funkin;

import Paths;
import Options;
import funkin.Note;
import funkin.FocusedPlayState.BareBonesPlayState;
import copyPasted.Conductor;
import copyPasted.MusicBeat;
import menus.ArrowSubState.StrumValues;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class NoteLane extends FlxTypedGroup<FlxBasic> {
    
    private var stateInstance:BareBonesPlayState;

    var ghostTween:FlxTween;

    public var strum:FlxSprite;
    public var strumOverlay:FlxSprite;
    public var hittingSustain:Bool = false;
    public var holding:Bool = false;
    public var notes:FlxTypedGroup<Note> = new FlxTypedGroup<Note>();
    public var unspawnNotes:Array<Note> = [];

    public var daValues:StrumValues = {position: [155, 105], scale: [0.7, 0.7], angle: 0, direction: 0, alpha: 1, color: "FFFFFF"};
    private var ghostScale:Float = 0.0;
    public var keybinds:Array<Int> = null; //Set it to null for opponent notes.
    public var colors:Array<FlxColor> = [0xFF87A3AD];
    var ghostColor:FlxColor;

    public var char:Character;
    public var missAnim:String = "singLEFTmiss"; //For ghost tapping. Annoying thing is that I had to make this var public.

    public function new(values:StrumValues, keys:Array<Int>, Char:Character, instance:BareBonesPlayState) {
        super(0);

        stateInstance = instance;

        daValues = values;

        colors.push(Paths.colorFromString(values.color));
        colors.push(FlxColor.fromHSL(colors[1].hue, colors[1].saturation, colors[1].lightness + 0.35));
        var ghostSat:Float = (colors[1].saturation >= 0.45) ? 0.45 : colors[1].saturation - 0.1;
        colors.push(FlxColor.fromHSB(colors[1].hue, ghostSat, 0.75));
        this.keybinds = keys;
        this.char = Char;

        strum = new FlxSprite(values.position[0], values.position[1]);
        strum.frames = Paths.sparrowAtlas('noteskins/default/normal/NOTE_assets', "UI");
        strum.animation.addByPrefix('static', 'arrow0', 24, false);
        strum.animation.addByPrefix('glow', 'glow', 24, false);
        strum.scale.set(values.scale[0], values.scale[1]);
        strum.antialiasing = Options.antialiasing;
        strum.animation.play('static');
        strum.angle = values.angle;
        strum.alpha = values.alpha;
        strum.color = colors[0];
        strum.updateHitbox();
        strum.offset.set(0.5 * strum.frameWidth, 0.5 * strum.frameHeight);
        add(strum);

        strum.animation.finishCallback = (name:String) -> {
            if (name == "glow" && keybinds == null)
                resetStrum();
        }

        strumOverlay = new FlxSprite(strum.x, strum.y);
        strumOverlay.frames = Paths.sparrowAtlas('noteskins/default/normal/NOTE_assets', "UI");
        strumOverlay.animation.addByPrefix('overlay', 'strum overlay', 24, false);
        strumOverlay.scale.set(values.scale[0], values.scale[1]);
        strumOverlay.antialiasing = Options.antialiasing;
        strumOverlay.animation.play('overlay');
        strumOverlay.angle = values.angle;
        strumOverlay.alpha = values.alpha;
        strumOverlay.updateHitbox();
        strumOverlay.offset.set(0.5 * strumOverlay.frameWidth, 0.5 * strumOverlay.frameHeight);
        add(strumOverlay);

        add(notes);
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (unspawnNotes[0] != null && unspawnNotes[0].strumTime - Conductor.songPosition < 2000) {
			var spawningNote:Note = unspawnNotes[0];
            spawningNote.spawned = true;
			notes.add(spawningNote);

			unspawnNotes.splice(0, 1);
		}
        notes.forEach(function(note:Note) {
            note.updatePos(daValues, stateInstance.SONG.chart.speed * -0.45 * (Conductor.songPosition - note.strumTime), stateInstance.SONG.chart.speed);

            if (note.strumTime - Conductor.songPosition + Options.inputOffset < -stateInstance.hud.rateValues[0][0] && !note.hittingSustain) {
                if (keybinds != null && (note.sustainLength >= 35 || note.sustainLength <= 0)) { //I'll be kind with the holds. I'll ignore it if you released a few milliseconds too early.
                    stateInstance.hud.combo = 0;
                    stateInstance.hud.score -= 50;
                    stateInstance.hud.misses++;
                    stateInstance.health -= 0.0475;
                    stateInstance.hud.updateRank();
                }
                notes.remove(note, true);
                char.playAnim(note.missAnim);
                removeNotePart(note, "note");
                removeNotePart(note, "hold");
                removeNotePart(note, "tail");
                note.destroy();
            }
        });

        if (keybinds != null && holding) {
            hold(elapsed);
        } else if (keybinds == null) {
            notes.forEach(function(note:Note) {
                if (Math.abs(note.strumTime - Conductor.songPosition + Options.inputOffset) <= 45) {
                    if (note.sustainLength <= 0) {
                        removeNotePart(note, "note");
                        notes.remove(note, true);
                        note.destroy();
                    } else {
                        removeNotePart(note, "note");
                        note.sustainLength -= elapsed * 1000;
                        note.hittingSustain = true;
                        if (note.sustainLength * stateInstance.SONG.chart.speed * 0.675 <= note.tail.frameHeight)
                            removeNotePart(note, "hold");
                        if (note.sustainLength <= 0) {
                            removeNotePart(note, "tail");
                            notes.remove(note, true);
                            note.destroy();
                        }
                    }

                    strum.animation.play('glow');
                    strum.color = colors[2];
                    strumOverlay.visible = false;
                    resetValues();

                    char.playAnim(note.hitAnim, true);

                    if (stateInstance.hitEnablesZoom)
                        stateInstance.sectionZooms = true;
                } else if (note.sustainLength > 0 && note.hittingSustain) {
                    note.sustainLength -= elapsed * 1000;
                    if (note.sustainLength * stateInstance.SONG.chart.speed * 0.675 <= note.tail.frameHeight)
                        removeNotePart(note, "hold");
                    if (note.sustainLength <= 0) {
                        removeNotePart(note, "tail");
                        notes.remove(note, true);
                        note.destroy();
                    }

                    strum.animation.play('glow');
                    strum.color = colors[2];
                    strumOverlay.visible = false;

                    char.playAnim(note.hitAnim, true);
                }
            });
        }

        resetValues();
    }

    public function press() {
        notes.forEach(function(note:Note) {
            if (Math.abs(note.strumTime - Conductor.songPosition + Options.inputOffset) <= stateInstance.hud.rateValues[0][0]) {
                if (note.sustainLength <= 0) {
                    removeNotePart(note, "note");
                    notes.remove(note, true);
                    note.destroy();
                } else {
                    removeNotePart(note, "note");
                    note.sustainLength -= FlxG.elapsed * 1000;
                    if (note.sustainLength * stateInstance.SONG.chart.speed * 0.675 <= note.tail.frameHeight)
                        removeNotePart(note, "hold");
                    if (note.sustainLength <= 0) {
                        removeNotePart(note, "tail");
                        notes.remove(note, true);
                        note.destroy();
                    }
                }
                hittingSustain = true;
                note.hittingSustain = true;

                strum.animation.play('glow');
                strum.color = colors[2];
                strumOverlay.visible = false;
                resetValues();

                if (stateInstance.hitEnablesZoom)
                    stateInstance.sectionZooms = true;
                char.playAnim(note.hitAnim, true);

                stateInstance.hud.combo++;
                stateInstance.hud.rating(note.strumTime - Conductor.songPosition + Options.inputOffset);
            }
        });
        if (!hittingSustain) { // Ghost tapping
            ghostTween = FlxTween.tween(this, {ghostScale: 0.05}, 0.1, {ease: FlxEase.linear});
            strum.animation.play('static');
            strum.color = colors[3];
            if (!Options.ghostTapping) {
                char.playAnim(missAnim);
                stateInstance.hud.combo = 0;
                stateInstance.hud.score -= 10;
                stateInstance.hud.misses++;
                stateInstance.health -= 0.025;
                stateInstance.hud.updateRank();
            }
        }

        holding = true;
    }

    public function release() {
        hittingSustain = false;
        holding = false;
        notes.forEach(function(note:Note) {
            if (note.hittingSustain)
                note.hittingSustain = false;
        });
        resetStrum();
    }

    public function hold(elapsed:Float) {
        notes.forEach(function(note:Note) {
            if (note.sustainLength > 0 && note.hittingSustain) {
                note.sustainLength -= elapsed * 1000;
                if (note.sustainLength * stateInstance.SONG.chart.speed * 0.675 <= note.tail.frameHeight)
                    removeNotePart(note, "hold");
                if (note.sustainLength <= 0) {
                    removeNotePart(note, "tail");
                    notes.remove(note, true);
                    note.destroy();
                }

                strum.animation.play('glow');
                strum.color = colors[2];
                strumOverlay.visible = false;

                char.playAnim(note.hitAnim, true);
            }
        });
    }

    function resetValues() {
        strum.scale.set(daValues.scale[0] - ghostScale, daValues.scale[1] - ghostScale);
        strum.updateHitbox();
        strum.offset.set(0.5 * strum.frameWidth, 0.5 * strum.frameHeight);
        strum.x = daValues.position[0];
        strum.y = daValues.position[1];
        strum.angle = daValues.angle;
        strum.alpha = daValues.alpha;

        strumOverlay.scale.set(strum.scale.x, strum.scale.y);
        strumOverlay.updateHitbox();
        strumOverlay.offset.set(0.5 * strumOverlay.frameWidth, 0.5 * strumOverlay.frameHeight);
        strumOverlay.x = strum.x;
        strumOverlay.y = strum.y;
        strumOverlay.angle = strum.angle;
        strumOverlay.alpha = strum.alpha;
    }

    public function resetStrum() {
        if (ghostTween != null)
            ghostTween.cancel();
	    ghostScale = 0;
        strum.animation.play('static');
        strum.color = colors[0];

        strumOverlay.visible = true;

        resetValues();
    }

    public function removeNotePart(note:Note, part:String) {
        switch (part) {
            case "note":
                if (note.arrow != null) {
                    note.arrow.destroy();
                    note.overlay.destroy();
                    note.spritesToRender.remove(note.arrow);
                    note.spritesToRender.remove(note.overlay);
                }
            case "hold":
                if (note.hold != null) {
                    note.hold.destroy();
                    note.holdOverlay.destroy();
                    note.spritesToRender.remove(note.hold);
                    note.spritesToRender.remove(note.holdOverlay);
                    note.hold = null;
                    note.holdOverlay = null;
                }
            case "tail":
                if (note.tail != null) {
                    note.tail.destroy();
                    note.tailOverlay.destroy();
                    note.spritesToRender.remove(note.tail);
                    note.spritesToRender.remove(note.tailOverlay);
                    note.tail = null;
                    note.tailOverlay = null;
                }
        }
    }
    
    override public function destroy() {
        for (note in unspawnNotes) {
            removeNotePart(note, "tail");
            removeNotePart(note, "hold");
            removeNotePart(note, "note");
            unspawnNotes.splice(unspawnNotes.indexOf(note), 1);
            note.destroy();
        }

        notes.forEach(function(note:Note) {
            removeNotePart(note, "tail");
            removeNotePart(note, "hold");
            removeNotePart(note, "note");
        });
        notes.destroy();

        super.destroy();
    }
}