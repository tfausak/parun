{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AlternativeCost where

import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.Cost as Cost
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AlternativeCost as AlternativeCost

-- | 'cost' is required and 'condition' defaults to Nothing, which is the honest
-- default here where Parun.Codec.Cost's 'mana' has none: an absent condition means
-- CR 118.9's unconditioned alternative, the case every printing but
-- Asmoranomardicadaistinaculdacar's is.
--
-- NESTED rather than flattened into the Cost's own keys, so this codec states no
-- opinion about what a Cost looks like.
--
-- The wire format is unchanged by the conversion to a bundle; what it adds is
-- the schema.
codec :: Codec.Codec AlternativeCost.AlternativeCost
codec = Fields.object $ do
  condition <- Fields.defaulted "condition" Nothing (Common.maybe Condition.codec) AlternativeCost.condition
  cost <- Fields.required "cost" (Cost.codec Keyword.codec) AlternativeCost.cost
  pure
    AlternativeCost.MkAlternativeCost
      { AlternativeCost.condition = condition,
        AlternativeCost.cost = cost
      }
