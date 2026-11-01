{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.TargetSlot where

import qualified Data.Map.Strict as Map
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Pool as Pool
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.SlotCount as SlotCount
import qualified Parun.Codec.SlotPerPlayer as SlotPerPlayer
import qualified Parun.Codec.Together as Together
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.SlotCount as SlotCount
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.TargetCount as TargetCount
import qualified Parun.Types.TargetSlot as TargetSlot

-- | The filter key is omitted when Nothing, mirroring how optional fields are
-- encoded elsewhere. CR 601.2c's "another" is a Not IsSource conjunct inside
-- that filter, not a key of its own (#163).
--
-- The count key is omitted when the slot takes exactly one, so an ordinary
-- "target creature" renders as it always did and only CR 601.2c's variable
-- counts spend a key.
--
-- The amount key is omitted the same way, and for a sharper version of the same
-- reason: only the handful of slots printing a computed mana-value bound name one
-- (Parun.Types.TargetSlot's `amount`), so every other slot in the corpus renders
-- unchanged. The chooser key is omitted on the same terms: CR 115.1's default is
-- the ability's controller, which nearly every slot takes.
-- The perPlayer key likewise: only CR 601.2c's "for each opponent" and "for each
-- player" slots name one, the divided key: only CR 601.2d's divided slots, and
-- the together key: only a slot whose targets must share a zone, and the asCast
-- key: only a slot narrowed as the spell is cast.
codec :: Codec.Codec TargetSlot.TargetSlot
codec = Fields.object $ do
  pool <- Fields.required "pool" Pool.codec TargetSlot.pool
  filter_ <- Fields.defaulted "filter" Nothing (Common.maybe (Filter.codec Keyword.codec)) TargetSlot.filter
  count <- Fields.defaulted "count" (SlotCount.Printed TargetCount.one) SlotCount.codec TargetSlot.count
  amount <- Fields.defaulted "amount" Nothing (Common.maybe Quantity.codec) TargetSlot.amount
  chooser <- Fields.defaulted "chooser" Nothing (Common.maybe PlayerRef.codec) TargetSlot.chooser
  perPlayer <- Fields.defaulted "perPlayer" Nothing (Common.maybe SlotPerPlayer.codec) TargetSlot.perPlayer
  divided <- Fields.defaulted "divided" Nothing (Common.maybe Quantity.codec) TargetSlot.divided
  together <- Fields.defaulted "together" Nothing (Common.maybe Together.codec) TargetSlot.together
  asCast <- Fields.defaulted "asCast" Nothing (Common.maybe (Filter.codec Keyword.codec)) TargetSlot.asCast
  pure
    TargetSlot.MkTargetSlot
      { TargetSlot.pool = pool,
        TargetSlot.filter = filter_,
        TargetSlot.count = count,
        TargetSlot.amount = amount,
        TargetSlot.chooser = chooser,
        TargetSlot.perPlayer = perPlayer,
        TargetSlot.divided = divided,
        TargetSlot.together = together,
        TargetSlot.asCast = asCast
      }

-- | A slot-keyed map as a JSON object keyed by the slot name (#1303).
codecMap :: Codec.Codec (Map.Map SlotName.SlotName TargetSlot.TargetSlot)
codecMap = Common.textMap SlotName.unwrap (Right . SlotName.MkSlotName) codec
