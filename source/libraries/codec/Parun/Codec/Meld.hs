{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Meld where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Meld as Meld

-- | Both keys required: CR 701.42a names the cards and the combined back face,
-- and neither has a default a card file could elide.
--
-- The card codec is a PARAMETER, Parun.Codec.Create's posture: this arm is where
-- card data nests inside card data, and Parun.Codec.Card is what ties the knot.
codec :: (Typeable.Typeable card) => Codec.Codec card -> Codec.Codec (Meld.Meld card)
codec cardCodec = Fields.object $ do
  objects <- Fields.required "objects" ObjectRef.codec Meld.objects
  result <- Fields.required "result" cardCodec Meld.result
  pure
    Meld.MkMeld
      { Meld.objects = objects,
        Meld.result = result
      }
