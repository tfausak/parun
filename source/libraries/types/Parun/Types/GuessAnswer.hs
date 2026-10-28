module Parun.Types.GuessAnswer where

-- | A guesser's answer to Parun.Types.Prompt.ChooseGuess: whether the guess's
-- proposition holds of the card guessed about. A named sum rather than a Bool,
-- Parun.Types.OptionalDecision's reason.
data GuessAnswer
  = -- | The proposition holds.
    Holds
  | -- | The proposition does not hold.
    DoesNotHold
  deriving (Bounded, Enum, Eq, Ord, Show)
