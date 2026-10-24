{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ManaAdded where

import qualified Parun.Codec.ManaAddedCause as ManaAddedCause
import qualified Parun.Codec.ManaType as ManaType
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ManaAdded as ManaAdded

-- | A bare object keyed by the record's field names, every key required for
-- Parun.Codec.TappedForMana's reason: a log entry whose one producer
-- (Parun.Engine.Cost.tapForManaWith) always knows all three. The `cause` too:
-- both producers state it.
codec :: Codec.Codec ManaAdded.ManaAdded
codec = Fields.object $ do
  player <- Fields.required "player" PlayerId.codec ManaAdded.player
  source <- Fields.required "source" ObjectId.codec ManaAdded.source
  mana <- Fields.required "mana" (Common.set ManaType.codec) ManaAdded.mana
  cause <- Fields.required "cause" ManaAddedCause.codec ManaAdded.cause
  pure ManaAdded.MkManaAdded {ManaAdded.player = player, ManaAdded.source = source, ManaAdded.mana = mana, ManaAdded.cause = cause}
