module Parun.Codec.PermanentWasSacrificedSpec where

import qualified Parun.Codec.PermanentWasSacrificed as PermanentWasSacrificed
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PermanentWasSacrificed as PermanentWasSacrificed
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PermanentWasSacrificed" $ do
  -- CR 701.21a.
  Spec.it s "MkPermanentWasSacrificed, both keys" $
    Common.assertCodec
      s
      PermanentWasSacrificed.codec
      ( PermanentWasSacrificed.MkPermanentWasSacrificed
          { PermanentWasSacrificed.player = PlayerId.MkPlayerId 0,
            PermanentWasSacrificed.permanent = ObjectId.MkObjectId 1
          }
      )
      " {\"player\":0,\"permanent\":1} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PermanentWasSacrificed.codec
