module Parun.Codec.DrawRevealSpec where

import qualified Parun.Codec.DrawReveal as DrawReveal
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.DrawReveal as DrawReveal
import qualified Parun.Types.RevealObligation as RevealObligation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DrawReveal" $ do
  -- Rowen's "the first card you draw each turn".
  Spec.it s "MkDrawReveal, both keys" $
    Common.assertCodec
      s
      DrawReveal.codec
      (DrawReveal.MkDrawReveal {DrawReveal.obligation = RevealObligation.Optional, DrawReveal.nth = Just 1})
      " {\"obligation\":{\"type\":\"Optional\"},\"nth\":1} "
  -- Booby Trap's "each card they draw": no ordinal, so no key.
  Spec.it s "no ordinal writes no key" $
    Common.assertCodec
      s
      DrawReveal.codec
      (DrawReveal.MkDrawReveal RevealObligation.Mandatory Nothing)
      " {\"obligation\":{\"type\":\"Mandatory\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s DrawReveal.codec
