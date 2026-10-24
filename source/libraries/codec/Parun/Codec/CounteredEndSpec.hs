module Parun.Codec.CounteredEndSpec where

import qualified Parun.Codec.CounteredEnd as CounteredEnd
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CounteredEnd as CounteredEnd
import qualified Parun.Types.LibraryPosition as LibraryPosition

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CounteredEnd" $ do
  -- Memory Lapse's "on top".
  Spec.it s "Stated" $
    Common.assertCodec
      s
      CounteredEnd.codec
      (CounteredEnd.Stated LibraryPosition.Top)
      " {\"type\":\"Stated\",\"value\":{\"type\":\"Top\"}} "
  -- Hinder's "your choice of the top or bottom".
  Spec.it s "CounteringPlayerChooses" $
    Common.assertCodec
      s
      CounteredEnd.codec
      CounteredEnd.CounteringPlayerChooses
      " {\"type\":\"CounteringPlayerChooses\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CounteredEnd.codec
