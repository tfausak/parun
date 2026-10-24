{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ConjureEntry where

import qualified Parun.Codec.TapState as TapState
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ConjureEntry as ConjureEntry

-- | Both keys defaulted, Parun.Codec.EntryRiders' spelling for the same two
-- riders, so a sentence states only what it prints.
codec :: Codec.Codec ConjureEntry.ConjureEntry
codec = Fields.object $ do
  tapped <- Fields.defaulted "tapped" (ConjureEntry.tapped ConjureEntry.defaultValue) TapState.codec ConjureEntry.tapped
  attacking <- Fields.defaulted "attacking" (ConjureEntry.attacking ConjureEntry.defaultValue) Common.boolean ConjureEntry.attacking
  pure ConjureEntry.MkConjureEntry {ConjureEntry.tapped = tapped, ConjureEntry.attacking = attacking}
