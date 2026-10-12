module Pawl.Codec.ShowsSpec where

import qualified Pawl.Codec.Shows as Shows
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Audience as Audience
import qualified Pawl.Types.ShownCards as ShownCards
import qualified Pawl.Types.Shows as Shows

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.Shows" $ do
  -- Fblthp, Lost on the Range's look: the top card, to its owner alone.
  Spec.it s "MkShows" $
    Common.assertCodec
      s
      Shows.codec
      (Shows.MkShows ShownCards.TopOfLibrary Audience.ThatPlayer)
      " {\"cards\":{\"type\":\"TopOfLibrary\"},\"to\":{\"type\":\"ThatPlayer\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Shows.codec
