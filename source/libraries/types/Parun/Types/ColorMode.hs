module Parun.Types.ColorMode where

-- | CR 105.3: whether a colour an effect gives replaces the object's colours or
-- joins them ("in addition to its other colors").
data ColorMode
  = -- | CR 105.3: the new colour replaces every previous one (Shifting Sky).
    Replace
  | -- | CR 105.3's parenthetical: the new colour joins the others (Painter's Servant).
    InAddition
  deriving (Bounded, Enum, Eq, Ord, Show)
