package;

import flixel.util.FlxColor;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

//I had to write this from scratch because of how different the assets are.

class Paths
{
    public static var allMods:Array<String> = [];
    public static var curMod:String;

	inline public static function colorFromString(color:String):FlxColor {
        if (!color.startsWith("0x") && !color.startsWith("#"))
            return FlxColor.fromString("#" + color);
        return FlxColor.fromString(color);
    }

	inline public static function getFile(file:String):String {
        if (OpenFlAssets.exists('$file.png'))
            return '$file.png';
        else if (OpenFlAssets.exists('$file.ogg'))
            return '$file.ogg';
        else
            return file;
    }

	inline public static function fileExists(file:String, library:String):Bool {
        return OpenFlAssets.exists('assets/$library/$file');
    }

	inline public static function charFile(file:String):String {
        return getFile('assets/characters/$file');
    }

    inline public static function sceneFile(file:String):String {
        return getFile('assets/cutscenes/$file');
    }

    inline public static function font(file:String) {
        return 'assets/fonts/$file'; // This is for fonts so of cource im not checking for pngs and oggs.
    }

    inline public static function menuFile(file:String):String {
        return getFile('assets/menus/$file');
    }

    inline public static function stageFile(file:String):String {
        return getFile('assets/stages/$file');
    }

    inline public static function uiFile(file:String):String {
        return getFile('assets/UI/$file');
    }

    inline public static function weekFile(file:String):String {
        return getFile('assets/weeks/$file');
    }

    inline public static function sparrowAtlas(file:String, library:String):FlxAtlasFrames {
        return FlxAtlasFrames.fromSparrow('assets/$library/$file.png', OpenFlAssets.getText('assets/$library/$file.xml'));
    }
    
    inline public static function packerAtlas(file:String, library:String):FlxAtlasFrames {
        return FlxAtlasFrames.fromSpriteSheetPacker('assets/$library/$file.png', OpenFlAssets.getText('assets/$library/$file.txt'));
    }
}