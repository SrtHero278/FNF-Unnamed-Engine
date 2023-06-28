package funkin;

import Paths;
import menus.ArrowSubState.StrumValues;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;

class Note extends flixel.FlxBasic {
    public var spawned:Bool = false;
    public var missed:Bool = false;

    public var strumTime:Float;
    public var sustainLength:Float;
    public var hittingSustain:Bool;

    public var arrow:FlxSprite;
    public var overlay:FlxSprite;
    public var hold:FlxSprite;
    public var holdOverlay:FlxSprite;
    public var tail:FlxSprite;
    public var tailOverlay:FlxSprite;

    public var spritesToRender:Array<FlxSprite> = [];

    public var hitAnim:String = "singLEFT";
    public var missAnim:String = "singLEFTmiss";

    public var color(default, set):FlxColor = 0xFFFFFFFF;
    function set_color(newColor:FlxColor) {
        for (sprite in [arrow, tail, hold]) {
            if (sprite != null)
                sprite.color = newColor;
        }

        return color = newColor;
    }

    public function new(StrumTime:Float, SustainLength:Float, noteColor:FlxColor, scrollSpeed:Float) {
        super();

        this.strumTime = StrumTime;
        this.sustainLength = SustainLength;

        if (sustainLength > 0) {
            initTail();

            if (sustainLength * scrollSpeed * 0.45 > tail.frameHeight)
                initHold();
        }

        arrow = new FlxSprite();
        arrow.frames = Paths.sparrowAtlas('noteskins/default/normal/NOTE_assets', 'UI');
        arrow.animation.addByPrefix('arrow', 'arrow0', 24, false);
        arrow.antialiasing = Options.antialiasing;
        arrow.animation.play('arrow');
        arrow.scale.set(0.7, 0.7);
        arrow.updateHitbox();

        overlay = new FlxSprite();
        overlay.frames = Paths.sparrowAtlas('noteskins/default/normal/NOTE_assets', 'UI');
        overlay.animation.addByPrefix('overlay', 'arrow overlay', 24, false);
        overlay.antialiasing = Options.antialiasing;
        overlay.animation.play('overlay');
        overlay.scale.set(0.7, 0.7);
        overlay.updateHitbox();

        spritesToRender.push(arrow);
        spritesToRender.push(overlay);

        color = noteColor;
    }

    function initHold() {
        hold = new FlxSprite();
        hold.frames = Paths.sparrowAtlas('noteskins/default/normal/NOTE_assets', 'UI');
        hold.animation.addByPrefix('hold', 'hold0', 24, false);
        hold.antialiasing = Options.antialiasing;
        hold.animation.play('hold');
        hold.scale.set(0.7, 1);
        hold.updateHitbox();

        holdOverlay = new FlxSprite();
        holdOverlay.frames = Paths.sparrowAtlas('noteskins/default/normal/NOTE_assets', 'UI');
        holdOverlay.animation.addByPrefix('overlay', 'hold overlay', 24, false);
        holdOverlay.antialiasing = Options.antialiasing;
        holdOverlay.animation.play('overlay');
        holdOverlay.scale.set(0.7, 1);
        holdOverlay.updateHitbox();

        spritesToRender.insert(2, holdOverlay); //The hold should always be at index 2.
        spritesToRender.insert(2, hold); // We do the overlay first for layering.
    }

    function initTail() {
        tail = new FlxSprite();
        tail.frames = Paths.sparrowAtlas('noteskins/default/normal/NOTE_assets', 'UI');
        tail.animation.addByPrefix('tail', 'tail0', 24, false);
        tail.antialiasing = Options.antialiasing;
        tail.animation.play('tail');
        tail.scale.set(0.7, 1);
        tail.updateHitbox();

        tailOverlay = new FlxSprite();
        tailOverlay.frames = Paths.sparrowAtlas('noteskins/default/normal/NOTE_assets', 'UI');
        tailOverlay.animation.addByPrefix('overlay', 'tail overlay', 24, false);
        tailOverlay.antialiasing = Options.antialiasing;
        tailOverlay.animation.play('overlay');
        tailOverlay.scale.set(0.7, 1);
        tailOverlay.updateHitbox();

        spritesToRender.insert(0, tailOverlay); //The tail should always be at index 0.
        spritesToRender.insert(0, tail); // We do the overlay first for layering.
    }

    public function updatePos(strumValues:StrumValues, distance:Float, scrollSpeed:Float) {
        var sinMult:Float = Math.sin((strumValues.direction % 360) * Math.PI / -180);
        var cosMult:Float = Math.cos((strumValues.direction % 360) * Math.PI / 180);

        arrow.x = strumValues.position[0] + distance * sinMult;
        arrow.y = strumValues.position[1] + distance * cosMult;
        if (arrow.scale != null) {
            arrow.scale.x = strumValues.scale[0];
            arrow.scale.y = strumValues.scale[1];
            arrow.angle = strumValues.angle;
            arrow.alpha = strumValues.alpha;
            overlay.x = arrow.x;
            overlay.y = arrow.y;
            overlay.scale.x = arrow.scale.x;
            overlay.scale.y = arrow.scale.y;
            overlay.angle = arrow.angle;
            overlay.alpha = arrow.alpha;
            arrow.updateHitbox();
            overlay.updateHitbox();
            arrow.offset.set(0.5 * arrow.frameWidth, 0.5 * arrow.frameHeight);
            overlay.offset.set(0.5 * overlay.frameWidth, 0.5 * overlay.frameHeight);
        }

        var daSustainLength:Float = sustainLength * scrollSpeed * 0.45;
        if (daSustainLength > 0) {
            if (tail == null)
                initTail();

            tail.origin.y = 0;
            tailOverlay.origin.y = 0;
            tail.offset.set(0.5 * tail.frameWidth, 0);
            tailOverlay.offset.set(0.5 * tailOverlay.frameWidth, 0);

            tail.angle = strumValues.direction;
            tailOverlay.angle = strumValues.direction;
            tail.alpha = arrow.alpha;
            tailOverlay.alpha = arrow.alpha;

            if (daSustainLength > tail.frameHeight && hold != null) {
                hold.origin.y = 0;
                holdOverlay.origin.y = 0;
                hold.offset.set(0.5 * hold.frameWidth, 0);
                holdOverlay.offset.set(0.5 * holdOverlay.frameWidth, 0);

                var holdHeight:Int = Math.floor((daSustainLength - arrow.frameHeight * 0.5 - tail.frameHeight) * (strumValues.scale[1] / 0.7));
                hold.setGraphicSize(
                    Math.floor(hold.frameWidth * strumValues.scale[0]),
                    holdHeight
                );
                holdOverlay.setGraphicSize(
                    Math.floor(holdOverlay.frameWidth * strumValues.scale[0]),
                    holdHeight
                );
                tail.setGraphicSize(
                    Math.floor(tail.frameWidth * strumValues.scale[0]),
                    Math.floor(tail.frameHeight * (strumValues.scale[1] / 0.7))
                );
                tailOverlay.setGraphicSize(
                    Math.floor(tailOverlay.frameWidth * strumValues.scale[0]),
                    Math.floor((tail.frameHeight - (tail.frameHeight - tailOverlay.frameHeight)) * (strumValues.scale[1] / 0.7))
                );

                hold.angle = strumValues.direction;
                holdOverlay.angle = strumValues.direction;
                hold.alpha = arrow.alpha;
                holdOverlay.alpha = arrow.alpha;

                hold.updateHitbox();
                holdOverlay.updateHitbox();

                hold.origin.y = 0;
                holdOverlay.origin.y = 0;
                hold.offset.set(0.5 * hold.frameWidth, 0);
                holdOverlay.offset.set(0.5 * holdOverlay.frameWidth, 0);

                if (hittingSustain) {
                    hold.x = strumValues.position[0];
                    hold.y = strumValues.position[1];
                } else {
                    hold.x = arrow.x;
                    hold.y = arrow.y;
                }

                holdOverlay.x = hold.x;
                holdOverlay.y = hold.y;

                tail.x = hold.x + hold.height * sinMult;
                tail.y = hold.y + hold.height * cosMult;
            } else {
                tail.setGraphicSize(
                    Math.floor(tail.frameWidth * strumValues.scale[0]),
                    Math.floor(daSustainLength * (strumValues.scale[1] / 0.7))
                );
                tailOverlay.setGraphicSize(
                    Math.floor(tailOverlay.frameWidth * strumValues.scale[0]),
                    Math.floor((daSustainLength - (tail.frameHeight - tailOverlay.frameHeight)) * (strumValues.scale[1] / 0.7))
                );

                tail.updateHitbox();
                tailOverlay.updateHitbox();

                tail.origin.y = 0;
                tailOverlay.origin.y = 0;
                tail.offset.set(0.5 * tail.frameWidth, 0);
                tailOverlay.offset.set(0.5 * tailOverlay.frameWidth, 0);
                
                if (hittingSustain) {
                    tail.x = strumValues.position[0];
                    tail.y = strumValues.position[1];
                } else {
                    tail.x = arrow.x;
                    tail.y = arrow.y;
                }
            }

            tailOverlay.x = tail.x;
            tailOverlay.y = tail.y;
        }
    }

    override public function update(elapsed:Float) {
        @:privateAccess for (sprite in spritesToRender)
            sprite.updateAnimation(elapsed); // We just need to update animation. None of the other shit.
    }

    override public function draw() {
        for (sprite in spritesToRender)
            sprite.draw();
    }
}