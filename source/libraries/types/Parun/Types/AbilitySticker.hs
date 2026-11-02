module Parun.Types.AbilitySticker where

import qualified Data.Map.Strict as Map
import qualified Numeric.Natural as Natural
import qualified Parun.Types.Card as Card
import qualified Parun.Types.CastingPermission as CastingPermission
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.Keyword as Keyword

-- | CR 123.7: an ability sticker, its abilities in the card DSL.
data AbilitySticker = MkAbilitySticker
  { -- | CR 123.3c / 107.17a.
    tickets :: Natural.Natural,
    -- | CR 702: Face.keywords' shape.
    keywords :: Map.Map Keyword.Keyword Natural.Natural,
    -- | CR 113.3: every other printed ability but a casting permission.
    abilities :: [GrantedAbility.GrantedAbility Card.Card],
    -- | CR 113.6f / 601.3: a permission about the card it's on.
    castingPermissions :: [CastingPermission.CastingPermission]
  }
  deriving (Eq, Ord, Show)
