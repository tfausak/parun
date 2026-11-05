module Parun.Codec.RiderClauseSpec where

import qualified Parun.Codec.RiderClause as RiderClause
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.RiderClause as RiderClause

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.RiderClause" $ do
  Spec.it s "InstantSpeed" $
    Common.assertCodec
      s
      RiderClause.codec
      RiderClause.InstantSpeed
      " {\"type\":\"InstantSpeed\"} "
  Spec.it s "TimesEachTurn" $
    Common.assertCodec
      s
      RiderClause.codec
      (RiderClause.TimesEachTurn 2)
      " {\"type\":\"TimesEachTurn\",\"value\":2} "
  Spec.it s "has a schema" $ Common.assertHasSchema s RiderClause.codec
