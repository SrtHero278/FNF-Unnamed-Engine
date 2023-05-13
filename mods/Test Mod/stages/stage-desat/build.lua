function create()
	setDefaultZoom(0.9);

	makeSprite('stageback', -600, -200);
	setGraphic('stage-desat/stageback');
	setScrollFactor(0.9, 0.9);

	makeSprite('stagefront', -650, 600);
	setGraphic('stage-desat/stagefront');
	setScrollFactor(0.9, 0.9);
	resize('scale', 1.1, 1.1);

	makeSprite('stagecurtains', -500, -300);
	setGraphic('stage-desat/stagecurtains');
	setScrollFactor(1.3, 1.3);
	resize('scale', 0.9, 0.9);

	insertChar('spectator', 400, 130);
	insertChar('player', 770, 100);
	insertChar('opponent', 100, 100);
end