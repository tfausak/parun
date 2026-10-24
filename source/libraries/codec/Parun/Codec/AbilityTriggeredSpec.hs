module Parun.Codec.AbilityTriggeredSpec where

import qualified Parun.Codec.AbilityTriggered as AbilityTriggered
import qualified Parun.Codec.TriggeredAbilitySourceSpec as TriggeredAbilitySourceSpec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityTriggered as AbilityTriggered
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.TriggerSource as TriggerSource

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AbilityTriggered" $ do
  -- CR 603.2.
  Spec.it s "MkAbilityTriggered, every key" $
    Common.assertCodec
      s
      AbilityTriggered.codec
      ( AbilityTriggered.MkAbilityTriggered
          { AbilityTriggered.source = TriggerSource.OfObject (ObjectId.MkObjectId 1),
            AbilityTriggered.controller = PlayerId.MkPlayerId 0,
            AbilityTriggered.ability = TriggeredAbilitySourceSpec.ability
          }
      )
      " {\"source\":{\"type\":\"OfObject\",\"value\":1},\"controller\":0,\"ability\":{\"condition\":{\"type\":\"SelfEnters\"},\"modal\":{\"modes\":[{}]}}} "
  -- CR 725.2 / CR 702.179d: the same record for an inherent ability with no
  -- object behind it, where the controller is what tells two players' instances
  -- of the one ability apart.
  Spec.it s "a sourceless ability names its controller and nothing else" $
    Common.assertCodec
      s
      AbilityTriggered.codec
      ( AbilityTriggered.MkAbilityTriggered
          { AbilityTriggered.source = TriggerSource.Sourceless,
            AbilityTriggered.controller = PlayerId.MkPlayerId 1,
            AbilityTriggered.ability = TriggeredAbilitySourceSpec.ability
          }
      )
      " {\"source\":{\"type\":\"Sourceless\"},\"controller\":1,\"ability\":{\"condition\":{\"type\":\"SelfEnters\"},\"modal\":{\"modes\":[{}]}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AbilityTriggered.codec
