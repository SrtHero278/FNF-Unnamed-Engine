local curLight = 0;
local trainMoving = false;
local trainFrameTiming = 0;

local trainCars = 8;
local trainFinishing = false;
local trainCooldown = 0;
local startedMoving = false;

function create()
	setDefaultZoom(1.05);

	makeSprite('bg', -100, 0);
	setGraphic('philly/sky');
	setScrollFactor(0.1, 0.1);

	makeSprite('city', -10, 0);
	setGraphic('philly/city');
	setScrollFactor(0.3, 0.3);
	resize('scale', 0.85, 0.85);

	makeSprite('cityLights', -10, 0);
	setFrames('philly/windows');
	setScrollFactor(0.3, 0.3);
	resize('scale', 0.85, 0.85);
	for i = 0, 4, 1 do
		addPrefixAnim("win"..i, "win"..i);
	end
	setSpriteProperty('alpha', 0);

	makeSprite('streetBehind', -40, 50);
	setGraphic('philly/behindTrain');

	makeSprite('train', 2000, 360);
	setGraphic('philly/train');

	makeSound('trainSound');

	makeSprite('street', -40, 50);
	setGraphic('philly/street');

	insertChar('spectator', 400, 130);
	insertChar('player', 770, 100);
	insertChar('opponent', 100, 100);
end

function beatHit()
	if not trainMoving then
		trainCooldown = trainCooldown + 1;
	end

	if curBeat % 4 == 0 then
		curLight = random('int', 0, 4, {curLight});

		selectSprite('cityLights');
		setSpriteProperty('alpha', 1);
		playAnim('win'..curLight);

		spriteTween('lightFade', {["alpha"] = 0}, crochet / 1000 * 3, "linear");
	end

	if curBeat % 8 == 4 and random('bool', 30) and not trainMoving and trainCooldown > 8 then
		trainCooldown = random('int', -4, 0);
		trainMoving = true;
		if not getSoundProperty("playing") then
			playSound('philly/train_passes');
		end
	end
end

function update(elapsed)
	if trainMoving then
		trainFrameTiming = trainFrameTiming + elapsed;

		if trainFrameTiming >= 1 / 24 then
			if getSoundProperty("time") >= 4700 then
				startedMoving = true;
				charPlayAnim('spectator', 'hairBlow');
			end

			if startedMoving then
				selectSprite('train')
				setSpriteProperty('x', getSpriteProperty('x') - 400);

				if getSpriteProperty('x') < -2000 and not trainFinishing then
					setSpriteProperty('x', -1150);
					trainCars = trainCars - 1;

					if trainCars <= 0 then
						trainFinishing = true;
					end
				end

				if getSpriteProperty('x') < -4000 and trainFinishing then
					charPlayAnim('spectator', 'hairFall');
					setSpriteProperty('x', 1480);

					trainMoving = false;
					trainCars = 8;
					trainFinishing = false;
					startedMoving = false;
				end
			end

			trainFrameTiming = 0
		end
	end
end