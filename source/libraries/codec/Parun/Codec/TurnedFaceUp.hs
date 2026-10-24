{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.TurnedFaceUp where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.TurnedFaceUp as TurnedFaceUp

-- | Parun.Codec.Transformed's shape: a bare object keyed by the record's field
-- names. Runtime-only, GameEvent serialising transcripts rather than card data.
codec :: Codec.Codec TurnedFaceUp.TurnedFaceUp
codec = Fields.object $ do
  object <- Fields.required "object" ObjectId.codec TurnedFaceUp.object
  announcedX <- Fields.defaulted "announcedX" Nothing (Common.maybe Common.natural) TurnedFaceUp.announcedX
  pure
    TurnedFaceUp.MkTurnedFaceUp
      { TurnedFaceUp.object = object,
        TurnedFaceUp.announcedX = announcedX
      }
