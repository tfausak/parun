module Pawl.Codec.NameChooserSpec where

import qualified Pawl.Codec.NameChooser as NameChooser
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.NameChooser as NameChooser

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.NameChooser" $ do
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
