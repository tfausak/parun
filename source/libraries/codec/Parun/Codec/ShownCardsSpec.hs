module Parun.Codec.ShownCardsSpec where

import qualified Parun.Codec.ShownCards as ShownCards
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ShownCards as ShownCards

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ShownCards" $ do
  Spec.it s "Hand" $
    Common.assertCodec
      s
      ShownCards.codec
      ShownCards.Hand
      " {\"type\":\"Hand\"} "
  Spec.it s "TopOfLibrary" $
    Common.assertCodec
      s
      ShownCards.codec
      ShownCards.TopOfLibrary
      " {\"type\":\"TopOfLibrary\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s ShownCards.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s ShownCards.codec
