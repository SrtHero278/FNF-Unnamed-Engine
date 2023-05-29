package funkin;

import Paths;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxTileFrames;
import flixel.graphics.frames.FlxFramesCollection;
import lime.utils.Assets;

using StringTools;

typedef CharAnimation =
{
	var prefix:String;
	var offset:Array<Int>;
	var indices:Array<Int>;
    var fps:Int;
    var loop:Bool;
}

class MinimizedCharacter {
    public var sprite:FlxSprite;
    public var anims:Map<String, CharAnimation>;
    public var spriteType:String;

    public var deathAnimations:Map<String, CharAnimation> = new Map();
    public var deadFrames:FlxFramesCollection;
    public var deadAnimType:String;

    public var icon:FlxSprite;

    public function new(sprite:FlxSprite, anims:Map<String, CharAnimation>, spriteType:String,
    deathAnimations:Map<String, CharAnimation>, deadFrames:FlxFramesCollection, deadAnimType:String, icon:FlxSprite) {
        this.sprite = sprite;
        this.anims = anims;
        this.spriteType = spriteType;
    
        this.deathAnimations = deathAnimations;
        this.deadFrames = deadFrames;
        this.deadAnimType = deadAnimType;
    
        this.icon = icon;
    }
}

class Character extends FlxSprite {

    public var error:String = null;

    public var oldOffsets:Array<Float> = [0, 0];
    public var cameraPos:FlxPoint = new FlxPoint();

    var spriteType:String;
    public var anims:Map<String, CharAnimation> = new Map();

    public var deathAnimations:Map<String, CharAnimation> = new Map();
    public var deadFrames:FlxFramesCollection;
    public var deathAnimsOnly:Bool = false;
    var deadAnimType:String;
    
    public var healthBarGraphic:FlxGraphic;
    public var healthColor:FlxColor;
    public var icon:FlxSprite;
    var iconAnimType:String;

	public function new(x:Float, y:Float) {
		super(x, y);
		icon = new FlxSprite();
		anims = new Map();
		deathAnimations = new Map();
	}

    public function loadCharacter(char:String, isPlayer:Bool = false, stageCamOffsets:Array<Float>):MinimizedCharacter {
        if (Paths.fileExists(char + '/data.txt', 'characters') && !deathAnimsOnly) {
            var charData:Array<String> = Assets.getText(Paths.charFile(char + '/data.txt')).split('\n');
            animation.destroyAnimations();
            anims.clear();
            deathAnimations.clear();
            deadFrames = null;

            healthColor = 0xFF808080;

            flipX = false;
            flipY = false;
            antialiasing = Options.antialiasing;
            scale.set(1, 1);
            x -= oldOffsets[0];
            y -= oldOffsets[1];

            cameraPos.set(getMidpoint().x + 150 + stageCamOffsets[0], getMidpoint().y - 100 + stageCamOffsets[1]);
            if (isPlayer)
                cameraPos.x -= 250;
            
            for (i in 0...charData.length) {
				if (charData[i] != null && charData[i].length > 0) {
					var commandArray:Array<String> = [for (line in charData[i].split(":")) line.trim()];
					switch (commandArray[0]) {
						case "frames":
							if (Paths.fileExists(commandArray[2] + '.png', 'characters')) {
								spriteType = commandArray[1];
								if (commandArray[1] == "sparrow")
									if (Paths.fileExists(commandArray[2] + '.xml', 'characters'))
										frames = Paths.sparrowAtlas(commandArray[2], 'characters');
									else
										error = "We couldn't find the xml for your character's spritesheet. Please make sure it exists and is spelled properly.";
								else if (commandArray[1] == "packer")
									if (Paths.fileExists(commandArray[2] + '.txt', 'characters'))
										frames = Paths.packerAtlas(commandArray[2], 'characters');
									else
										error = "We couldn't find the txt for your character's spritesheet. Please make sure it exists and is spelled properly.";
								else if (commandArray[1] == "grid")
									loadGraphic(Paths.charFile(commandArray[2]), true, Std.parseInt(commandArray[3]), Std.parseInt(commandArray[4]));

								updateHitbox();
							} else {
								error = "We couldn't find the png for your character's spritesheet. Please make sure it exists and is spelled properly.";
							}
							if (error != null)
								return null;
						case "anims":
							if (commandArray[1] == "add" && spriteType != "grid") {
								var daAnim:CharAnimation = {
									prefix: 'idle',
									offset: [0, 0],
									indices: [],
									fps: 24,
									loop: false
								};
								if (commandArray[6] != null && commandArray[6].length > 0) {
									var stringIndices:Array<String> = commandArray[6].split(',');
									var intIndices:Array<Int> = [];
									for (i in 0...stringIndices.length) {
										intIndices.push(Std.parseInt(stringIndices[i]));
									}

									animation.addByIndices(commandArray[2], commandArray[3], intIndices, '', 24, false);

									daAnim.prefix = commandArray[3];
									daAnim.offset = [Std.parseInt(commandArray[4]), Std.parseInt(commandArray[5])];
									daAnim.indices = intIndices;
									anims.set(commandArray[2], daAnim);
								} else {
									animation.addByPrefix(commandArray[2], commandArray[3], 24, false);

									daAnim.prefix = commandArray[3];
									daAnim.offset = [Std.parseInt(commandArray[4]), Std.parseInt(commandArray[5])];
									anims.set(commandArray[2], daAnim);
								}
							} else if (commandArray[1] == "add" && spriteType == "grid") {
								var stringIndices:Array<String> = commandArray[3].split(',');
								var intIndices:Array<Int> = [];
								for (i in 0...stringIndices.length) {
									intIndices.push(Std.parseInt(stringIndices[i]));
								}

								animation.add(commandArray[2], intIndices, 24, false);

								var daAnim:CharAnimation = {
									prefix: null,
									offset: [0, 0],
									indices: [],
									fps: 24,
									loop: false
								};
								daAnim.offset = [Std.parseInt(commandArray[4]), Std.parseInt(commandArray[5])];
								daAnim.indices = intIndices;
								anims.set(commandArray[2], daAnim);
							} else if (commandArray[1] == "extra" && spriteType != "grid") {
								var daAnim:CharAnimation = anims.get(commandArray[2]);
								if (anims.exists(commandArray[2]) && daAnim.indices.length < 1) {
									animation.addByPrefix(commandArray[2], daAnim.prefix, Std.parseInt(commandArray[3]),
										(commandArray[4] == "true") ? true : false);
									daAnim.fps = Std.parseInt(commandArray[3]);
									daAnim.loop = (commandArray[4] == "true");
									anims.set(commandArray[2], daAnim);
								} else if (anims.exists(commandArray[2]) && daAnim.indices.length > 0) {
									animation.addByIndices(commandArray[2], daAnim.prefix, daAnim.indices, '', Std.parseInt(commandArray[3]),
										(commandArray[4] == "true") ? true : false);
									daAnim.fps = Std.parseInt(commandArray[3]);
									daAnim.loop = (commandArray[4] == "true");
									anims.set(commandArray[2], daAnim);
								}
							} else if (commandArray[1] == "extra" && spriteType == "grid") {
								var daAnim:CharAnimation = anims.get(commandArray[2]);
								if (anims.exists(commandArray[2])) {
									animation.add(commandArray[2], daAnim.indices, Std.parseInt(commandArray[3]), (commandArray[4] == "true") ? true : false);
									daAnim.fps = Std.parseInt(commandArray[3]);
									daAnim.loop = (commandArray[4] == "true");
									anims.set(commandArray[2], daAnim);
								}
							}
						case "dead":
							switch (commandArray[1]) {
								case "frames":
									deadAnimType = commandArray[2];
									if (commandArray[2] == "sparrow") deadFrames = Paths.sparrowAtlas(commandArray[3],
										'characters'); else if (commandArray[2] == "packer") deadFrames = Paths.packerAtlas(commandArray[3],
										'characters'); else if (commandArray[2] == "grid")
										deadFrames = FlxTileFrames.fromGraphic(FlxGraphic.fromAssetKey(Paths.charFile(commandArray[3])),
										FlxPoint.get(Std.parseInt(commandArray[4]), Std.parseInt(commandArray[5])));
								case "firstDeath" | "deathLoop" | "deathConfirm":
									if (deadAnimType != "grid") {
										var daAnim:CharAnimation = {
											prefix: 'idle',
											offset: [0, 0],
											indices: [],
											fps: 24,
											loop: false
										};
										if (commandArray[5] != null && commandArray[5].length > 0) {
											var stringIndices:Array<String> = commandArray[5].split(',');
											var intIndices:Array<Int> = [];
											for (i in 0...stringIndices.length) {
												intIndices.push(Std.parseInt(stringIndices[i]));
											}

											// animation.addByIndices(commandArray[1], commandArray[2], intIndices, '', 24, false);

											daAnim.prefix = commandArray[2];
											daAnim.offset = [Std.parseInt(commandArray[3]), Std.parseInt(commandArray[4])];
											daAnim.indices = intIndices;
											deathAnimations.set(commandArray[1], daAnim);
										} else {
											// animation.addByPrefix(commandArray[1], commandArray[2], 24, false);

											daAnim.prefix = commandArray[2];
											daAnim.offset = [Std.parseInt(commandArray[3]), Std.parseInt(commandArray[4])];
											deathAnimations.set(commandArray[1], daAnim);
										}
									} else {
										var stringIndices:Array<String> = commandArray[2].split(',');
										var intIndices:Array<Int> = [];
										for (i in 0...stringIndices.length) {
											intIndices.push(Std.parseInt(stringIndices[i]));
										}

										// animation.add(commandArray[1], intIndices, 24, false);

										var daAnim:CharAnimation = {
											prefix: null,
											offset: [0, 0],
											indices: [],
											fps: 24,
											loop: false
										};
										daAnim.offset = [Std.parseInt(commandArray[3]), Std.parseInt(commandArray[4])];
										daAnim.indices = intIndices;
										deathAnimations.set(commandArray[1], daAnim);
									}
							}
						case "offset":
							oldOffsets = [Std.parseFloat(commandArray[1]), Std.parseFloat(commandArray[2])];
							x += Std.parseFloat(commandArray[1]);
							y += Std.parseFloat(commandArray[2]);

							cameraPos.set(getMidpoint().x + 150 + stageCamOffsets[0], getMidpoint().y - 100 + stageCamOffsets[1]);
							if (isPlayer)
								cameraPos.x -= 250;

							cameraPos.x += Std.parseFloat(commandArray[3]);
							cameraPos.y += Std.parseFloat(commandArray[4]);
						case "healthColor":
							switch (commandArray[1]) {
								case "hex" | "hexadecimal":
									healthColor = Paths.colorFromString(commandArray[2]);
								case "rgb" | "redGreenBlue":
									var stringVals = [for (val in commandArray[2].split(',')) val.trim()];

									var vals:Array<Int> = [Std.parseInt(stringVals[0]), Std.parseInt(stringVals[1]), Std.parseInt(stringVals[2])];
									healthColor = FlxColor.fromRGB(vals[0], vals[1], vals[2]);
								case "hsv" | "hsb" | "hueSaturationValue" | "hueSaturationBrightness":
									var stringVals = [for (val in commandArray[2].split(',')) val.trim()];

									var vals:Array<Float> = [
										Std.parseFloat(stringVals[0]),
										Std.parseFloat(stringVals[1]),
										Std.parseFloat(stringVals[2])
									];
									if (vals[1] > 1)
										vals[1] = vals[1] / 100;
									if (vals[2] > 1)
										vals[2] = vals[2] / 100;
									healthColor = FlxColor.fromHSB(vals[0], vals[1], vals[2]);
								case "hsl" | "hueSaturationLightness":
									var stringVals = [for (val in commandArray[2].split(',')) val.trim()];

									var vals:Array<Float> = [
										Std.parseFloat(stringVals[0]),
										Std.parseFloat(stringVals[1]),
										Std.parseFloat(stringVals[2])
									];
									if (vals[1] > 1)
										vals[1] = vals[1] / 100;
									if (vals[2] > 1)
										vals[2] = vals[2] / 100;
									healthColor = FlxColor.fromHSL(vals[0], vals[1], vals[2]);
							}
						case "icon":
							switch (commandArray[1]) {
								case "frames":
									iconAnimType = commandArray[2];
									if (commandArray[2] == "sparrow") icon.frames = Paths.sparrowAtlas(commandArray[3],
										'characters'); else if (commandArray[2] == "packer") icon.frames = Paths.packerAtlas(commandArray[3],
										'characters'); else if (commandArray[2] == "grid") icon.loadGraphic(Paths.charFile(commandArray[3] + ".png"), true,
										Std.parseInt(commandArray[4]), Std.parseInt(commandArray[5]));
								case "winning" | "normal" | "losing":
									if (iconAnimType != "grid") {
										icon.animation.addByPrefix(commandArray[1], commandArray[2], 24, true);
									} else {
										var stringIndices:Array<String> = commandArray[2].split(',');
										var intIndices:Array<Int> = [];
										for (i in 0...stringIndices.length) {
											intIndices.push(Std.parseInt(stringIndices[i]));
										}

										icon.animation.add(commandArray[1], intIndices, 24, true);
									}
							}
						case "mirror":
							flipX = (commandArray[1] == "true");
							flipY = (commandArray[2] == "true");
						case "pixelized":
							antialiasing = false;
						case "scale":
							scale.set(Std.parseFloat(commandArray[1]), Std.parseFloat(commandArray[1]));
					}
				}
            }
            
            updateHitbox();

            if (Paths.fileExists(char + "/healthBar.png", "characters"))
                healthBarGraphic = FlxGraphic.fromAssetKey(Paths.charFile(char + "/healthBar.png"), false, Paths.charFile(char + "/healthBar.png"), false);
            else
                healthBarGraphic = FlxGraphic.fromAssetKey(Paths.uiFile("defaultHealthBar.png"), false, Paths.uiFile("defaultHealthBar.png"), false);

            if (icon.numFrames <= 0) {
                icon.loadGraphic(Paths.uiFile("unknownIcon.png"), true, 150, 150);
                icon.animation.add("winning", [0], 24, true);
                icon.animation.add("normal", [0], 24, true);
                icon.animation.add("losing", [1], 24, true);
            }

            if (!deathAnimations.exists("firstDeath") || !deathAnimations.exists("deathLoop") || !deathAnimations.exists("deathConfirm") || deadFrames == null) {
                deadFrames = Paths.sparrowAtlas('bf/BOYFRIEND_DEAD', 'characters');
                deadAnimType = "sparrow";

                var startAnim:CharAnimation = {prefix:'BF dies', offset:[37, 11], indices:[], fps:24, loop:false};
                var loopAnim:CharAnimation = {prefix:'BF Dead Loop', offset:[37, 5], indices:[], fps:24, loop:true};
                var confirmAnim:CharAnimation = {prefix:'BF Dead confirm', offset:[37, 69], indices:[], fps:24, loop:false};

                deathAnimations.set('firstDeath', startAnim);
                deathAnimations.set('deathLoop', loopAnim);
                deathAnimations.set('deathConfirm', confirmAnim);
            }

            if (isPlayer)
                flipX = !flipX;

            dance(true);

            return new MinimizedCharacter(clone(), anims, spriteType, deathAnimations, deadFrames, deadAnimType, icon.clone());
        } else if (!deathAnimsOnly) {
            return loadCharacter('bf', isPlayer, stageCamOffsets);
        }
        return new MinimizedCharacter(clone(), anims, spriteType, deathAnimations, deadFrames, deadAnimType, icon.clone());
    }

    public function loadMinimized(char:String, minChar:MinimizedCharacter, isPlayer:Bool, stageCamOffsets:Array<Float>) {
        if (Paths.fileExists(char + '/data.txt', 'characters') && !deathAnimsOnly) {
            loadGraphicFromSprite(minChar.sprite);
            anims = minChar.anims;
            spriteType = minChar.spriteType;

            deathAnimations = minChar.deathAnimations;
            deadFrames = minChar.deadFrames;
            deadAnimType = minChar.deadAnimType;

            icon.loadGraphicFromSprite(minChar.icon);

            healthColor = 0xFF808080;

            flipX = false;
            flipY = false;
            antialiasing = Options.antialiasing;
            scale.set(1, 1);
            x -= oldOffsets[0];
            y -= oldOffsets[1];

            cameraPos.set(getMidpoint().x + 150 + stageCamOffsets[0], getMidpoint().y - 100 + stageCamOffsets[1]);
            if (isPlayer)
                cameraPos.x -= 250;
            
            var charData:Array<String> = Assets.getText(Paths.charFile(char + '/data.txt')).split('\n');
            for (i in 0...charData.length) {
				if (charData[i] != null && charData[i].length > 0) {
					var commandArray:Array<String> = [for (line in charData[i].split(":")) line.trim()];
					switch (commandArray[0]) {
						case "offset":
							oldOffsets = [Std.parseFloat(commandArray[1]), Std.parseFloat(commandArray[2])];
							x += Std.parseFloat(commandArray[1]);
							y += Std.parseFloat(commandArray[2]);

							cameraPos.set(getMidpoint().x + 150 + stageCamOffsets[0], getMidpoint().y - 100 + stageCamOffsets[1]);
							if (isPlayer)
								cameraPos.x -= 250;

							cameraPos.x += Std.parseFloat(commandArray[3]);
							cameraPos.y += Std.parseFloat(commandArray[4]);
						case "healthColor":
							switch (commandArray[1]) {
								case "hex" | "hexadecimal":
									healthColor = Paths.colorFromString(commandArray[2]);
								case "rgb" | "redGreenBlue":
									var stringVals = [for (val in commandArray[2].split(',')) val.trim()];

									var vals:Array<Int> = [Std.parseInt(stringVals[0]), Std.parseInt(stringVals[1]), Std.parseInt(stringVals[2])];
									healthColor = FlxColor.fromRGB(vals[0], vals[1], vals[2]);
								case "hsv" | "hsb" | "hueSaturationValue" | "hueSaturationBrightness":
									var stringVals = [for (val in commandArray[2].split(',')) val.trim()];

									var vals:Array<Float> = [
										Std.parseFloat(stringVals[0]),
										Std.parseFloat(stringVals[1]),
										Std.parseFloat(stringVals[2])
									];
									if (vals[1] > 1)
										vals[1] = vals[1] / 100;
									if (vals[2] > 1)
										vals[2] = vals[2] / 100;
									healthColor = FlxColor.fromHSB(vals[0], vals[1], vals[2]);
								case "hsl" | "hueSaturationLightness":
									var stringVals = [for (val in commandArray[2].split(',')) val.trim()];

									var vals:Array<Float> = [
										Std.parseFloat(stringVals[0]),
										Std.parseFloat(stringVals[1]),
										Std.parseFloat(stringVals[2])
									];
									if (vals[1] > 1)
										vals[1] = vals[1] / 100;
									if (vals[2] > 1)
										vals[2] = vals[2] / 100;
									healthColor = FlxColor.fromHSL(vals[0], vals[1], vals[2]);
							}
						case "mirror":
							flipX = (commandArray[1] == "true");
							flipY = (commandArray[2] == "true");
						case "pixelized":
							antialiasing = false;
						case "scale":
							scale.set(Std.parseFloat(commandArray[1]), Std.parseFloat(commandArray[1]));
					}
				}
            }
            
            updateHitbox();

            if (Paths.fileExists(char + "/healthBar.png", "characters"))
                healthBarGraphic = FlxGraphic.fromAssetKey(Paths.charFile(char + "/healthBar.png"), false, Paths.charFile(char + "/healthBar.png"), false);
            else
                healthBarGraphic = FlxGraphic.fromAssetKey(Paths.uiFile("defaultHealthBar.png"), false, Paths.uiFile("defaultHealthBar.png"), false);

            if (isPlayer)
                flipX = !flipX;

            dance(true);
        }
    }

    public function oofOwieMyBones() {
        deathAnimsOnly = true;

        animation.destroyAnimations();
        frames = deadFrames;
        anims = deathAnimations;
        spriteType = deadAnimType;

        if (spriteType != "grid") {
            if (anims.get("firstDeath").indices.length > 0)
                animation.addByIndices("firstDeath", anims.get("firstDeath").prefix, anims.get("firstDeath").indices, '', 24, false);
            else
                animation.addByPrefix("firstDeath", anims.get("firstDeath").prefix, 24, false);

            if (anims.get("deathLoop").indices.length > 0)
                animation.addByIndices("deathLoop", anims.get("deathLoop").prefix, anims.get("deathLoop").indices, '', 24, true);
            else
                animation.addByPrefix("deathLoop", anims.get("deathLoop").prefix, 24, true);

            if (anims.get("deathConfirm").indices.length > 0)
                animation.addByIndices("deathConfirm", anims.get("deathConfirm").prefix, anims.get("deathConfirm").indices, '', 24, false);
            else
                animation.addByPrefix("deathConfirm", anims.get("deathConfirm").prefix, 24, false);
        } else {
            animation.add("firstDeath", anims.get("firstDeath").indices, 24, false);
            animation.add("deathLoop", anims.get("deathLoop").indices, 24, true);
            animation.add("deathConfirm", anims.get("deathConfirm").indices, 24, false);
        }

        animation.play("firstDeath", true);
        var daOffsets:Array<Int> = anims.get("firstDeath").offset;
        offset.set(daOffsets[0], daOffsets[1]);
    }

    public function playAnim(name:String, forced:Bool = false, reversed:Bool = false, startFrame:Int = 0) {
        if (anims.exists(name) && (name.startsWith('death') || !deathAnimsOnly)) {
            animation.play(name, forced, reversed, startFrame);
            var daOffsets:Array<Int> = anims.get(name).offset;
            offset.set(daOffsets[0], daOffsets[1]);
        } else if (name.endsWith("-alt"))
            playAnim(name.substr(0, name.indexOf("-alt")), forced, reversed, startFrame);
    }

    public function dance(evenBeat:Bool) {
        if (animation.curAnim == null || animation.curAnim.name == "idle" || animation.curAnim.name == "danceLeft" || animation.curAnim.name == "danceRight" || animation.curAnim.finished) {
            if (anims.exists('danceLeft') && anims.exists('danceRight')) {
                if (evenBeat)
                    playAnim('danceLeft', true);
                else
                    playAnim('danceRight', true);
            } else if (evenBeat) {
                playAnim('idle', true);
            }
        }
    }
}