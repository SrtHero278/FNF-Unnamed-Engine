function postCreate()
	selectSprite('PlayState.opponent');
	setSpriteProperty('x', getClassProperty('PlayState.spectator.x'));
	setSpriteProperty('y', getClassProperty('PlayState.spectator.y'));
	setClassProperty('PlayState.spectator.visible', false);
	removeSprite(false);
	insertSprite('player');
end