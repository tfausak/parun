module Parun.Codec.CrewRoleSpec where

import qualified Parun.Codec.CrewRole as CrewRole
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CrewRole as CrewRole
import qualified Parun.Types.TriggerFrequency as TriggerFrequency

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CrewRole" $ do
  Spec.it s "Vehicle" $
    Common.assertCodec s CrewRole.codec (CrewRole.Vehicle TriggerFrequency.FirstTimeEachTurn) " {\"type\":\"Vehicle\",\"value\":\"FirstTimeEachTurn\"} "
  Spec.it s "Crewer" $
    Common.assertCodec s CrewRole.codec CrewRole.Crewer " {\"type\":\"Crewer\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CrewRole.codec
