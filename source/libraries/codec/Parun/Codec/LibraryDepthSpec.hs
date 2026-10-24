module Parun.Codec.LibraryDepthSpec where

import qualified Parun.Codec.LibraryDepth as LibraryDepth
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.LibraryDepth as LibraryDepth

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LibraryDepth" $ do
  -- Calim, Djinn Emperor's "seventh from the top".
  Spec.it s "FromTop" $
    Common.assertCodec
      s
      LibraryDepth.codec
      (LibraryDepth.FromTop 7)
      " {\"type\":\"FromTop\",\"value\":7} "
  -- Mine Security's "into the top eight cards of your library at random".
  Spec.it s "AtRandomInTop" $
    Common.assertCodec
      s
      LibraryDepth.codec
      (LibraryDepth.AtRandomInTop 8)
      " {\"type\":\"AtRandomInTop\",\"value\":8} "
  Spec.it s "has a schema" $ Common.assertHasSchema s LibraryDepth.codec
