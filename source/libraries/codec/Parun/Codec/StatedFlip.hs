{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.StatedFlip where

import qualified Parun.Codec.CoinFace as CoinFace
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.StatedFlip as StatedFlip

-- | A bare object keyed by the record's field names. Every field defaults, so a
-- card writes only the half of CR 705.3 it states.
codec :: Codec.Codec StatedFlip.StatedFlip
codec = Fields.object $ do
  face <- Fields.defaulted "face" Nothing (Common.maybe CoinFace.codec) StatedFlip.face
  wins <- Fields.defaulted "wins" False Common.boolean StatedFlip.wins
  firstEachTurn <- Fields.defaulted "firstEachTurn" False Common.boolean StatedFlip.firstEachTurn
  pure
    StatedFlip.MkStatedFlip
      { StatedFlip.face = face,
        StatedFlip.wins = wins,
        StatedFlip.firstEachTurn = firstEachTurn
      }
