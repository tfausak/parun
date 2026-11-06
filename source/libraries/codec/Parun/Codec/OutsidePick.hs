{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.OutsidePick where

import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.OutsidePick as OutsidePick

-- | A bare object keyed by the record's field names.
codec :: Codec.Codec OutsidePick.OutsidePick
codec = Fields.object $ do
  chooser <- Fields.required "chooser" PlayerRelation.codec OutsidePick.chooser
  count <- Fields.required "count" Common.natural OutsidePick.count
  pure OutsidePick.MkOutsidePick {OutsidePick.chooser = chooser, OutsidePick.count = count}
