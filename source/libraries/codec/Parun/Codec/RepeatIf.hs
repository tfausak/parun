{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.RepeatIf where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Condition as Condition
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.RepeatIf as RepeatIf

-- | A bare object keyed by the record's field names, every one required, as
-- Parun.Codec.ForEachNumber's are. The effect codec is a parameter for
-- Parun.Codec.ForEach's reason.
codec ::
  (Typeable.Typeable effect) =>
  Codec.Codec effect ->
  Codec.Codec (RepeatIf.RepeatIf effect)
codec effectCodec = Fields.object $ do
  process <- Fields.required "process" (Common.seq effectCodec) RepeatIf.process
  condition <- Fields.required "condition" Condition.codec RepeatIf.condition
  ifHolds <- Fields.required "ifHolds" (Common.seq effectCodec) RepeatIf.ifHolds
  pure
    RepeatIf.MkRepeatIf
      { RepeatIf.process = process,
        RepeatIf.condition = condition,
        RepeatIf.ifHolds = ifHolds
      }
