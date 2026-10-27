{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ChosenCardFromAmong where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.HowMany as HowMany
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ChosenCardFromAmong as ChosenCardFromAmong
import qualified Parun.Types.HowMany as HowMany
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | A bare object keyed by the record's field names, the shape every other
-- 'Parun.Types.ObjectRef' payload record takes.
--
-- @count@ and @chooser@ are defaulted rather than required, so the printed
-- singular addressed to the resolving controller -- which is every "from among
-- them" but Ancestral Memories', Animal Magnetism's and the "up to" ones --
-- writes neither. @pileChooser@ is elided rather than written null.
codec :: Codec.Codec ChosenCardFromAmong.ChosenCardFromAmong
codec = Fields.object $ do
  slot <- Fields.required "slot" SlotName.codec ChosenCardFromAmong.slot
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) ChosenCardFromAmong.filter
  count <- Fields.defaulted "count" HowMany.one HowMany.codec ChosenCardFromAmong.count
  chooser <- Fields.defaulted "chooser" (PlayerRef.Relative PlayerRelation.You) PlayerRef.codec ChosenCardFromAmong.chooser
  pileChooser <- Fields.defaulted "pileChooser" Nothing (Common.maybe PlayerRef.codec) ChosenCardFromAmong.pileChooser
  pure
    ChosenCardFromAmong.MkChosenCardFromAmong
      { ChosenCardFromAmong.slot = slot,
        ChosenCardFromAmong.filter = filter_,
        ChosenCardFromAmong.count = count,
        ChosenCardFromAmong.chooser = chooser,
        ChosenCardFromAmong.pileChooser = pileChooser
      }
