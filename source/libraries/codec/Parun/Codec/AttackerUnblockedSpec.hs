module Parun.Codec.AttackerUnblockedSpec where

import qualified Parun.Codec.AttackerUnblocked as AttackerUnblocked
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AttackerUnblocked as AttackerUnblocked
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttackerUnblocked" $ do
  Spec.it s "MkAttackerUnblocked" $
    Common.assertCodec
      s
      AttackerUnblocked.codec
      ( AttackerUnblocked.MkAttackerUnblocked
          { AttackerUnblocked.attacker = ObjectId.MkObjectId 1,
            AttackerUnblocked.defender = PlayerId.MkPlayerId 2
          }
      )
      " {\"attacker\":1,\"defender\":2} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AttackerUnblocked.codec
