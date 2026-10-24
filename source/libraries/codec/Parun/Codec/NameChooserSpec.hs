module Parun.Codec.NameChooserSpec where

import qualified Parun.Codec.NameChooser as NameChooser
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.NameChooser as NameChooser

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.NameChooser" $ do
  Spec.it s "AnyChooser" $
    Common.assertCodec
      s
      NameChooser.codec
      NameChooser.AnyChooser
      " {\"type\":\"AnyChooser\"} "
  Spec.it s "CandidateOwner" $
    Common.assertCodec
      s
      NameChooser.codec
      NameChooser.CandidateOwner
      " {\"type\":\"CandidateOwner\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s NameChooser.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s NameChooser.codec
