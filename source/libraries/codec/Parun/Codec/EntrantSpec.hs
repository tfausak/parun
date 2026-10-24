module Parun.Codec.EntrantSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Entrant as Entrant
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Entrant as Entrant.Type
import qualified Parun.Types.Label as Label

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Entrant" $ do
  Spec.it s "works" $
    Common.assertCodec s Entrant.codec (Entrant.Type.MkEntrant (Label.MkLabel (Text.pack "alice")) [Text.pack "12 Grizzly Bears", Text.pack "8 Forest"]) "{\"name\":\"alice\",\"deck\":[\"12 Grizzly Bears\",\"8 Forest\"]}"
  Spec.it s "has a schema" $
    Common.assertHasSchema s Entrant.codec
