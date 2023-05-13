package funkin;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;
import lime.utils.Assets;
import vm.lua.LuaVM;

import Options;
import funkin.PlayState;
import copyPasted.Conductor;

using StringTools;

class FNFLua {
	var stateInstance:PlayState;

	public var selectedSprite:FlxSprite;
	public var selectedSound:FlxSound;

	public var filePath:String;
	public var state:LuaVM;

	public var error:String;

	public function new(scriptFile:String, playState:PlayState) {
		stateInstance = playState;

		filePath = scriptFile;
		state = new LuaVM();
		try {
			state.run(Assets.getText(scriptFile));
		} catch(e) {
			error = 'Lua error on $scriptFile\n' + Std.string(e);
			return;
		}

		state.setGlobalVar("filePath", scriptFile);

		state.setGlobalVar("curBeat", 0); //IDK what to call these vars.
		state.setGlobalVar("curStep", 0);
		state.setGlobalVar("sectionData", {sectionNotes: [], lengthInSteps: 16, typeOfSection: 0, mustHitSection: false, bpm: 100, changeBPM: false, altAnim: false});
		state.setGlobalVar("tweenTypes", {PERSIST: 1, LOOPING: 2, PINGPONG: 4, ONESHOT: 8, BACKWARD: 16});

		state.setGlobalVar("crochet", Conductor.crochet); // Conductor vars.
		state.setGlobalVar("stepCrochet", Conductor.stepCrochet);
		state.setGlobalVar("songPos", Conductor.songPosition);
		state.setGlobalVar("bpm", Conductor.bpm);

		state.setGlobalVar('trace', function(text:String) {
			var daPath = stateInstance.curScriptPath;
			copyPasted.Main.logStuff += '$daPath: $text\r\n';
			Sys.println('$daPath: $text');
		});

		state.setGlobalVar('random', function(type:String, min:Float, max:Float, exclude:Array<Float>):Dynamic {
			if (type == "int" || type == "interger") {
				if (exclude != null && exclude.length > 0) {
					var newExclude:Array<Int> = [];

					for (number in 0...exclude.length)
						newExclude.push(Std.int(exclude[number]));

					return FlxG.random.int(Std.int(min), Std.int(max), newExclude);
				}
				return FlxG.random.int(Std.int(min), Std.int(max));
			} else if (type == "float") {
				return FlxG.random.float(min, max, exclude);
			} else {
				return FlxG.random.bool(min);
			}
		});
		state.setGlobalVar("getClassProperty", function(property:String):Dynamic {
			var splitArray:Array<String> = property.split('.');
			if (property.startsWith("PlayState.instance"))
				splitArray.splice(1, 1);
			return dumbPropertyLoop(splitArray);
		});
		state.setGlobalVar("setClassProperty", function(property:String, newValue:Dynamic) {
			var splitArray:Array<String> = property.split('.');
			if (property.startsWith("PlayState.instance"))
				splitArray.splice(1, 1);
			var propertyToSet:String = splitArray.pop();
			blockableSetProperty(dumbPropertyLoop(splitArray), propertyToSet, newValue);
		});
		state.setGlobalVar("classTween", function(tag:String, tweenObject:String, vars:Dynamic, duration:Float, ?ease:String, ?tweenType:FlxTweenType = FlxTweenType.ONESHOT) {
			stateInstance.luaTweens.set(tag, FlxTween.tween(dumbPropertyLoop(tweenObject.split(".")), vars, duration, {ease: stringToEase(ease), onComplete: function(twn:FlxTween) {
				if (tweenType != 2 && tweenType != 4)
					stateInstance.luaTweens.remove(tag);
				stateInstance.luaCall(tag + "_finished", []);
			}, type: tweenType}));
		});

		state.setGlobalVar('insertChar', function(char:String, x:Float, y:Float) { // Stage stuff.
			stateInstance.addChar(char, x, y);
		});
		state.setGlobalVar('setDefaultZoom', function(value:Float) {
			stateInstance.defaultZoom = value;
		});
		state.setGlobalVar("addZoom", function(?gameZoom:Float = 0.015, ?hudZoom:Float = 0.03) {
			FlxG.camera.zoom += gameZoom;
			stateInstance.hud.camHUD.zoom += hudZoom;
		});
		state.setGlobalVar('camOffsets', function(char:String, xOffset:Float, yOffset:Float) {
			switch (char) {
				case "player" | "boyfriend" | "bf":
					stateInstance.camOffsets[0] = xOffset;
					stateInstance.camOffsets[1] = yOffset;
				case "spectator" | "girlfriend" | "gf":
					stateInstance.camOffsets[2] = xOffset;
					stateInstance.camOffsets[3] = yOffset;
				case "opponent" | "dad":
					stateInstance.camOffsets[4] = xOffset;
					stateInstance.camOffsets[5] = yOffset;
			}
		});

		state.setGlobalVar('makeSprite', function(name:String, x:Float, y:Float, ?autoAdd:Bool = true) { // Sprite stuff. Disabling autoAdd is mainly for placing sprites behind characters that have been inserted already.
			var daSprite:FlxSprite = new FlxSprite(x, y);
			daSprite.antialiasing = Options.antialiasing;
			stateInstance.luaSprites.set(name, daSprite);
			if (autoAdd)
				stateInstance.gameObjects.add(daSprite);
			selectedSprite = daSprite;
		});
		state.setGlobalVar("selectSprite", function(name:String) {
			if (name.startsWith("PlayState.")) {
				//I would of liked to use substring but lastIndexOf just HAD TO NOT WORK. also i had to do a dumb property loop.
				var splitArray:Array<String> = name.split('.');
				if (name.startsWith("PlayState.instance"))
					splitArray.splice(1, 1);
				selectedSprite = dumbPropertyLoop(splitArray);
			} else
				selectedSprite = stateInstance.luaSprites.get(name);
		});
		state.setGlobalVar("insertSprite", function(insertType:String) {
			switch (insertType) {
				case "player" | "boyfriend" | "bf":
					stateInstance.gameObjects.insert(stateInstance.gameObjects.members.indexOf(stateInstance.player), selectedSprite);
				case "spectator" | "girlfriend" | "gf":
					stateInstance.gameObjects.insert(stateInstance.gameObjects.members.indexOf(stateInstance.spectator), selectedSprite);
				case "opponent" | "dad":
					stateInstance.gameObjects.insert(stateInstance.gameObjects.members.indexOf(stateInstance.opponent), selectedSprite);
				case "none":
					stateInstance.gameObjects.add(selectedSprite);
				case "permanentFront":
					stateInstance.add(selectedSprite);
				case "permanentBack":
					stateInstance.insert(stateInstance.members.indexOf(stateInstance.gameObjects), selectedSprite);
			}
		});
		state.setGlobalVar("removeSprite", function(?delete:Bool = true) {
			if (stateInstance.gameObjects.members.indexOf(selectedSprite) >= 0)
				stateInstance.gameObjects.remove(selectedSprite, true);
			else if (stateInstance.members.indexOf(selectedSprite) >= 0)
				stateInstance.remove(selectedSprite, true);
			if (delete) {
				selectedSprite.destroy();
				selectedSprite = null;
			}
		});
		state.setGlobalVar('setGraphic', function(file:String, ?xGrid:Int = 0, ?yGrid:Int = 0, ?library:String = "stages") {
			if (xGrid > 0 && yGrid > 0)
				selectedSprite.loadGraphic(Paths.getFile('assets/$library/$file'), true, xGrid, yGrid);
			else
				selectedSprite.loadGraphic(Paths.getFile('assets/$library/$file'));
		});
		state.setGlobalVar("setFrames", function(file:String, ?spriteType:String = "sparrow", ?library:String = "stages") {
			if (spriteType == "sparrow")
				selectedSprite.frames = Paths.sparrowAtlas(file, library);
			else if (spriteType == "packer")
				selectedSprite.frames = Paths.packerAtlas(file, library);
		});
		state.setGlobalVar("addGridAnim", function(animName:String, daFrames:Array<Int>, ?fps:Int = 24, ?loop:Bool = false) {
			selectedSprite.animation.add(animName, daFrames, fps, loop);
		});
		state.setGlobalVar("addPrefixAnim", function(animName:String, prefix:String, ?fps:Int = 24, ?loop:Bool = false) {
			selectedSprite.animation.addByPrefix(animName, prefix, fps, loop);
		});
		state.setGlobalVar("addIndiceAnim", function(animName:String, prefix:String, indices:Array<Int>, ?fps:Int = 24, ?loop:Bool = false) {
			selectedSprite.animation.addByIndices(animName, prefix, indices, '', fps, loop);
		});
		state.setGlobalVar("playAnim", function(name:String, ?forced:Bool = false, ?reversed:Bool = false, ?startFrame:Int = 0) {
			selectedSprite.animation.play(name, forced, reversed, startFrame);
		});
		state.setGlobalVar("resize", function(type:String, x:Float, y:Float, ?updateHitbox:Bool = true) {
			if (type == "scale")
				selectedSprite.scale.set(x, y);
			else if (type == "graphicSize")
				selectedSprite.setGraphicSize(Std.int(x),Std.int(y));
			if (updateHitbox)
				selectedSprite.updateHitbox();
		});
		state.setGlobalVar("setScrollFactor", function(x:Float, y:Float) {
			selectedSprite.scrollFactor.set(x, y);
		});
		state.setGlobalVar("updateHitbox", function() {
			selectedSprite.updateHitbox();
		});
		state.setGlobalVar("getSpriteProperty", function(field:String):Dynamic {
			switch (field) {
				case "x": return selectedSprite.x;
				case "y": return selectedSprite.y;
				case "scrollFactor.x": return selectedSprite.scrollFactor.x;
				case "scrollFactor.y": return selectedSprite.scrollFactor.y;
				case "scale.x": return selectedSprite.scale.x;
				case "scale.y": return selectedSprite.scale.y;
				case "width": return selectedSprite.width;
				case "height": return selectedSprite.height;
				case "frameWidth": return selectedSprite.frameWidth;
				case "frameHeight": return selectedSprite.frameHeight;
				case "position": return [selectedSprite.x, selectedSprite.y];
				case "scrollFactor": return [selectedSprite.scrollFactor.x, selectedSprite.scrollFactor.y];
				case "scale": return [selectedSprite.scale.x, selectedSprite.scale.y];
				case "size": return [selectedSprite.width, selectedSprite.height];
				case "frameSize": return [selectedSprite.frameWidth, selectedSprite.frameHeight];
				default: return dumbPropertyLoop(field.split("."), selectedSprite);
			}
		});
		state.setGlobalVar("setSpriteProperty", function(field:String, newValue:Dynamic) {
			switch (field) {
				case "x": selectedSprite.x = newValue;
				case "y": selectedSprite.y = newValue;
				case "scrollFactor.x": selectedSprite.scrollFactor.x = newValue;
				case "scrollFactor.y": selectedSprite.scrollFactor.y = newValue;
				case "scale.x": selectedSprite.scale.x = newValue;
				case "scale.y": selectedSprite.scale.y = newValue;
				case "position": selectedSprite.setPosition(newValue[0], newValue[1]);
				case "scrollFactor": selectedSprite.scrollFactor.set(newValue[0], newValue[1]);
				case "scale": selectedSprite.scale.set(newValue[0], newValue[1]);
				default:
					var splitArray:Array<String> = field.split('.');
					var propertyToSet:String = splitArray.pop();
					blockableSetProperty(dumbPropertyLoop(splitArray, selectedSprite), propertyToSet, newValue);
			}
		});
		state.setGlobalVar("spriteTween", function(tag:String, vars:Dynamic, duration:Float, ?ease:String, ?tweenType:FlxTweenType = FlxTweenType.ONESHOT) {
			stateInstance.luaTweens.set(tag, FlxTween.tween(selectedSprite, vars, duration, {ease: stringToEase(ease), onComplete: function(twn:FlxTween) {
				if (tweenType != 2 && tweenType != 4) stateInstance.luaTweens.remove(tag);
				stateInstance.luaCall(tag + "_finished", []);
			}, type: tweenType}));
		});

		state.setGlobalVar("makeSound", function(name:String) { // Sound stuff.
			stateInstance.luaSounds.set(name, new FlxSound());
			selectedSound = stateInstance.luaSounds.get(name);
			FlxG.sound.list.add(selectedSound);
		});
		state.setGlobalVar("selectSound", function(name:String) {
			if (stateInstance.luaSounds.exists(name))
				selectedSound = stateInstance.luaSounds.get(name);
		});
		state.setGlobalVar("playSound", function(file:String, ?volume:Float = 1, ?looped:Bool = false, ?library:String = "stages") { //Would of liked to make it so you have to load the sound first but the sound had a problem loading the embed without playing it.
			if (selectedSound.playing) {
				selectedSound.volume = volume;
				selectedSound.play(true);
			} else {
				selectedSound.loadEmbedded(Paths.getFile('assets/$library/$file'), looped);
				selectedSound.volume = volume;
				selectedSound.play();
			}
		});
		state.setGlobalVar("pauseSound", function() {
			selectedSound.pause();
		});
		state.setGlobalVar("getSoundProperty", function(field:String):Dynamic {
			switch (field) {
				case "x": return selectedSound.x;
				case "y": return selectedSound.y;
				case "time": return selectedSound.time;
				case "length": return selectedSound.length;
				case "playing": return selectedSound.playing;
				case "volume": return selectedSound.volume;
				default: return dumbPropertyLoop(field.split("."), selectedSound);
			}
		});
		state.setGlobalVar("setSoundProperty", function(field:String, newValue:Dynamic) {
			switch (field) {
				case "x": selectedSound.x = newValue;
				case "y": selectedSound.y = newValue;
				case "time": selectedSound.time = newValue;
				case "volume": selectedSound.volume = newValue;
				default:
					var splitArray:Array<String> = field.split('.');
					var propertyToSet:String = splitArray.pop();
					Reflect.setProperty(dumbPropertyLoop(splitArray, selectedSound), propertyToSet, newValue);
			}
		});

		state.setGlobalVar("startTimer", function(name:String, seconds:Float = 1, ?loops:Int = 1) {
			var daTimer:FlxTimer = new FlxTimer().start(seconds, function(tmr:FlxTimer) {
				if(tmr.finished) {
					stateInstance.luaTimers.remove(name);
				}
				stateInstance.luaCall(name + "_finished", [tmr.loops, tmr.loopsLeft]);
			}, loops);

			stateInstance.luaTimers.set(name, daTimer);
		});

		state.setGlobalVar("charPlayAnim", function(char:String, animName:String, ?forced:Bool = false, ?reversed:Bool = false, ?startFrame:Int = 0) {
			if (char == "player" || char == "boyfriend" || char == "bf")
				stateInstance.player.playAnim(animName, forced, reversed, startFrame);
			else if (char == "spectator" || char == "girlfriend" || char == "gf")
				stateInstance.spectator.playAnim(animName, forced, reversed, startFrame);
			else if (char == "opponent" || char == "dad")
				stateInstance.opponent.playAnim(animName, forced, reversed, startFrame);
		});
		state.setGlobalVar("switchChar", function(char:String, name:String) {
			stateInstance.switchChar(char, name);
		});
		state.setGlobalVar("switchStage", function(name:String) {
			stateInstance.loadStage(name);
		});

		stateInstance.curScriptPath = filePath;
		state.call("create", []);
	}

	function stringToEase(?ease:String = '') {
		switch(ease.toLowerCase().trim()) {
			case 'backin': return FlxEase.backIn;
			case 'backinout': return FlxEase.backInOut;
			case 'backout': return FlxEase.backOut;
			case 'bouncein': return FlxEase.bounceIn;
			case 'bounceinout': return FlxEase.bounceInOut;
			case 'bounceout': return FlxEase.bounceOut;
			case 'circin': return FlxEase.circIn;
			case 'circinout': return FlxEase.circInOut;
			case 'circout': return FlxEase.circOut;
			case 'cubein': return FlxEase.cubeIn;
			case 'cubeinout': return FlxEase.cubeInOut;
			case 'cubeout': return FlxEase.cubeOut;
			case 'elasticin': return FlxEase.elasticIn;
			case 'elasticinout': return FlxEase.elasticInOut;
			case 'elasticout': return FlxEase.elasticOut;
			case 'expoin': return FlxEase.expoIn;
			case 'expoinout': return FlxEase.expoInOut;
			case 'expoout': return FlxEase.expoOut;
			case 'quadin': return FlxEase.quadIn;
			case 'quadinout': return FlxEase.quadInOut;
			case 'quadout': return FlxEase.quadOut;
			case 'quartin': return FlxEase.quartIn;
			case 'quartinout': return FlxEase.quartInOut;
			case 'quartout': return FlxEase.quartOut;
			case 'quintin': return FlxEase.quintIn;
			case 'quintinout': return FlxEase.quintInOut;
			case 'quintout': return FlxEase.quintOut;
			case 'sinein': return FlxEase.sineIn;
			case 'sineinout': return FlxEase.sineInOut;
			case 'sineout': return FlxEase.sineOut;
			case 'smoothstepin': return FlxEase.smoothStepIn;
			case 'smoothstepinout': return FlxEase.smoothStepInOut;
			case 'smoothstepout': return FlxEase.smoothStepInOut;
			case 'smootherstepin': return FlxEase.smootherStepIn;
			case 'smootherstepinout': return FlxEase.smootherStepInOut;
			case 'smootherstepout': return FlxEase.smootherStepOut;
			default: return FlxEase.linear;
		}
	}

	//Shadow Mario, I see why you do this now. getProperty really is trash.
	function dumbPropertyLoop(array:Array<String>, ?includedItem:Dynamic):Dynamic {
		var item:Dynamic = includedItem;
		if (item == null) {
			var start:Array<String> = [array.shift()];
			item = (start[0] == "PlayState") ? stateInstance : Type.resolveClass(start[0]);
			while (item == null) {
				start.push(array.shift());
				item = Type.resolveClass(start.join('.'));
			}
		}
		while (array.length > 0) {
			var thing:String = array.shift();
			if (thing.endsWith("]")) {
				var arrayNum:Int = Std.parseInt(thing.substring(thing.lastIndexOf("[") + 1, thing.indexOf("]")));
				thing = thing.substring(0, thing.indexOf("["));
				item = Reflect.getProperty(item, thing)[arrayNum];
			} else
				item = Reflect.getProperty(item, thing);
		}

		return item;
	}

	function blockableSetProperty(item:Dynamic, property:String, value:Dynamic) {
		var propIndex:Int = [
			"antialiasing",
			"focused",
			"canSwitchStages",
			"canSwitchToUnpreloadedChars",
			"inputOffset",
			"canPreload",
			property
		].indexOf(property);
		var values:Array<Dynamic> = [
			(value && Options.antialiasing), 
			Options.focused, 
			Options.canSwitchStages, 
			Options.canSwitchToUnpreloadedChars,
			Options.inputOffset,
			stateInstance.canPreload,
			value
		];
		Reflect.setProperty(item, property, values[propIndex]);
	}
}
