{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AttackerDeclared where

import qualified Parun.Codec.AttackTarget as AttackTarget
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AttackerDeclared as AttackerDeclared

-- | A bare object keyed by the record's field names, replacing the positional
-- array this payload used to be. Runtime-only: GameEvent serialises transcripts,
-- never card data.
codec :: Codec.Codec AttackerDeclared.AttackerDeclared
codec = Fields.object $ do
  attacker <- Fields.required "attacker" ObjectId.codec AttackerDeclared.attacker
  defender <- Fields.required "defender" PlayerId.codec AttackerDeclared.defender
  target <- Fields.required "target" AttackTarget.codec AttackerDeclared.target
  count <- Fields.required "count" Common.natural AttackerDeclared.count
  attackingPlayer <- Fields.required "attackingPlayer" PlayerId.codec AttackerDeclared.attackingPlayer
  pure
    AttackerDeclared.MkAttackerDeclared
      { AttackerDeclared.attacker = attacker,
        AttackerDeclared.defender = defender,
        AttackerDeclared.target = target,
        AttackerDeclared.count = count,
        AttackerDeclared.attackingPlayer = attackingPlayer
      }
