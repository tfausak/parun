module Parun.Codec.TurnResumeSpec where

import qualified Parun.Codec.TurnResume as TurnResume
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.TurnResume as TurnResume

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TurnResume" $ do
  -- CR 117.3: a turn parked with its step's priority window open.
  Spec.it s "InWindow" $
    Common.assertCodec
      s
      TurnResume.codec
      TurnResume.InWindow
      " \"InWindow\" "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s TurnResume.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s TurnResume.codec
