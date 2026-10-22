{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.ChangeText where

import qualified Pawl.Codec.Duration as Duration
import qualified Pawl.Codec.SlotName as SlotName
import qualified Pawl.Codec.TextWord as TextWord
import qualified Pawl.Codec.WordFamily as WordFamily
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.ChangeText as ChangeText
import qualified Pawl.Types.Duration as Duration.Type

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Pawl.Codec.Effect's ChangeText arm. The duration defaults to CR
-- 611.2a's Indefinite, which every card stating none has.
codec :: Codec.Codec ChangeText.ChangeText
codec = Fields.object $ do
  families <- Fields.required "families" (Common.set WordFamily.codec) ChangeText.families
  forbidden <- Fields.required "forbidden" (Common.set TextWord.codec) ChangeText.forbidden
  slot <- Fields.required "slot" SlotName.codec ChangeText.slot
  duration <- Fields.defaulted "duration" Duration.Type.Indefinite Duration.codec ChangeText.duration
  pure
    ChangeText.MkChangeText
      { ChangeText.families = families,
        ChangeText.forbidden = forbidden,
        ChangeText.slot = slot,
        ChangeText.duration = duration
      }
