module Parun.Codec.DefendersAreSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.DefendersAre as DefendersAre
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.DefendersAre as DefendersAre.Type
import qualified Parun.Types.Label as Label.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DefendersAre" $ do
  Spec.it s "in order" $
    Common.assertCodec
      s
      DefendersAre.codec
      (DefendersAre.Type.MkDefendersAre (fmap (Label.Type.MkLabel . Text.pack) ["carol", "bob"]))
      " {\"players\":[\"carol\",\"bob\"]} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s DefendersAre.codec
