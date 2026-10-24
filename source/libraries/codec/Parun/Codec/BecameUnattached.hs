{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.BecameUnattached where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.Recipient as Recipient
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.BecameUnattached as BecameUnattached

-- | A bare object keyed by the record's field names. Runtime-only: GameEvent
-- serialises transcripts, never card data.
codec :: Codec.Codec BecameUnattached.BecameUnattached
codec = Fields.object $ do
  attachment <- Fields.required "attachment" ObjectId.codec BecameUnattached.attachment
  host <- Fields.required "host" Recipient.codec BecameUnattached.host
  pure
    BecameUnattached.MkBecameUnattached
      { BecameUnattached.attachment = attachment,
        BecameUnattached.host = host
      }
