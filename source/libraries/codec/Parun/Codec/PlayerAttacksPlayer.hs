{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PlayerAttacksPlayer where

import qualified Parun.Codec.AttackedPlayer as AttackedPlayer
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PlayerAttacksPlayer as PlayerAttacksPlayer

-- | A bare object keyed by the record's field names, as
-- Parun.Codec.PlayerAttacksWith is. Both keys are required: rule 508.3e names
-- both subjects, and neither has a default -- a card that qualifies only the
-- declaring side writes Related AnyPlayer on the other, which is what the twenty-four
-- printings of the bare "attacks a player" say.
codec :: Codec.Codec PlayerAttacksPlayer.PlayerAttacksPlayer
codec = Fields.object $ do
  attacker <- Fields.required "attacker" PlayerRelation.codec PlayerAttacksPlayer.attacker
  attacked <- Fields.required "attacked" AttackedPlayer.codec PlayerAttacksPlayer.attacked
  pure PlayerAttacksPlayer.MkPlayerAttacksPlayer {PlayerAttacksPlayer.attacker = attacker, PlayerAttacksPlayer.attacked = attacked}
