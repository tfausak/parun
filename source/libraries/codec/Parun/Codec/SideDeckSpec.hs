module Parun.Codec.SideDeckSpec where

import qualified Parun.Codec.SideDeck as SideDeck
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.SideDeck as SideDeck

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.SideDeck" $ do
  Spec.it s "Attraction" $
    Common.assertCodec s SideDeck.codec SideDeck.Attraction " \"Attraction\" "
  Spec.it s "Contraption" $
    Common.assertCodec s SideDeck.codec SideDeck.Contraption " \"Contraption\" "
  Spec.it s "Planar" $
    Common.assertCodec s SideDeck.codec SideDeck.Planar " \"Planar\" "
  Spec.it s "Scheme" $
    Common.assertCodec s SideDeck.codec SideDeck.Scheme " \"Scheme\" "
  Spec.it s "has a schema" $ Common.assertHasSchema s SideDeck.codec
