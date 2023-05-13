package;

import flixel.group.FlxGroup.FlxTypedGroup;
import menus.ArrowSubState.StrumValues;

import haxe.Json;
#if sys
import sys.io.File;
#else
import lime.utils.Assets;
#end

class Options {
    public static var opponentNotes:Array<StrumValues>;
    public static var playerNotes:Array<StrumValues>;
    public static var keybinds:Array<String>;

    public static var ghostTapping:Bool = true;
    public static var inputOffset:Int = 0;
    public static var accType:String = "rating";

    public static var canSwitchToUnpreloadedChars:Bool = true;
    public static var canSwitchStages:Bool = true;
    public static var antialiasing:Bool = true;
    public static var focused:Bool = false;

    static var defaults:Map<String, Dynamic> = [
        "opponentNotes" => [
            {position: [100, 50], scale: [0.7, 0.7], angle: 0, direction: 0, alpha: 1, color: "C24B99"}, 
            {position: [210, 50], scale: [0.7, 0.7], angle: 270, direction: 0, alpha: 1, color: "00FFFF"}, 
            {position: [320, 50], scale: [0.7, 0.7], angle: 90, direction: 0, alpha: 1, color: "12FA05"}, 
            {position: [430, 50], scale: [0.7, 0.7], angle: 180, direction: 0, alpha: 1, color: "F9393F"}
        ],
        "playerNotes" => [
            {position: [740, 50], scale: [0.7, 0.7], angle: 0, direction: 0, alpha: 1, color: "C24B99"}, 
            {position: [850, 50], scale: [0.7, 0.7], angle: 270, direction: 0, alpha: 1, color: "00FFFF"}, 
            {position: [960, 50], scale: [0.7, 0.7], angle: 90, direction: 0, alpha: 1, color: "12FA05"}, 
            {position: [1070, 50], scale: [0.7, 0.7], angle: 180, direction: 0, alpha: 1, color: "F9393F"}
        ],
        "keybinds" => ["A", "S", "W", "D"],

        "ghostTapping" => true,
        "inputOffset" => 0,
        "accType" => "rating",
        
        "canSwitchToUnpreloadedChars" => true,
        "canSwitchStages" => true,
        "antialiasing" => true,
        "focused" => false
    ];

    public static function resetOptions() {
        resetOptionCatagory("notefield");
        resetOptionCatagory("gameplay");
        resetOptionCatagory("optimization");
    }

    public static function resetOptionCatagory(catagory:String) {
        #if sys
        var parsedJson = cast Json.parse(File.getContent("assets/settings/" + catagory + ".json"));
        #else
        var parsedJson = cast Json.parse(Assets.getText("assets/settings/" + catagory + ".json"));
        #end
        switch (catagory) {
            case "notefield":
                opponentNotes = (parsedJson.opponentNotes != null && parsedJson.opponentNotes.length >= 4) ? parsedJson.opponentNotes : defaults.get("opponentNotes");
                playerNotes = (parsedJson.playerNotes != null && parsedJson.playerNotes.length >= 4) ? parsedJson.playerNotes : defaults.get("playerNotes");
                keybinds = (parsedJson.keybinds != null && parsedJson.keybinds.length >= 4) ? parsedJson.keybinds : defaults.get("keybinds");
            case "gameplay":
                if (parsedJson.ghostTapping == null) parsedJson.ghostTapping = defaults.get("ghostTapping"); //It's annoying that I have to do the if statement like this.
                ghostTapping = parsedJson.ghostTapping;
                if (parsedJson.inputOffset == null) parsedJson.inputOffset = defaults.get("inputOffset");
                inputOffset = parsedJson.inputOffset;
                if (parsedJson.accType == null) parsedJson.accType = defaults.get("accType");
                accType = parsedJson.accType;
            case "optimization":
                if (parsedJson.canSwitchToUnpreloadedChars == null) parsedJson.canSwitchToUnpreloadedChars = defaults.get("canSwitchToUnpreloadedChars");
                canSwitchToUnpreloadedChars = parsedJson.canSwitchToUnpreloadedChars;
                if (parsedJson.canSwitchStages == null) parsedJson.canSwitchStages = defaults.get("canSwitchStages");
                canSwitchStages = parsedJson.canSwitchStages;
                if (parsedJson.antialiasing == null) parsedJson.antialiasing = defaults.get("antialiasing");
                antialiasing = parsedJson.antialiasing;
                if (parsedJson.focused == null) parsedJson.focused = defaults.get("focused");
                focused = parsedJson.focused;
        }
    }
}