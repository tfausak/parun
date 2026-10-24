{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PileDraw where

import qualified Parun.Codec.Pile as Pile
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PileDraw as PileDraw

codec :: Codec.Codec PileDraw.PileDraw
codec = Fields.object $ do
  pile <- Fields.required "pile" Pile.codec PileDraw.pile
  ordinal <- Fields.required "ordinal" Common.natural PileDraw.ordinal
  pure
    PileDraw.MkPileDraw
      { PileDraw.pile = pile,
        PileDraw.ordinal = ordinal
      }
