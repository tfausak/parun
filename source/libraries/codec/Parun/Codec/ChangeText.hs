{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ChangeText where

import qualified Parun.Codec.Duration as Duration
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.Codec.TextWord as TextWord
import qualified Parun.Codec.WordFamily as WordFamily
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ChangeText as ChangeText
import qualified Parun.Types.Duration as Duration.Type

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's ChangeText arm. The duration defaults to CR
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
