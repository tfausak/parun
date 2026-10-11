module Pawl.Types.SourceChoices where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.Color as Color
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.Subtype as Subtype

-- | CR 607.2d: what a source had chosen, as a stored effect bakes it when it
-- begins (CR 608.2h, Pawl.Types.ActivePlayerEffect.choices).
data SourceChoices = MkSourceChoices
  { -- | CR 201.4: the chosen card names, keyed by who chose each.
    names :: Map.Map PlayerId.PlayerId CardName.CardName,
    -- | CR 105.2: the chosen colours.
    colors :: Set.Set Color.Color,
    -- | CR 205.3: the chosen subtype.
    subtype :: Maybe Subtype.Subtype
  }
  deriving (Eq, Ord, Show)
