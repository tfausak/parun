module Parun.Types.LentCards where

-- | Where Parun.Types.CardAbilities walks for the cards lending their activated
-- abilities (CR 613.1f).
data LentCards
  = -- | CR 406: each card in exile (Myr Welder, Mairsil, the Pretender).
    InExile
  | -- | CR 401.5: the top card of the library of the effect's controller, while
    -- it is shown (Conspicuous Snoop).
    TopOfYourLibrary
  deriving (Bounded, Enum, Eq, Ord, Show)
