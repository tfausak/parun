{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AttackersAre where

import qualified Parun.Codec.Reference as Reference
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AttackersAre as AttackersAre

-- | Keyed by attacker, as Parun.Codec.Move's blocks are: @{"$bear": "$bob"}@.
codec :: Codec.Codec AttackersAre.AttackersAre
codec = Fields.object $ do
  attackers <- Fields.required "attackers" (Common.textMap Reference.toText Reference.fromText Reference.codec) AttackersAre.attackers
  pure AttackersAre.MkAttackersAre {AttackersAre.attackers = attackers}
