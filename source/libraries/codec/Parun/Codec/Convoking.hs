{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Convoking where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Convoking as Convoking

-- | A bare object keyed by the record's field names. Runtime-only: GameEvent
-- serialises transcripts, never card data.
codec :: Codec.Codec Convoking.Convoking
codec = Fields.object $ do
  spell <- Fields.required "spell" ObjectId.codec Convoking.spell
  convokedBy <- Fields.required "convokedBy" (Common.set ObjectId.codec) Convoking.convokedBy
  pure
    Convoking.MkConvoking
      { Convoking.spell = spell,
        Convoking.convokedBy = convokedBy
      }
