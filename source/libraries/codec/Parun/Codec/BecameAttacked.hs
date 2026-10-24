{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.BecameAttacked where

import qualified Parun.Codec.AttackTarget as AttackTarget
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.BecameAttacked as BecameAttacked

-- | A bare object keyed by the record's field names, Parun.Codec.AttackerDeclared's
-- shape. Runtime-only: GameEvent serialises transcripts, never card data.
codec :: Codec.Codec BecameAttacked.BecameAttacked
codec = Fields.object $ do
  attacker <- Fields.required "attacker" PlayerId.codec BecameAttacked.attacker
  target <- Fields.required "target" AttackTarget.codec BecameAttacked.target
  pure
    BecameAttacked.MkBecameAttacked
      { BecameAttacked.attacker = attacker,
        BecameAttacked.target = target
      }
