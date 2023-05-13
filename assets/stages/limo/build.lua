local canDrive = true
local elapsed = 0;

function create()
	setDefaultZoom(0.9);

	makeSprite('skyBG', -120, -50);
	setGraphic('limo/limoSunset');
	setScrollFactor(0.1, 0.1);

	makeSprite('bgLimo', -200, 480);
	setFrames('limo/bgLimo');
	addPrefixAnim('drive', 'background limo pink', 24, true);
	playAnim('drive');
	setScrollFactor(0.4, 0.4);

	for i = 0, 4, 1 do
		makeSprite('dancer'..i, 370 * i + 130, 80);
		setFrames('limo/limoDancer');
		addIndiceAnim('danceLeft', 'bg dancer sketch PINK', {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14});
		addIndiceAnim('danceRight', 'bg dancer sketch PINK', {15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29});
		setScrollFactor(0.4, 0.4);
	end

	insertChar('spectator', 400, 130);

	makeSprite('limo', -120, 550);
	setFrames('limo/limoDrive');
	addPrefixAnim('drive', 'Limo stage', 24, true);
	playAnim('drive');

	insertChar('player', 1030, -120);
	camOffsets('player', -200, 0);
	insertChar('opponent', 100, 100);

	makeSprite('fastCar', -12600, random('int', 140, 250));
	setGraphic('limo/fastCarLol');
	setSpriteProperty('velocity.x', 0);

	makeSound('passing');
end

function update(el, failed)
   elapsed = el;
end

function beatHit()
	if curBeat % 2 == 0 then
		for i = 0, 4, 1 do
			selectSprite('dancer'..i);
			playAnim('danceLeft');
		end
	else
		for i = 0, 4, 1 do
			selectSprite('dancer'..i);
			playAnim('danceRight');
		end
	end

	if random('bool', 10) and canDrive then
		selectSprite('fastCar');
		playSound('limo/carPass'..random('int', 0, 1));
		setSpriteProperty('velocity.x', random('int', 170, 220) / elapsed * 3);
		canDrive = false;
		startTimer('resetTimer', 2);
	end
end

function resetTimer_finished(loops, loopsLeft)
	selectSprite('fastCar');
	setSpriteProperty('x', -12600);
	setSpriteProperty('y', random('int', 140, 250));
	setSpriteProperty('velocity.x', 0);
	canDrive = true;
end