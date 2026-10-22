{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.AttackerUnblocked where

import qualified Pawl.Codec.ObjectId as ObjectId
import qualified Pawl.Codec.PlayerId as PlayerId
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.AttackerUnblocked as AttackerUnblocked

-- | A bare object keyed by the record's field names. Runtime-only: GameEvent
-- serialises transcripts, never card data.
codec :: Codec.Codec AttackerUnblocked.AttackerUnblocked
codec = Fields.object $ do
  attacker <- Fields.required "attacker" ObjectId.codec AttackerUnblocked.attacker
  defender <- Fields.required "defender" PlayerId.codec AttackerUnblocked.defender
  pure
    AttackerUnblocked.MkAttackerUnblocked
      { AttackerUnblocked.attacker = attacker,
        AttackerUnblocked.defender = defender
      }
