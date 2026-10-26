module Parun.Types.ChangeMode where

-- | CR 105.3 / 205.1a / 205.1b: whether the colours or subtypes an effect gives
-- replace the object's existing ones or join them ("in addition to its other
-- colors", "in addition to its other types").
data ChangeMode
  = -- | CR 105.3 / 205.1a: the new values replace the old (Shifting Sky, Blood Moon).
    Replace
  | -- | CR 105.3 / 205.1b: the new values join the old (Painter's Servant, Urborg).
    InAddition
  deriving (Bounded, Enum, Eq, Ord, Show)
