{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.LaterPayment where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Cost as Cost
import qualified Parun.Codec.Duration as Duration
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.LaterPayment as LaterPayment

codec :: (Typeable.Typeable effect) => Codec.Codec effect -> Codec.Codec (LaterPayment.LaterPayment effect)
codec effect = Fields.object $ do
  duration <- Fields.required "duration" Duration.codec LaterPayment.duration
  cost <- Fields.required "cost" (Cost.codec Keyword.codec) LaterPayment.cost
  effects <- Fields.required "effects" (Common.seq effect) LaterPayment.effects
  pure
    LaterPayment.MkLaterPayment
      { LaterPayment.duration = duration,
        LaterPayment.cost = cost,
        LaterPayment.effects = effects
      }
