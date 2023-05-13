function create()
	setDefaultZoom(0.8);

	makeSprite('bg', -1000, -500);
	setGraphic('mall/bgWalls');
	setScrollFactor(0.2, 0.2);
	resize('scale', 0.8, 0.8);

	makeSprite('upperBoppers', -240, -90);
	setFrames('mall/upperBop');
	addPrefixAnim('bop', 'Upper Crowd Bob');
	setScrollFactor(0.33, 0.33);
	resize('scale', 0.85, 0.85);

	makeSprite('bgEscalator', -1100, -600);
	setGraphic('mall/bgEscalator');
	setScrollFactor(0.3, 0.3);
	resize('scale', 0.9, 0.9);

	makeSprite('tree', 370, -250);
	setGraphic('mall/christmasTree');
	setScrollFactor(0.4, 0.4);

	makeSprite('bottomBoppers', -300, 140);
	setFrames('mall/bottomBop');
	addPrefixAnim('bop', 'Bottom Level Boppers');
	setScrollFactor(0.9, 0.9);

	makeSprite('fgSnow', -600, 700);
	setGraphic('mall/fgSnow');

	makeSprite('santa', -840, 150);
	setFrames('mall/santa');
	addPrefixAnim('idle', 'santa idle in fear');

	insertChar('spectator', 400, 130);
	insertChar('player', 970, 100);
	camOffsets('player', 0, -100);
	insertChar('opponent', 100, 100);
end

function beatHit()
	selectSprite('upperBoppers');
	playAnim('bop');

	selectSprite('bottomBoppers');
	playAnim('bop');

	selectSprite('santa');
	playAnim('idle');
end