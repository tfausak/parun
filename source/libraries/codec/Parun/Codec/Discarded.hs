{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Discarded where

import qualified Parun.Codec.DiscardCause as DiscardCause
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.MadnessCost as MadnessCost
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Discarded as Discarded

-- | A bare object keyed by the record's field names, replacing the positional
-- array this payload used to be. Runtime-only: GameEvent serialises transcripts,
-- never card data.
codec :: Codec.Codec Discarded.Discarded
codec = Fields.object $ do
  player <- Fields.required "player" PlayerId.codec Discarded.player
  card <- Fields.required "card" ObjectId.codec Discarded.card
  cause <- Fields.required "cause" DiscardCause.codec Discarded.cause
  madness <- Fields.required "madness" (Common.maybe (MadnessCost.codec Keyword.codec)) Discarded.madness
  -- Defaulted: only a discard an effect made sets it.
  causedBy <- Fields.defaulted "causedBy" Nothing (Common.maybe PlayerId.codec) Discarded.causedBy
  pure
    Discarded.MkDiscarded
      { Discarded.player = player,
        Discarded.card = card,
        Discarded.cause = cause,
        Discarded.madness = madness,
        Discarded.causedBy = causedBy
      }
