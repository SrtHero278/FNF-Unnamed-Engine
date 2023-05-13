local stageSwap = true;
local oldMustHit = true;
local isDesat = false;

--[[ dont uncomment. this was to test crashes.
function startSong()
	trace("haha time to break everything");
	setClassProperty("PlayState.spectator", nil);
end
]]--

function sectionHit()
	if sectionData.mustHitSection ~= oldMustHit and not sectionData.mustHitSection then
	   if isDesat then
		switchChar('opponent', 'bf-pixel');
		if stageSwap then
		   switchStage('stage');
		end
	   else
		switchChar('opponent', 'bf-pixel-desat');
		if stageSwap then
		   switchStage('stage-desat');
		end
	   end
	   isDesat = not (isDesat);
	end
	oldMustHit = sectionData.mustHitSection;

	selectSprite("PlayState.hud.iconP1");
	setSpriteProperty("angle", 45);
	spriteTween("resetAngle", {angle = 0}, crochet / 1000, "circOut");

	setClassProperty("PlayState.hud.strums.members[4].daValues.angle", 45);
	classTween("resetAngle2", "PlayState.hud.strums.members[4].daValues", {angle = 0}, crochet / 1000, "circOut");

	selectSprite("PlayState.instance.player");
	setSpriteProperty("angle", 45);
	spriteTween("resetAngle3", {angle = 0}, crochet / 1000, "circOut");
end