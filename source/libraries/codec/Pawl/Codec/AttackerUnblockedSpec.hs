module Pawl.Codec.AttackerUnblockedSpec where

import qualified Pawl.Codec.AttackerUnblocked as AttackerUnblocked
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.AttackerUnblocked as AttackerUnblocked
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.AttackerUnblocked" $ do
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
