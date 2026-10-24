module Parun.Types.CopyOriginal where

import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.ObjectRef as ObjectRef

-- | What Parun.Types.BecomeCopy's subject becomes a copy of (CR 707.1).
data CopyOriginal
  = -- | An object in the game (Unstable Shapeshifter's "that creature").
    OfObject ObjectRef.ObjectRef
  | -- | CR 108.1 / 707.2: the card the Oracle reference gives this name
    -- (Transcantation's "a copy of Lightning Bolt").
    Named CardName.CardName
  deriving (Eq, Ord, Show)
