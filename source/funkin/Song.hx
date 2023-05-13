package funkin;

import flixel.FlxG;
import flixel.system.FlxSound;
import haxe.Json;
import lime.utils.Assets;

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
    var gfVersion:String;
	var stage:String;
}

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
	var typeOfSection:Int;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
}

class Song
{
	public var error:String = null;

	public var inst:FlxSound = new FlxSound();
	public var voices:FlxSound = new FlxSound();

	public var chart:SwagSong;
	public var fileName:String = "tutorial";

	public var scriptNames:Array<String> = [];

	public function new(fileSong:String, week:String, diff:String)
	{
		fileName = fileSong;
		if (Paths.fileExists(week + "/songs/" + fileSong + "/" + diff + '.json', 'weeks')) {
			var jsonText:String = Assets.getText(Paths.weekFile(week + "/songs/" + fileSong + "/" + diff + '.json')).trim();
			while (!jsonText.endsWith("}"))
				jsonText = jsonText.substr(0, jsonText.length - 1);

			try {
				chart = cast Json.parse(jsonText).song;
			} catch(parseFail) {
				error = 'Failed to parse song file.\n$parseFail';
				return;
			}

			inst.loadEmbedded(Paths.weekFile(week + "/songs/" + fileSong + "/Inst.ogg"));
			if (chart.needsVoices)
				voices.loadEmbedded(Paths.weekFile(week + "/songs/" + fileSong + "/Voices.ogg"));

			FlxG.sound.list.add(inst);
			FlxG.sound.list.add(voices);

			trace("LOADED SONG: " + chart.song);

			if (Paths.fileExists(week + "/songs/" + fileSong + '/scriptList.txt', 'weeks')) {
				var scriptNams:Array<String> = Assets.getText(Paths.weekFile(week + "/songs/" + fileSong + '/scriptList.txt')).split('\n');
				for (nam in scriptNams) {
					var name:String = nam.trim();
					if (Paths.fileExists(week + "/songs/" + fileSong + '/$name.lua', 'weeks'))
						scriptNames.push(Paths.weekFile(week + "/songs/" + fileSong + '/$name.lua'));
					else if (Paths.fileExists(week + "/songs/" + fileSong + '/$name', 'weeks'))
						scriptNames.push(Paths.weekFile(week + "/songs/" + fileSong + '/$name'));
				}
			}
		} else {
			error = "We couldn't find the json file for this song.";
		}
	}
}