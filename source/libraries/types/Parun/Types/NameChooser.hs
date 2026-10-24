module Parun.Types.NameChooser where

-- | Whose CR 201.4 chosen name Filter.HasChosenName compares the candidate
-- against, when several players each chose one for the same source.
data NameChooser
  = -- | Any chooser's: Null Chamber's names apply to every player.
    AnyChooser
  | -- | The name the candidate's OWNER chose: Conundrum Sphinx's "the name they
    -- chose", where each player reveals a card from their own library (CR 400.3).
    CandidateOwner
  deriving (Bounded, Enum, Eq, Ord, Show)
