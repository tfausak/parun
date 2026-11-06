{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.FacedDilemma where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.FacedDilemma as FacedDilemma

-- | A bare object keyed by the record's field names. Runtime-only: GameEvent
-- serialises transcripts, never card data.
codec :: Codec.Codec FacedDilemma.FacedDilemma
codec = Fields.object $ do
  player <- Fields.required "player" PlayerId.codec FacedDilemma.player
  object <- Fields.required "object" ObjectId.codec FacedDilemma.object
  pure
    FacedDilemma.MkFacedDilemma
      { FacedDilemma.player = player,
        FacedDilemma.object = object
      }
