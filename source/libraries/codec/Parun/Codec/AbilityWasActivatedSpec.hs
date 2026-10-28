module Parun.Codec.AbilityWasActivatedSpec where

import qualified Parun.Codec.AbilityWasActivated as AbilityWasActivated
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityWasActivated as AbilityWasActivated
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AbilityWasActivated" $ do
  Spec.it s "MkAbilityWasActivated, every key" $
    Common.assertCodec
      s
      AbilityWasActivated.codec
      ( AbilityWasActivated.MkAbilityWasActivated
          { AbilityWasActivated.player = PlayerId.MkPlayerId 1,
            AbilityWasActivated.ability = ObjectId.MkObjectId 2,
            AbilityWasActivated.source = ObjectId.MkObjectId 3,
            AbilityWasActivated.loyalty = True
          }
      )
      " {\"player\":1,\"ability\":2,\"source\":3,\"loyalty\":true} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AbilityWasActivated.codec
