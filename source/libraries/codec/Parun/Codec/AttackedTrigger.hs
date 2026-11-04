{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AttackedTrigger where

import qualified Parun.Codec.AttackedSubject as AttackedSubject
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AttackedTrigger as AttackedTrigger

-- | A bare object keyed by the record's field names. The attacked key is
-- required; CR 508.3b's "is attacked" writes no attacker.
codec :: Codec.Codec AttackedTrigger.AttackedTrigger
codec = Fields.object $ do
  attacker <- Fields.defaulted "attacker" Nothing (Common.maybe PlayerRelation.codec) AttackedTrigger.attacker
  attacked <- Fields.required "attacked" AttackedSubject.codec AttackedTrigger.attacked
  pure AttackedTrigger.MkAttackedTrigger {AttackedTrigger.attacker = attacker, AttackedTrigger.attacked = attacked}
