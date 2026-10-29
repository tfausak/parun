{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.LeftTheGame where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.LeftTheGame as LeftTheGame

-- | A bare object keyed by the record's field names, as
-- Parun.Codec.PlayerActsOn is. Both keys are required.
codec :: Codec.Codec LeftTheGame.LeftTheGame
codec = Fields.object $ do
  object <- Fields.required "object" ObjectId.codec LeftTheGame.object
  from <- Fields.required "from" Zone.codec LeftTheGame.from
  pure LeftTheGame.MkLeftTheGame {LeftTheGame.object = object, LeftTheGame.from = from}
