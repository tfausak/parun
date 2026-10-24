{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AttackingPlayers where

import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AttackingPlayers as AttackingPlayers

-- | A bare object keyed by the record's field names. Card data, unlike its
-- neighbours under Parun.Codec.GameEvent: Curse of Vitality writes one.
codec :: Codec.Codec AttackingPlayers.AttackingPlayers
codec = Fields.object $ do
  relation <- Fields.required "relation" PlayerRelation.codec AttackingPlayers.relation
  attacked <- Fields.required "attacked" SlotName.codec AttackingPlayers.attacked
  pure
    AttackingPlayers.MkAttackingPlayers
      { AttackingPlayers.relation = relation,
        AttackingPlayers.attacked = attacked
      }
