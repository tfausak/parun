module Pawl.Codec.SideDeckSpec where

import qualified Pawl.Codec.SideDeck as SideDeck
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.SideDeck as SideDeck

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.SideDeck" $ do
  Spec.it s "Attraction" $
    Common.assertCodec s SideDeck.codec SideDeck.Attraction " {\"type\":\"Attraction\"} "
  Spec.it s "Contraption" $
    Common.assertCodec s SideDeck.codec SideDeck.Contraption " {\"type\":\"Contraption\"} "
  Spec.it s "Planar" $
    Common.assertCodec s SideDeck.codec SideDeck.Planar " {\"type\":\"Planar\"} "
  Spec.it s "Scheme" $
    Common.assertCodec s SideDeck.codec SideDeck.Scheme " {\"type\":\"Scheme\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s SideDeck.codec
