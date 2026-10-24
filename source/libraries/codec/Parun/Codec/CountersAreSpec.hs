module Parun.Codec.CountersAreSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.CountersAre as CountersAre
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CounterKind as CounterKind.Type
import qualified Parun.Types.CountersAre as CountersAre.Type
import qualified Parun.Types.Label as Label.Type
import qualified Parun.Types.Reference as Reference.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CountersAre" $ do
  Spec.it s "the kind is tagged as a placement's is" $
    Common.assertCodec
      s
      CountersAre.codec
      (CountersAre.Type.MkCountersAre (Reference.Type.Labelled (Label.Type.MkLabel (Text.pack "jace"))) CounterKind.Type.Loyalty 3)
      " {\"object\":\"$jace\",\"kind\":{\"type\":\"Loyalty\"},\"count\":3} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s CountersAre.codec
