{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.BecameTarget where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.Recipient as Recipient
import qualified Parun.Codec.StackObjectKind as StackObjectKind
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.BecameTarget as BecameTarget

-- | A bare object keyed by the record's field names. Runtime-only: GameEvent
-- serialises transcripts, never card data.
codec :: Codec.Codec BecameTarget.BecameTarget
codec = Fields.object $ do
  targeted <- Fields.required "targeted" Recipient.codec BecameTarget.targeted
  source <- Fields.required "source" ObjectId.codec BecameTarget.source
  kind <- Fields.required "kind" StackObjectKind.codec BecameTarget.kind
  controller <- Fields.required "controller" PlayerId.codec BecameTarget.controller
  pure
    BecameTarget.MkBecameTarget
      { BecameTarget.targeted = targeted,
        BecameTarget.source = source,
        BecameTarget.kind = kind,
        BecameTarget.controller = controller
      }
