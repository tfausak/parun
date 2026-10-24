module Parun.Codec.RevealWindowSpec where

import qualified Parun.Codec.RevealWindow as RevealWindow
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.RevealWindow as RevealWindow

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.RevealWindow" $ do
  Spec.it s "WhileOnStack" $
    Common.assertCodec
      s
      RevealWindow.codec
      (RevealWindow.WhileOnStack (ObjectId.MkObjectId 3))
      " {\"type\":\"WhileOnStack\",\"value\":3} "
  Spec.it s "UntilPriority" $
    Common.assertCodec
      s
      RevealWindow.codec
      RevealWindow.UntilPriority
      " {\"type\":\"UntilPriority\"} "
  Spec.it s "UntilFirstTurn" $
    Common.assertCodec
      s
      RevealWindow.codec
      RevealWindow.UntilFirstTurn
      " {\"type\":\"UntilFirstTurn\"} "
  Spec.it s "DuringUpkeep" $
    Common.assertCodec
      s
      RevealWindow.codec
      (RevealWindow.DuringUpkeep 2)
      " {\"type\":\"DuringUpkeep\",\"value\":2} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s RevealWindow.codec
