# Parun

> In times of peril, the vision the ancient paruns had for their city comes into focus.
> - [Band Together](https://gatherer.wizards.com/WAR/en-us/153/band-together)

Parun is a Magic: The Gathering (MTG) rules engine written in Haskell.

## Features

- Cards are represented as data, not code.
  There is no escape hatch to handle tricky cards.
  Each card must be encoded using the non-recursive card description language.

- The engine never makes a player's choice for them.
  Players have complete control over ordering triggers, picking targets, paying mana, and everything else.
  Choices are only skipped when they're indistinguishable and lead to the same result.

- Suspend and restore at any point.
  The entire game can be written to a JSON file and picked up again later.
  This makes saving games and stepping through simulations trivial.

- The engine is completely deterministic.
  Anything that needs input, whether that's a player's choice or the outcome of a shuffle, is modeled as a request.
  The same inputs always give the same outputs, so any bug can be reproduced.
