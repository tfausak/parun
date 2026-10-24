module Parun.Codec.MonarchIsSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.MonarchIs as MonarchIs
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Label as Label.Type
import qualified Parun.Types.MonarchIs as MonarchIs.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.MonarchIs" $ do
  Spec.it s "a seat" $
    Common.assertCodec s MonarchIs.codec (MonarchIs.Type.MkMonarchIs (Just (Label.Type.MkLabel (Text.pack "alice")))) " {\"player\":\"alice\"} "
  Spec.it s "nobody is null" $
    Common.assertCodec s MonarchIs.codec (MonarchIs.Type.MkMonarchIs Nothing) " {\"player\":null} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s MonarchIs.codec
