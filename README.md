Flyweight
I keep one shared table (CardDefs) that holds each card’s cost, power, and “onReveal” function. When I create a new card, it simply points back to that shared data instead of copying it. That way, twenty copies of “Zeus” don’t each store separate copies of the same numbers and code—they all reference the same entry in CardDefs. This saves memory and makes it easy for me to update a card’s stats in one place.

Observer
Some cards (like Athena) need to react whenever another card is played in the same spot. To handle this, I keep a list of listener functions. When Athena flips face-down, I add a tiny function to that list that says “if a new card is played here, give me +1 power.” Later, whenever I place any card on the board, I loop through all listeners and call them. This lets cards hook into events (like “card was played”) without me hard-coding special checks all over the code.

Event Queue (lightweight)
When I place a card into a zone, I immediately push a mini-event (a simple table { type="cardPlayed", … }) to my listener list. That’s my “event queue.” Once all cards are placed for the turn, I go through those events (calling each listener function). This is a lightweight version of an event queue: collect events (card plays) and then notify whoever is listening (like Athena).

State
Each card keeps track of whether it’s face-down or face-up. My drawing code checks that flag: if it’s faceDown, I draw a card back; otherwise, I draw the front with name, cost, power. When I call resolveReveals(), I flip each card to face-up and trigger its “onReveal.” That simple two-state (face-down vs. face-up) controls both how the card looks and when its effect runs.

Strategy
Right now, my AI uses a very simple strategy: pick a random card it can afford and drop it in a random legal slot, then repeat until out of mana. If I ever want a smarter AI, I can swap in a different “choose-and-play” function without reworking the entire game code. That pluggable decision-making is the essence of the Strategy pattern.

Component (in spirit)
I treat each Card object as a small, self-contained unit that knows how to draw itself, hold its own stats (cost, currentPower), and run its own “onReveal” logic. I haven’t broken cards into dozens of sub-pieces, but by letting a Card class own its data and drawing code, I follow the idea of making each game object responsible for its own behavior.

Postmortem 
I struggled with many difficult bugs that took a lot of my time to try to figure out how to fix them. Implementing certain cards' features made it more difficult, as it could have possibly been easier if I had chosen different cards. I could have made or used assets from somewhere so my game looks ugly, but I can fix this in the final version. Adding some visual touch-ups to UI, adding card images, and some color will drastically fix this. 
