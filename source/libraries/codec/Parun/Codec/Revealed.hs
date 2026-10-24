{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Revealed where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Parun.Codec.RevealCause as RevealCause
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Revealed as Revealed

-- | A bare object keyed by the record's field names, replacing the positional
-- array this payload used to be. Runtime-only: GameEvent serialises transcripts,
-- never card data.
codec :: Codec.Codec Revealed.Revealed
codec = Fields.object $ do
  player <- Fields.required "player" PlayerId.codec Revealed.player
  card <- Fields.required "card" ObjectId.codec Revealed.card
  cause <- Fields.required "cause" RevealCause.codec Revealed.cause
  characteristics <- Fields.required "characteristics" ProjectedCharacteristics.codec Revealed.characteristics
  pure
    Revealed.MkRevealed
      { Revealed.player = player,
        Revealed.card = card,
        Revealed.cause = cause,
        Revealed.characteristics = characteristics
      }
