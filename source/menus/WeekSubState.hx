package menus;

import funkin.FocusedPlayState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import lime.utils.Assets;

import Paths;
import funkin.PlayState;
import copyPasted.MusicBeat;

using StringTools;

class WeekSubState extends MusicBeatSubstate
{
    var selectWeek:Bool = true;
    var weeks:Array<String> = [];
    var curWeek:Int = 0;
    var songs:Array<String> = [];
    var curSong:Int = 0;
    var diffs:Array<String> = ["easy", "normal", "hard"];
    var diffColors:Array<Int> = [0xFF00FF55, 0xFFFFFF00, 0xFFFF0037];
    var curDiff:Int = 1;

    var banner:FlxSprite;
    var weekBG:FlxSprite;
    var weekIcon:FlxSprite;

    var player:FlxSprite;
    var spectator:FlxSprite;
    var opponent:FlxSprite;

    var naviInfo:FlxText;
    var tracks:FlxText;
    var includeZero:Bool = false;

    public function new() {
        super();

        for (line in Assets.getText(Paths.weekFile('weekList.txt')).split('\n')) {
            if (line.startsWith("?includeZero"))
                includeZero = (line.trim().endsWith("true"));
            else
                weeks.push(line.trim());
        }

        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		add(bg);
        FlxTween.tween(bg, {alpha: 0.6}, 0.25, {ease: FlxEase.quartInOut});

		banner = new FlxSprite(0, 56);
        banner.antialiasing = true;
        add(banner);

        weekBG = new FlxSprite(0, 475).makeGraphic(FlxG.width, 120, FlxColor.BLACK);
        add(weekBG);

		weekIcon = new FlxSprite(0, 475);
        weekIcon.antialiasing = true;
        weekIcon.screenCenter(X);
        add(weekIcon);

        naviInfo = new FlxText(0, 450, FlxG.width, '[UP/DOWN] - Scroll Through Weeks | [LEFT/RIGHT] - Switch Difficulty (Current: NORMAL)', 20);
        naviInfo.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
        naviInfo.color = 0xFFFFFF00;
        add(naviInfo);

        tracks = new FlxText(0, 600, FlxG.width, "Week 1/6 | [ENTER] - Full Week | [SPACE] - Select Specific Song\n\nTutorial", 20);
        tracks.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
        add(tracks);

        player = new FlxSprite(1000, 185);
        player.antialiasing = true;
        add(player);

        spectator = new FlxSprite(650, 100);
        spectator.antialiasing = true;
        add(spectator);

        opponent = new FlxSprite(50, 56);
        opponent.antialiasing = true;
        add(opponent);

        loadWeek();
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        var boolIndex = [
            FlxG.keys.justPressed.ESCAPE,
            FlxG.keys.justPressed.UP,
            FlxG.keys.justPressed.DOWN,
            FlxG.keys.justPressed.LEFT,
            FlxG.keys.justPressed.RIGHT,
            FlxG.keys.justPressed.SPACE,
            FlxG.keys.justPressed.ENTER
        ].indexOf(true);

        switch (boolIndex) {
            case 0:
                FlxG.sound.play(Paths.menuFile('title/sounds/cancel.ogg'), 0.5);
                close();
            case 1 | 2:
                var inc = -1 + 2 * (boolIndex - 1); //Fucc If Statements.
                if (selectWeek) {
                    curWeek = (curWeek + weeks.length + inc) % weeks.length;
                    loadWeek();
                } else {
                    curSong = (curSong + songs.length + inc) % songs.length;
                    selectSong();
                }
            case 3 | 4:
                var inc = -1 + 2 * (boolIndex - 3); //Fucc If Statements.
                setDiff((curDiff + diffs.length + inc) % diffs.length);
                FlxG.sound.play(Paths.menuFile('sounds/scroll.ogg'), 1);
            case 5:
                selectWeek = !selectWeek;
                curSong = 0;
    
                if (selectWeek)
                    loadWeek();
                else
                    selectSong();
            case 6:
                var songList = (selectWeek) ? songs : [songs[curSong]];
                if (Options.focused)
                    FocusedPlayState.songData = [songList, [weeks[curWeek], diffs[curDiff].toLowerCase()]];
                else 
                    PlayState.songData = [songList, [weeks[curWeek], diffs[curDiff].toLowerCase()]];

                FlxG.sound.play(Paths.menuFile('title/sounds/titleShoot.ogg'), 1);
                FlxG.sound.music.stop();
    
                var flashy:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
                flashy.alpha = 0;
                add(flashy);
    
                FlxTween.tween(flashy, {alpha: 1}, 0.1, {ease: FlxEase.circOut});
                FlxTween.color(flashy, 4.5, 0xFFFFFFFF, 0xFF000000, {ease: FlxEase.linear, 
                    onComplete: function(twn:FlxTween) {
                        if (FlxG.state.subState == this) //I found out you can exit the substate during this.
                            FlxG.switchState((Options.focused) ? new FocusedPlayState() : new PlayState());
                    }, startDelay: 0.1});
        }
    }

    public function loadWeek() {
        FlxG.sound.play(Paths.menuFile('sounds/scroll.ogg'), 1);
        
        diffs = ["easy", "normal", "hard"];
        diffColors = [0xFF00FF55, 0xFFFFFF00, 0xFFFF0037];
        curDiff = 1;

        banner.loadGraphic(Paths.weekFile(weeks[curWeek] + '/banner'));
        weekIcon.loadGraphic(Paths.weekFile(weeks[curWeek] + '/icon'));
        weekIcon.y = 535 - weekIcon.height / 2;
        weekIcon.screenCenter(X);

        player.visible = true;
        player.scale.set(0.565, 0.565);
        player.updateHitbox();
        player.x = 1000;
        player.y = 205;
        
        spectator.visible = true;
        spectator.scale.set(0.5, 0.5);
        spectator.updateHitbox();
        spectator.x = 650;
        spectator.y = 100;

        opponent.visible = true;
        opponent.scale.set(0.5, 0.5);
        opponent.updateHitbox();
        opponent.x = 50;
        opponent.y = 56;

        var weekData:Array<String> = Assets.getText(Paths.weekFile(weeks[curWeek] + '/data.txt')).split('\n');
        var hiddenSongs:Array<String> = [];
        for (i in 0...weekData.length) {
			if (weekData[i] != null && weekData[i].length > 0) {
				var commandArray:Array<String> = [for (line in weekData[i].split(":")) line.trim()];
				switch (commandArray[0]) {
					case "songOrder":
						songs = [for (song in commandArray[1].split(",")) song.trim()];

                    case "diffs" | "difficulties":
                        diffs = [];
                        diffColors = [];
                        var daDiffs = [for (diff in commandArray[1].split(",")) diff.trim()];
                        for (diff in daDiffs) {
                            var splitDiff = diff.split("--");
                            diffs.push(splitDiff[0]);
                            diffColors.push(FlxColor.fromString(splitDiff[1].trim()));
                        }

					case "nonDisplayedSongs" | "hiddenSongs":
						hiddenSongs = [for (song in commandArray[1].split(",")) song.trim()];

					case "player" | "playerData":
						switch (commandArray[1]) {
							case "visible":
								player.visible = (commandArray[2] == "true");
							case "position":
								var pos:Array<String> = commandArray[2].split(",");
								player.x = Std.parseFloat(pos[0].trim());
								player.y = Std.parseFloat(pos[1].trim());
							case "scale":
								player.scale.set(Std.parseFloat(commandArray[2]), Std.parseFloat(commandArray[2]));
						}

					case "spectator" | "spectatorData":
						switch (commandArray[1]) {
							case "visible":
								spectator.visible = (commandArray[2] == "true");
							case "position":
								var pos:Array<String> = commandArray[2].split(",");
								spectator.x = Std.parseFloat(pos[0].trim());
								spectator.y = Std.parseFloat(pos[1].trim());
							case "scale":
								spectator.scale.set(Std.parseFloat(commandArray[2]), Std.parseFloat(commandArray[2]));
						}

					case "opponent" | "opponentData":
						switch (commandArray[1]) {
							case "visible":
								opponent.visible = (commandArray[2] == "true");
							case "position":
								var pos:Array<String> = commandArray[2].split(",");
								opponent.x = Std.parseFloat(pos[0].trim());
								opponent.y = Std.parseFloat(pos[1].trim());
							case "scale":
								opponent.scale.set(Std.parseFloat(commandArray[2]), Std.parseFloat(commandArray[2]));
						}
				}
			}
        }

        if (includeZero)
            tracks.text = "Week: " + curWeek + "/" + (weeks.length - 1);
        else
            tracks.text = "Week: " + (curWeek + 1) + "/" + weeks.length;

        tracks.text += " | [ENTER] - Play Full Week | [SPACE] - Select Specific Song\n\n";
        for (song in 0...songs.length) {
            if (!hiddenSongs.contains(songs[song]))
                tracks.text += songs[song] + "\n";
        }

        if (player.visible) {
            if (Paths.fileExists(weeks[curWeek] + '/player.png', 'weeks'))
                player.frames = Paths.sparrowAtlas(weeks[curWeek] + '/player', 'weeks');
            else
                player.frames = Paths.sparrowAtlas('tutorial/player', 'weeks');
            player.animation.addByPrefix('idle', 'idle', 24);
            player.animation.play('idle');
            player.updateHitbox();
        }

        if (spectator.visible) {
            if (Paths.fileExists(weeks[curWeek] + '/spectator.png', 'weeks'))
                spectator.frames = Paths.sparrowAtlas(weeks[curWeek] + '/spectator', 'weeks');
            else
                spectator.frames = Paths.sparrowAtlas('tutorial/spectator', 'weeks');
            spectator.animation.addByPrefix('idle', 'idle', 24);
            spectator.animation.play('idle');
            spectator.updateHitbox();
        }

        if (opponent.visible) {
            if (Paths.fileExists(weeks[curWeek] + '/opponent.png', 'weeks'))
                opponent.frames = Paths.sparrowAtlas(weeks[curWeek] + '/opponent', 'weeks');
            else
                opponent.frames = Paths.sparrowAtlas('week1/opponent', 'weeks');
            opponent.animation.addByPrefix('idle', 'idle', 24);
            opponent.animation.play('idle');
            opponent.updateHitbox();
        }

        setDiff(Math.floor(diffs.length / 2));
    }

    public function selectSong() {
        FlxG.sound.play(Paths.menuFile('sounds/scroll.ogg'), 1);

        if (includeZero)
            tracks.text = "Week: " + curWeek + "/" + (weeks.length - 1);
        else
            tracks.text = "Week: " + (curWeek + 1) + "/" + weeks.length;

        tracks.text += " | [ENTER] - Play Song | [SPACE] - Back to Week Selection\n\n";

        for (song in 0...songs.length) {
            if (curSong == song)
                tracks.text += ">>> " + songs[song] + " <<<\n";
            else
                tracks.text += songs[song] + "\n";
        }
    }

    public function setDiff(toSet:Int = 1) {
        curDiff = toSet;
        
        var scrollThrough:String = (selectWeek) ? "Weeks" : "Songs";

        naviInfo.text = '[UP/DOWN] - Scroll Through $scrollThrough | [LEFT/RIGHT] - Switch Difficulty (Current: ${diffs[curDiff].toUpperCase()})';
        naviInfo.color = diffColors[curDiff];
    }
}