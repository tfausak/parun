{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Repeat where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Repeat as Repeat

-- | A bare object keyed by the record's field names, as Parun.Codec.RepeatIf's
-- are; the gate is ELIDED when absent. The effect codec is a parameter for
-- Parun.Codec.ForEach's reason.
codec ::
  (Typeable.Typeable effect) =>
  Codec.Codec effect ->
  Codec.Codec (Repeat.Repeat effect)
codec effectCodec = Fields.object $ do
  chooser <- Fields.required "chooser" PlayerRef.codec Repeat.chooser
  body <- Fields.required "body" (Common.seq effectCodec) Repeat.body
  gate <- Fields.defaulted "gate" Nothing (Common.maybe Condition.codec) Repeat.gate
  pure
    Repeat.MkRepeat
      { Repeat.chooser = chooser,
        Repeat.body = body,
        Repeat.gate = gate
      }
