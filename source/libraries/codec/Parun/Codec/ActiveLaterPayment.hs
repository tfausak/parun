{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ActiveLaterPayment where

import qualified Parun.Codec.Cost as Cost
import qualified Parun.Codec.Expiry as Expiry
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PreventionRider as PreventionRider
import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ActiveLaterPayment as ActiveLaterPayment

codec :: Codec.Codec ActiveLaterPayment.ActiveLaterPayment
codec = Fields.object $ do
  cost <- Fields.required "cost" (Cost.codec Keyword.codec) ActiveLaterPayment.cost
  payoff <- Fields.required "payoff" PreventionRider.codec ActiveLaterPayment.payoff
  createdAt <- Fields.required "createdAt" Timestamp.codec ActiveLaterPayment.createdAt
  expiry <- Fields.required "expiry" Expiry.codec ActiveLaterPayment.expiry
  pure
    ActiveLaterPayment.MkActiveLaterPayment
      { ActiveLaterPayment.cost = cost,
        ActiveLaterPayment.payoff = payoff,
        ActiveLaterPayment.createdAt = createdAt,
        ActiveLaterPayment.expiry = expiry
      }
