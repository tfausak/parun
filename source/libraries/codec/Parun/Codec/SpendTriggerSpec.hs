module Parun.Codec.SpendTriggerSpec where

import qualified Parun.Codec.FaceSpec as FaceSpec
import qualified Parun.Codec.SpendTrigger as SpendTrigger
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.SpendTrigger as SpendTrigger

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.SpendTrigger" $ do
  Spec.it s "every field written out" $
    Common.assertCodec
      s
      SpendTrigger.codec
      SpendTrigger.MkSpendTrigger
        { SpendTrigger.casts = Filter.HasCardType CardType.Instant,
          SpendTrigger.ability = FaceSpec.minimalTriggeredAbility,
          SpendTrigger.source = ObjectId.MkObjectId 4,
          SpendTrigger.controller = PlayerId.MkPlayerId 0
        }
      ( " {\"casts\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Instant\"}},"
          <> "\"ability\":{\"condition\":{\"type\":\"SelfEnters\"},\"modal\":{\"modes\":[{}]}},\"source\":4,\"controller\":0} "
      )
  Spec.it s "has a schema" $ Common.assertHasSchema s SpendTrigger.codec
