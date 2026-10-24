module Parun.Codec.AfterObjectTurnSpec where

import qualified Parun.Codec.AfterObjectTurn as AfterObjectTurn
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AfterObjectTurn as AfterObjectTurn
import qualified Parun.Types.ObjectId as ObjectId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AfterObjectTurn" $ do
  -- Runtime-only, Parun.Codec.AfterTurnSpec's reason.
  Spec.it s "MkAfterObjectTurn, both keys" $
    Common.assertCodec
      s
      AfterObjectTurn.codec
      ( AfterObjectTurn.MkAfterObjectTurn
          { AfterObjectTurn.object = ObjectId.MkObjectId 5,
            AfterObjectTurn.turn = 7
          }
      )
      " {\"object\":5,\"turn\":7} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AfterObjectTurn.codec
