{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.BlocksDeclared where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.BlocksDeclared as BlocksDeclared

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be. Runtime-only: GameEvent serialises transcripts,
-- never card data.
codec :: Codec.Codec BlocksDeclared.BlocksDeclared
codec = Fields.object $ do
  blocker <- Fields.required "blocker" ObjectId.codec BlocksDeclared.blocker
  count <- Fields.required "count" Common.natural BlocksDeclared.count
  pure
    BlocksDeclared.MkBlocksDeclared
      { BlocksDeclared.blocker = blocker,
        BlocksDeclared.count = count
      }
