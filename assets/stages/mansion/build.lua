local strikeBeat = 0;
local offset = 8;

function create()
	setDefaultZoom(1.05);

	makeSprite('bg', -200, -100);
	setFrames('mansion/halloween_bg');
	addPrefixAnim('bg', 'halloweem bg0');
	addPrefixAnim('strike', 'halloweem bg lightning strike');

	makeSound('thunder');

	insertChar('spectator', 400, 130);
	insertChar('player', 770, 100);
	insertChar('opponent', 100, 100);
end


function beatHit()
	if random('bool', 10) and curBeat > strikeBeat + offset then
		playSound('mansion/thunder_'..random('int', 1, 2));
		playAnim('strike');

		strikeBeat = curBeat;
		offset = random('int', 8, 24);

		charPlayAnim('spectator', 'scared');
		charPlayAnim('player', 'scared');
	end
end
