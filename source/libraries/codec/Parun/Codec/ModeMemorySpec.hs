module Parun.Codec.ModeMemorySpec where

import qualified Parun.Codec.ModeMemory as ModeMemory
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ModeMemory as ModeMemory

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ModeMemory" $ do
  Spec.it s "ObjectLifetime" $
    Common.assertCodec
      s
      ModeMemory.codec
      ModeMemory.ObjectLifetime
      " {\"type\":\"ObjectLifetime\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s ModeMemory.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s ModeMemory.codec
