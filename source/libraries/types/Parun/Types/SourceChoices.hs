module Parun.Types.SourceChoices where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.Color as Color
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Subtype as Subtype

-- | CR 607.2d: what a source had chosen, as a stored effect bakes it when it
-- begins (CR 608.2h, Parun.Types.ActivePlayerEffect.choices).
data SourceChoices = MkSourceChoices
  { -- | CR 201.4: the chosen card names, keyed by who chose each.
    names :: Map.Map PlayerId.PlayerId CardName.CardName,
    -- | CR 105.2: the chosen colours.
    colors :: Set.Set Color.Color,
    -- | CR 205.3: the chosen subtype.
    subtype :: Maybe Subtype.Subtype
  }
  deriving (Eq, Ord, Show)
