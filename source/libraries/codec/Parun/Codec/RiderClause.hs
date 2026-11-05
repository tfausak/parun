module Parun.Codec.RiderClause where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.RiderClause as RiderClause

-- | Tagged, since CR 602.5b's TimesEachTurn carries a count.
codec :: Codec.Codec RiderClause.RiderClause
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "InstantSpeed" RiderClause.InstantSpeed,
      Arm.payload "TimesEachTurn" Common.natural RiderClause.TimesEachTurn (\x -> case x of RiderClause.TimesEachTurn y -> Just y; _ -> Nothing)
    ]

tagOf :: RiderClause.RiderClause -> String
tagOf x = case x of
  RiderClause.InstantSpeed {} -> "InstantSpeed"
  RiderClause.TimesEachTurn {} -> "TimesEachTurn"
