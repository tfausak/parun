{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DeclarationTrigger where

import qualified Parun.Codec.AttackCount as AttackCount
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DeclarationTrigger as DeclarationTrigger

-- | A bare object keyed by the record's field names. The player is required;
-- CR 508.3d's bare "attacks" writes no count.
codec :: Codec.Codec DeclarationTrigger.DeclarationTrigger
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRelation.codec DeclarationTrigger.player
  attackers <- Fields.defaulted "attackers" Nothing (Common.maybe AttackCount.codec) DeclarationTrigger.attackers
  pure DeclarationTrigger.MkDeclarationTrigger {DeclarationTrigger.player = player, DeclarationTrigger.attackers = attackers}
