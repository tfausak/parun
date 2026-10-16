module Pawl.Codec.RevealWindowSpec where

import qualified Pawl.Codec.RevealWindow as RevealWindow
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.RevealWindow as RevealWindow

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.RevealWindow" $ do
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
