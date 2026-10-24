{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ModifiedRoll where

import qualified Parun.Codec.Cost as Cost
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PermissionLimit as PermissionLimit
import qualified Parun.Codec.RollModifier as RollModifier
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ModifiedRoll as ModifiedRoll
import qualified Parun.Types.PermissionLimit as PermissionLimit

-- | A bare object keyed by the record's field names. Both narrowings and the CR
-- 706.2a cost default to Nothing, and the budget to Unlimited, so a card writes
-- only the ones its sentence states.
codec :: Codec.Codec ModifiedRoll.ModifiedRoll
codec = Fields.object $ do
  sides <- Fields.defaulted "sides" Nothing (Common.maybe Common.natural) ModifiedRoll.sides
  natural <- Fields.defaulted "natural" Nothing (Common.maybe Common.natural) ModifiedRoll.natural
  modifier <- Fields.required "modifier" RollModifier.codec ModifiedRoll.modifier
  cost <- Fields.defaulted "cost" Nothing (Common.maybe (Cost.codec Keyword.codec)) ModifiedRoll.cost
  limit <- Fields.defaulted "limit" PermissionLimit.Unlimited PermissionLimit.codec ModifiedRoll.limit
  pure
    ModifiedRoll.MkModifiedRoll
      { ModifiedRoll.sides = sides,
        ModifiedRoll.natural = natural,
        ModifiedRoll.modifier = modifier,
        ModifiedRoll.cost = cost,
        ModifiedRoll.limit = limit
      }
