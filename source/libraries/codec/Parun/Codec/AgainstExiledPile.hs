{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AgainstExiledPile where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.ExiledPile as ExiledPile
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AgainstExiledPile as AgainstExiledPile

-- | A bare object keyed by the record's field names. The quantity codec is a
-- PARAMETER for Parun.Codec.AgainstSlot's reason.
codec :: (Typeable.Typeable quantity) => Codec.Codec quantity -> Codec.Codec (AgainstExiledPile.AgainstExiledPile quantity)
codec quantityCodec = Fields.object $ do
  pile <- Fields.required "pile" ExiledPile.codec AgainstExiledPile.pile
  quantity <- Fields.required "quantity" quantityCodec AgainstExiledPile.quantity
  pure AgainstExiledPile.MkAgainstExiledPile {AgainstExiledPile.pile = pile, AgainstExiledPile.quantity = quantity}
