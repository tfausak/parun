module Parun.Types.PlacesSticker where

import qualified Data.Set as Set
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.StickerKind as StickerKind

-- | CR 123.3: "whenever [a player] places a sticker", narrowed to these
-- kinds, PermanentGetsCounters' posture for a counter kind.
data PlacesSticker = MkPlacesSticker
  { placer :: PlayerRelation.PlayerRelation,
    kinds :: Set.Set StickerKind.StickerKind,
    -- | The object it went on; @And []@ for any. "On this enchantment" is
    -- IsSource (_____ Balls of Fire).
    object :: Filter.Filter Keyword.Keyword
  }
  deriving (Eq, Ord, Show)
