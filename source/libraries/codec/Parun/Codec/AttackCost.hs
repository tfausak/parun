{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AttackCost where

import qualified Parun.Codec.Affected as Affected
import qualified Parun.Codec.AttackCostScope as AttackCostScope
import qualified Parun.Codec.PerCreature as PerCreature
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AttackCost as AttackCost

-- | "subject" is Parun.Codec.AttackRequirement's key and names the same axis:
-- the creatures the effect is ABOUT, never Parun.Codec.BlockRequirement's
-- "attacker", which is the object CR 509.1c's requirements carry instead.
-- "perAttacker" is one attacker's share, not the card's whole cost -- a "for
-- each" repeats it per taxed attacker before CR 508.1h totals the declaration.
--
-- "scope" is Fields.required and not defaulted to the narrow arm, though the
-- narrow arm IS the default reading of an unqualified "you". A defaulted key
-- would let a card transcribed a clause short play as a Ghostly Prison -- a
-- weaker card than printed, in the attacking player's favour -- so every card
-- states which family it belongs to.
codec :: Codec.Codec AttackCost.AttackCost
codec = Fields.object $ do
  subject <- Fields.required "subject" Affected.codec AttackCost.subject
  perAttacker <- Fields.required "perAttacker" PerCreature.codec AttackCost.perAttacker
  scope <- Fields.required "scope" AttackCostScope.codec AttackCost.scope
  pure
    AttackCost.MkAttackCost
      { AttackCost.subject = subject,
        AttackCost.perAttacker = perAttacker,
        AttackCost.scope = scope
      }
