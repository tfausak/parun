module Parun.Codec.CastWindowSpec where

import qualified Parun.Codec.CastWindow as CastWindow
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CastWindow as CastWindow

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CastWindow" $ do
  Spec.it s "ThisTurn" $
    Common.assertCodec
      s
      CastWindow.codec
      CastWindow.ThisTurn
      " \"ThisTurn\" "
  Spec.it s "ThisGame" $
    Common.assertCodec
      s
      CastWindow.codec
      CastWindow.ThisGame
      " \"ThisGame\" "
  Spec.it s "BeforeEvaluated" $
    Common.assertCodec
      s
      CastWindow.codec
      CastWindow.BeforeEvaluated
      " \"BeforeEvaluated\" "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s CastWindow.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s CastWindow.codec
