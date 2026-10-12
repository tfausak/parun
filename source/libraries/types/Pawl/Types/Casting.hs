module Pawl.Types.Casting where

import qualified Pawl.Types.Choices as Choices
import qualified Pawl.Types.Reference as Reference

-- | CR 601.2: casting one spell, and the choices its casting asks.
data Casting = MkCasting
  { object :: Reference.Reference,
    choices :: Choices.Choices,
    -- | CR 702.37c / 708.4: whether the spell is cast face down, for a card
    -- offering both (a morph card in hand); Nothing for either.
    faceDown :: Maybe Bool
  }
  deriving (Eq, Ord, Show)
