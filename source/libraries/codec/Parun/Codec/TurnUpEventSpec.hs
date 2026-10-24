module Parun.Codec.TurnUpEventSpec where

import qualified Parun.Codec.TurnUpEvent as TurnUpEvent
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.TurnUpEvent as TurnUpEvent

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TurnUpEvent" $ do
  Spec.it s "AssignsCombatDamage" $
    Common.assertCodec
      s
      TurnUpEvent.codec
      TurnUpEvent.AssignsCombatDamage
      " {\"type\":\"AssignsCombatDamage\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s TurnUpEvent.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s TurnUpEvent.codec
