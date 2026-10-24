module Parun.Codec.TappedIsSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.TappedIs as TappedIs
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Label as Label.Type
import qualified Parun.Types.Reference as Reference.Type
import qualified Parun.Types.TapState as TapState.Type
import qualified Parun.Types.TappedIs as TappedIs.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TappedIs" $ do
  Spec.it s "tapped is a flag" $
    Common.assertCodec s TappedIs.codec (TappedIs.Type.MkTappedIs (Reference.Type.Labelled (Label.Type.MkLabel (Text.pack "bear"))) TapState.Type.Tapped) " {\"object\":\"$bear\",\"tapped\":true} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s TappedIs.codec
