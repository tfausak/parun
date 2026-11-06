module Parun.Codec.NextDamageOutcome where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.NextDamageOutcome as NextDamageOutcome

-- | Tagged, Parun.Codec.DamageRewrite's shape: @PreventedAllBut@ carries what
-- survives.
codec :: Codec.Codec NextDamageOutcome.NextDamageOutcome
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Prevented" NextDamageOutcome.Prevented,
      Arm.payload "PreventedAllBut" Common.natural NextDamageOutcome.PreventedAllBut (\x -> case x of NextDamageOutcome.PreventedAllBut y -> Just y; _ -> Nothing),
      Arm.nullary "AlsoToSourceController" NextDamageOutcome.AlsoToSourceController
    ]

tagOf :: NextDamageOutcome.NextDamageOutcome -> String
tagOf x = case x of
  NextDamageOutcome.Prevented -> "Prevented"
  NextDamageOutcome.PreventedAllBut {} -> "PreventedAllBut"
  NextDamageOutcome.AlsoToSourceController -> "AlsoToSourceController"
