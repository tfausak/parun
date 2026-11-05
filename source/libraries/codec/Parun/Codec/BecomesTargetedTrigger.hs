{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.BecomesTargetedTrigger where

import qualified Parun.Codec.ActingPermanent as ActingPermanent
import qualified Parun.Codec.Batching as Batching
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.StackObjectKind as StackObjectKind
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.BecomesTargetedTrigger as BecomesTargetedTrigger

-- | A bare object keyed by the record's field names. Every field at its
-- default writes no key (BecomesTargetedTrigger.defaultValue).
codec :: Codec.Codec BecomesTargetedTrigger.BecomesTargetedTrigger
codec = Fields.object $ do
  permanent <- Fields.defaulted "permanent" (BecomesTargetedTrigger.permanent BecomesTargetedTrigger.defaultValue) ActingPermanent.codec BecomesTargetedTrigger.permanent
  relation <- Fields.defaulted "relation" (BecomesTargetedTrigger.relation BecomesTargetedTrigger.defaultValue) PlayerRelation.codec BecomesTargetedTrigger.relation
  kind <- Fields.defaulted "kind" (BecomesTargetedTrigger.kind BecomesTargetedTrigger.defaultValue) (Common.maybe StackObjectKind.codec) BecomesTargetedTrigger.kind
  includesYou <- Fields.defaulted "includesYou" (BecomesTargetedTrigger.includesYou BecomesTargetedTrigger.defaultValue) Common.boolean BecomesTargetedTrigger.includesYou
  batching <- Fields.defaulted "batching" (BecomesTargetedTrigger.batching BecomesTargetedTrigger.defaultValue) Batching.codec BecomesTargetedTrigger.batching
  pure
    BecomesTargetedTrigger.MkBecomesTargetedTrigger
      { BecomesTargetedTrigger.permanent = permanent,
        BecomesTargetedTrigger.relation = relation,
        BecomesTargetedTrigger.kind = kind,
        BecomesTargetedTrigger.includesYou = includesYou,
        BecomesTargetedTrigger.batching = batching
      }
