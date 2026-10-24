module Parun.Codec.ShowsSpec where

import qualified Parun.Codec.Shows as Shows
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Audience as Audience
import qualified Parun.Types.ShownCards as ShownCards
import qualified Parun.Types.Shows as Shows

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Shows" $ do
  -- Fblthp, Lost on the Range's look: the top card, to its owner alone.
  Spec.it s "MkShows" $
    Common.assertCodec
      s
      Shows.codec
      (Shows.MkShows ShownCards.TopOfLibrary Audience.ThatPlayer)
      " {\"cards\":{\"type\":\"TopOfLibrary\"},\"to\":{\"type\":\"ThatPlayer\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Shows.codec
