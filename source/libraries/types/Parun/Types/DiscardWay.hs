module Parun.Types.DiscardWay where

-- | CR 701.9a: which discards a discard trigger admits.
data DiscardWay
  = -- | Any discard, cycling's included (CR 702.29a): "when you discard this
    -- card" (Bartered Cow).
    AnyDiscard
  | -- | CR 702.29c: a discard to pay a cycling ability's activation cost.
    Cycled
  | -- | CR 702.35a: a discard madness's replacement exiled ("exiled this way").
    ExiledForMadness
  deriving (Bounded, Enum, Eq, Ord, Show)
