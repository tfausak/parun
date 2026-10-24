{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.EachCardFromAmong where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.EachCardFromAmong as EachCardFromAmong

-- | A bare object keyed by the record's field names, the shape every other
-- 'Parun.Types.ObjectRef' payload record takes -- and the same two keys
-- 'Parun.Codec.ChosenCardFromAmong' writes, this type being its plural.
codec :: Codec.Codec EachCardFromAmong.EachCardFromAmong
codec = Fields.object $ do
  slot <- Fields.required "slot" SlotName.codec EachCardFromAmong.slot
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) EachCardFromAmong.filter
  pure
    EachCardFromAmong.MkEachCardFromAmong
      { EachCardFromAmong.slot = slot,
        EachCardFromAmong.filter = filter_
      }
