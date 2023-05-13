local blammedColors = {0x31A2FD, 0x31FD8C, 0xFB33F5, 0xFD4531, 0xFBA633};
local curFrameX = 0;

function postCreate()
	makeSprite('cityLight', 27 * 0.85, -252 * 0.85, false);
	setGraphic('philly/lightCity');
	setScrollFactor(0.3, 0.3);
	resize('scale', 0.85, 0.85);
	setSpriteProperty('visible', false);
	setSpriteProperty('_frame.frame.width', 1551);
	insertSprite("spectator");
end

function beatHit()
	if curBeat == 128 then
		addZoom(0.03, 0.06);
		selectSprite("cityLight");
		setSpriteProperty("visible", true);
		setClassProperty("PlayState.player.color", 0x000000);
		setClassProperty("PlayState.opponent.color", 0x000000);
		setClassProperty("PlayState.player.alpha", 0.15);
		setClassProperty("PlayState.opponent.alpha", 0.15);
		setClassProperty("PlayState.spectator.visible", false);
	elseif curBeat == 192 then
		addZoom(0.03, 0.06);
		selectSprite("cityLight");
		spriteTween("fade", {alpha = 0}, 1);
		setClassProperty("PlayState.player.color", 0xFFFFFF);
		setClassProperty("PlayState.opponent.color", 0xFFFFFF);
		setClassProperty("PlayState.player.alpha", 1);
		setClassProperty("PlayState.opponent.alpha", 1);
		setClassProperty("PlayState.spectator.visible", true);
	end

	if curBeat % 4 == 0 and curBeat >= 128 and curBeat <= 192 then
		selectSprite("cityLight");
		setSpriteProperty("color", blammedColors[math.random(1, 5)]);
	end
end

local beats = {1, 4, 7};

function contains(table, value)
   for i, v in pairs(table) do
	 if v == value then
		return true;
	 end
   end
   return false;
end

function update(e)
   	if curBeat >= 128 and curBeat <= 192 then
		curFrameX = curFrameX - e * 250;
		if curStep % 4 < 2 and not contains(beats, curBeat % 8) then
			curFrameX = curFrameX - e * 1500;
		end
		curFrameX = curFrameX % 1551;
		selectSprite("cityLight");
		setSpriteProperty("_frame.frame.x", curFrameX);
	end
end