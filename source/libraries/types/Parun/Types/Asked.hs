module Parun.Types.Asked where

import qualified Parun.Types.Prompt as Prompt

-- A question, together with the game that raised it. This -- not 'Prompt' -- is
-- what the engine actually suspends on, so every question reaches its answerer
-- knowing which game it came from (#153).
--
-- CR 729.1a: a subgame is "a completely separate Magic game", and the main game
-- "is temporarily discontinued while the subgame is in progress". Both games run
-- through this one channel, so without the tag a subgame's question is
-- indistinguishable from a main-game one -- and CR 723.4 makes that distinction
-- load-bearing for an interface, since information about cards OUTSIDE the game
-- is visible only to the player being controlled and not to their controller.
--
-- The tag is the GAME STATE rather than a minted identifier. A synthetic id
-- would be a concept the rules do not have, and it would answer only "is this
-- the same game as before"; the state answers that and every other question an
-- interface has to ask about the game it is displaying.
--
-- `g` is what the asked party holds of each game. The engine raises every
-- question with the WHOLE state, filtered for nobody, which its own answerers
-- (the scenario driver, chance, Parun.Play.Protocol) read. A seat is handed
-- only its view, a Parun.Types.PlayerView in each game's place: in process
-- through Parun.Engine.Driver.seated, over the line through
-- Parun.Play.Protocol (CR 400.2, 723.4).
--
-- 'Prompt' is deliberately untouched: it stays the vocabulary of questions, the
-- Parun.Engine.Replay transcript stays keyed on it, and an answerer that does not
-- care which game it is in ignores this wrapper (Engine.runGame).
data Asked g r = MkAsked
  { -- | The games this one is nested inside, OUTERMOST first -- so the main game
    -- heads the list and the game immediately containing `game` ends it. Empty
    -- for a question raised by the main game itself, which is every question
    -- parun asks outside CR 729.
    --
    -- A stack, which is why it is a list: the style guide reserves lists for
    -- stacks, and nesting is exactly what this records. Engine.playSubgame pushes
    -- onto it as each level's program passes outward through its parent's frame.
    enclosing :: [g],
    -- | The game that raised the question, as of the moment it was raised.
    game :: g,
    prompt :: Prompt.Prompt r
  }

-- Record that this question was raised inside a subgame of `parent` (CR 729.1a).
--
-- Applied by Engine.playSubgame to every instruction of the subgame's program at
-- once, so a question from N levels down is wrapped N times, innermost parent
-- first -- which is why pushing onto the front builds an outermost-first list.
under :: g -> Asked g r -> Asked g r
under parent asked = asked {enclosing = parent : enclosing asked}

-- CR 729.1a: the main game, the one every other level is nested inside. The
-- asking game itself when nothing encloses it.
mainGame :: Asked g r -> g
mainGame asked = case enclosing asked of
  [] -> game asked
  outermost : _ -> outermost

-- | The same question, `f` applied to each game it is in.
mapGames :: (g -> h) -> Asked g r -> Asked h r
mapGames f asked = asked {enclosing = fmap f (enclosing asked), game = f (game asked)}
