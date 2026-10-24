module Parun.Codec.LifeIsSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.LifeIs as LifeIs
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Label as Label.Type
import qualified Parun.Types.LifeIs as LifeIs.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LifeIs" $ do
  Spec.it s "a player and a life total" $
    Common.assertCodec s LifeIs.codec (LifeIs.Type.MkLifeIs (Label.Type.MkLabel (Text.pack "bob")) 18) " {\"player\":\"bob\",\"life\":18} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s LifeIs.codec
