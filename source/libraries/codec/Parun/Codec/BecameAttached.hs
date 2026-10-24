{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.BecameAttached where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.Recipient as Recipient
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.BecameAttached as BecameAttached

-- | A bare object keyed by the record's field names. Runtime-only: GameEvent
-- serialises transcripts, never card data.
codec :: Codec.Codec BecameAttached.BecameAttached
codec = Fields.object $ do
  attachment <- Fields.required "attachment" ObjectId.codec BecameAttached.attachment
  host <- Fields.required "host" Recipient.codec BecameAttached.host
  pure
    BecameAttached.MkBecameAttached
      { BecameAttached.attachment = attachment,
        BecameAttached.host = host
      }
