module Parun.Codec.PartnerTextSpec where

import qualified Parun.Codec.PartnerText as PartnerText
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PartnerText as PartnerText

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PartnerText" $ do
  Spec.it s "FriendsForever" $
    Common.assertCodec
      s
      PartnerText.codec
      PartnerText.FriendsForever
      " {\"type\":\"FriendsForever\"} "

  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s PartnerText.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s PartnerText.codec
