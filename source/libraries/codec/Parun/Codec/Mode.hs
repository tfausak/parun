{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Mode where

import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Clause as Clause
import qualified Parun.Codec.TargetSlot as TargetSlot
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Mode as Mode

-- | The wire format is unchanged by the conversion to a bundle; what it adds is
-- the schema.
codec :: (Typeable.Typeable card, Eq card, Typeable.Typeable ability, Eq ability) => Codec.Codec card -> Codec.Codec ability -> Codec.Codec (Mode.Mode card ability)
codec cardCodec abilityCodec = Fields.object $ do
  clauses <- Fields.defaulted "clauses" Seq.empty (Common.seq (Clause.codec cardCodec abilityCodec)) Mode.clauses
  targetSlots <- Fields.defaulted "targetSlots" Map.empty TargetSlot.codecMap Mode.targetSlots
  pure Mode.MkMode {Mode.clauses = clauses, Mode.targetSlots = targetSlots}
