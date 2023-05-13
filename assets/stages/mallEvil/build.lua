function create()
	setDefaultZoom(1.05);

	makeSprite('bg', -400, -500);
	setGraphic('mallEvil/evilBG');
	setScrollFactor(0.2, 0.2);
	resize('scale', 0.8, 0.8);

	makeSprite('tree', 300, -300);
	setGraphic('mallEvil/evilTree');
	setScrollFactor(0.2, 0.2);

	makeSprite('snow', -200, 700);
	setGraphic('mallEvil/evilSnow');

	insertChar('spectator', 400, 130);
	insertChar('player', 1090, 100);
	insertChar('opponent', 100, 20);
end