module Parun.Codec.SicknessSpec where

import qualified Parun.Codec.Sickness as Sickness
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Sickness as Sickness

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Sickness" $ do
  Spec.it s "Sick" $
    Common.assertCodec
      s
      Sickness.codec
      Sickness.Sick
      " {\"type\":\"Sick\"} "
  -- CR 302.6's subject is a PLAYER, so the seat is the payload rather than a
  -- flag: "settled" alone got Control Magic wrong (#198).
  Spec.it s "Settled names the player it is settled under" $
    Common.assertCodec
      s
      Sickness.codec
      (Sickness.Settled (PlayerId.MkPlayerId 2))
      " {\"type\":\"Settled\",\"value\":2} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s Sickness.codec
