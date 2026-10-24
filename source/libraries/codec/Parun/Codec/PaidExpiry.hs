{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PaidExpiry where

import qualified Parun.Codec.Cost as Cost
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PaidExpiry as PaidExpiry

-- | A bare object keyed by the record's field names, Parun.Codec.While's shape.
codec :: Codec.Codec PaidExpiry.PaidExpiry
codec = Fields.object $ do
  player <- Fields.required "player" PlayerId.codec PaidExpiry.player
  cost <- Fields.required "cost" (Cost.codec Keyword.codec) PaidExpiry.cost
  pure PaidExpiry.MkPaidExpiry {PaidExpiry.player = player, PaidExpiry.cost = cost}
