{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.AgainstExiledPile where

import qualified Data.Typeable as Typeable
import qualified Pawl.Codec.ExiledPile as ExiledPile
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.AgainstExiledPile as AgainstExiledPile

-- | A bare object keyed by the record's field names. The quantity codec is a
-- PARAMETER for Pawl.Codec.AgainstSlot's reason.
codec :: (Typeable.Typeable quantity) => Codec.Codec quantity -> Codec.Codec (AgainstExiledPile.AgainstExiledPile quantity)
codec quantityCodec = Fields.object $ do
  pile <- Fields.required "pile" ExiledPile.codec AgainstExiledPile.pile
  quantity <- Fields.required "quantity" quantityCodec AgainstExiledPile.quantity
  pure AgainstExiledPile.MkAgainstExiledPile {AgainstExiledPile.pile = pile, AgainstExiledPile.quantity = quantity}
