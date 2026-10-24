{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AgainstLastCardExiledWith where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AgainstLastCardExiledWith as AgainstLastCardExiledWith

-- | A bare object keyed by the record's field names. The quantity codec is a
-- PARAMETER for Parun.Codec.AgainstSlot's reason.
codec :: (Typeable.Typeable quantity) => Codec.Codec quantity -> Codec.Codec (AgainstLastCardExiledWith.AgainstLastCardExiledWith quantity)
codec quantityCodec = Fields.object $ do
  criterion <- Fields.required "filter" (Filter.codec Keyword.codec) AgainstLastCardExiledWith.filter
  quantity <- Fields.required "quantity" quantityCodec AgainstLastCardExiledWith.quantity
  pure AgainstLastCardExiledWith.MkAgainstLastCardExiledWith {AgainstLastCardExiledWith.filter = criterion, AgainstLastCardExiledWith.quantity = quantity}
