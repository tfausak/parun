module Parun.Codec.ExileLookerSpec where

import qualified Parun.Codec.ExileLooker as ExileLooker
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ExileLooker as ExileLooker
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ExileLooker" $ do
  -- CR 406.3's grant: the seat the instruction named.
  Spec.it s "a seat" $
    Common.assertCodec
      s
      ExileLooker.codec
      (ExileLooker.ThePlayer (PlayerId.MkPlayerId 1))
      " {\"type\":\"ThePlayer\",\"value\":1} "
  -- CR 702.75a's: no seat at all.
  Spec.it s "the exiling permanent's controller" $
    Common.assertCodec
      s
      ExileLooker.codec
      ExileLooker.TheExiler
      " {\"type\":\"TheExiler\"} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s ExileLooker.codec
