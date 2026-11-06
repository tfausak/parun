module Parun.Codec.FacedDilemmaSpec where

import qualified Parun.Codec.FacedDilemma as FacedDilemma
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.FacedDilemma as FacedDilemma
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.FacedDilemma" $ do
  Spec.it s "MkFacedDilemma" $
    Common.assertCodec
      s
      FacedDilemma.codec
      ( FacedDilemma.MkFacedDilemma
          { FacedDilemma.player = PlayerId.MkPlayerId 0,
            FacedDilemma.object = ObjectId.MkObjectId 7
          }
      )
      " {\"player\":0,\"object\":7} "
  Spec.it s "has a schema" $ Common.assertHasSchema s FacedDilemma.codec
