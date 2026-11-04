module Parun.Codec.CompanyCountSpec where

import qualified Parun.Codec.CompanyCount as CompanyCount
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CompanyCount as CompanyCount

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CompanyCount" $ do
  Spec.it s "AtLeastOthers carries its count" $
    Common.assertCodec s CompanyCount.codec (CompanyCount.AtLeastOthers 2) " {\"type\":\"AtLeastOthers\",\"value\":2} "
  Spec.it s "NoOthers" $
    Common.assertCodec s CompanyCount.codec CompanyCount.NoOthers " {\"type\":\"NoOthers\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CompanyCount.codec
