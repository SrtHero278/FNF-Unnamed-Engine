package copyPasted;

import flixel.FlxGame;
import flixel.FlxState;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
#if sys
import haxe.Log;
import haxe.CallStack;
import sys.io.File;
import sys.FileSystem;
import openfl.events.UncaughtErrorEvent;
import lime.app.Application;
#end
//It looks like everyone else is copy pasting this so I am too. (I think I know why tho)
//This is now a bit more updated to save logs. (Still mostly copy pasted tho)

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = menus.TitleState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		#if sys
		var normTrace = Log.trace;
		Log.trace = function(v:Dynamic, ?infos:haxe.PosInfos) {
			normTrace(v, infos);
			logStuff += Log.formatOutput(v, infos) + "\r\n";
		}

		Application.current.onExit.add(saveLog);

        Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, logError);
		#end

		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		addChild(new FlxGame(gameWidth, gameHeight, initialState, #if (flixel < "5.0.0") zoom, #end framerate, framerate, skipSplash, startFullscreen));

		#if !mobile
		addChild(new FPS(10, 3, 0xFFFFFF));
		#end
	}

	#if sys
	public static var logStuff:String = "";

	function saveLog(exitCode:Int) { //exit code param is just so onclose can work
		if (logStuff == "") return;
		if (!FileSystem.exists("./+savedLogs+"))
			FileSystem.createDirectory("./+savedLogs+");
		var date:String = "Log - " + DateTools.format(Date.now(), "%d-%m-%Y - %H-%M-%S");
		File.saveContent("./+savedLogs+/" + date + ".txt", logStuff);
		Sys.println("Saved " + date);
	}

	function logError(error:UncaughtErrorEvent) {
		logStuff += switch ([Std.isOfType(error.error, openfl.errors.Error), Std.isOfType(error.error, openfl.events.ErrorEvent), true].indexOf(true)) {
			case 0: "UH OH! Uncaught Error: " + cast(error.error, openfl.errors.Error).message + "\r\n";
			case 1: "UH OH! Uncaught Error: " + cast(error.error, openfl.events.ErrorEvent).text + "\r\n";
			default: "UH OH! Uncaught Error: " + error.error + "\r\n";
		}

		for (stackItem in CallStack.exceptionStack(true)) {
			switch (stackItem) {
                case CFunction: logStuff += "Called from C Function";
                case Module(module): logStuff += 'Called from $module (Module)';
                case FilePos(parent, file, line, col): logStuff += 'Called from $file on line $line';
                case LocalFunction(func): logStuff += 'Called from $func (Local Function)';
                case Method(clas, method): logStuff += 'Called from $clas - $method()';
			}
			logStuff += "\r\n";
		}

		saveLog(0);
	}
	#end
}