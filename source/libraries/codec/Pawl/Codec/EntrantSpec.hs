module Pawl.Codec.EntrantSpec where

import qualified Data.Text as Text
import qualified Pawl.Codec.Entrant as Entrant
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Entrant as Entrant.Type
import qualified Pawl.Types.Label as Label

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.Entrant" $ do
  Spec.it s "works" $
    Common.assertCodec s Entrant.codec (Entrant.Type.MkEntrant (Label.MkLabel (Text.pack "alice")) [Text.pack "12 Grizzly Bears", Text.pack "8 Forest"]) "{\"name\":\"alice\",\"deck\":[\"12 Grizzly Bears\",\"8 Forest\"]}"
  Spec.it s "has a schema" $
    Common.assertHasSchema s Entrant.codec
