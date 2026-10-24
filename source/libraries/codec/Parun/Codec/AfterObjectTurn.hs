{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AfterObjectTurn where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AfterObjectTurn as AfterObjectTurn

-- | A bare object keyed by the record's field names, like Parun.Codec.AfterTurn.
codec :: Codec.Codec AfterObjectTurn.AfterObjectTurn
codec = Fields.object $ do
  object <- Fields.required "object" ObjectId.codec AfterObjectTurn.object
  turn <- Fields.required "turn" Common.natural AfterObjectTurn.turn
  pure AfterObjectTurn.MkAfterObjectTurn {AfterObjectTurn.object = object, AfterObjectTurn.turn = turn}
