module Pawl.Codec.TurnUpEventSpec where

import qualified Pawl.Codec.TurnUpEvent as TurnUpEvent
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.TurnUpEvent as TurnUpEvent

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.TurnUpEvent" $ do
  Spec.it s "AssignsCombatDamage" $
    Common.assertCodec
      s
      TurnUpEvent.codec
      TurnUpEvent.AssignsCombatDamage
      " {\"type\":\"AssignsCombatDamage\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s TurnUpEvent.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s TurnUpEvent.codec
