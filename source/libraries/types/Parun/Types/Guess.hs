module Parun.Types.Guess where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.SlotName as SlotName

-- | The payload of Parun.Types.Effect's Guess arm: a player guesses whether a
-- proposition holds of a card hidden from them (CR 400.2), Master of
-- Predicaments' "That player guesses whether the card's mana value is greater
-- than 4". The guesser is offered the two answers and nothing else:
-- Parun.Types.Prompt.ChooseGuess carries the proposition, never the card.
--
-- The fields answer different questions and are named rather than positional,
-- Parun.Types.ChosenPermanents' reason.
data Guess = MkGuess
  { -- | The card guessed about, asked through
    -- Parun.Engine.Resolve.Common.askingObjects, so Master of Predicaments'
    -- "choose a card in your hand" is this ref's CR 608.2d choice. A ref naming
    -- no card, or several, makes no guess (CR 609.3).
    subject :: ObjectRef.ObjectRef,
    -- | Where the card is bound, for a later clause's "the card".
    slot :: SlotName.SlotName,
    -- | Who guesses: ONE seat, Parun.Types.ChosenPermanents' chooser.
    guesser :: PlayerRef.PlayerRef,
    -- | What is guessed, matched against the card in the effect's context (CR
    -- 109.5's "you" is the ability's controller).
    proposition :: Filter.Filter Keyword.Keyword,
    -- | Binds 1 for a right guess and 0 for a wrong one, Effect.FlipCoin's
    -- shape; nothing when no guess was made.
    right :: SlotName.SlotName
  }
  deriving (Eq, Ord, Show)
