module Parun.Codec.ManifestedDreadSpec where

import qualified Data.Sequence as Seq
import qualified Parun.Codec.ManifestedDread as ManifestedDread
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ManifestedDread as ManifestedDread
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ManifestedDread" $ do
  Spec.it s "MkManifestedDread" $
    Common.assertCodec
      s
      ManifestedDread.codec
      ( ManifestedDread.MkManifestedDread
          { ManifestedDread.player = PlayerId.MkPlayerId 0,
            ManifestedDread.cards = Seq.fromList [ObjectId.MkObjectId 7]
          }
      )
      " {\"player\":0,\"cards\":[7]} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ManifestedDread.codec
