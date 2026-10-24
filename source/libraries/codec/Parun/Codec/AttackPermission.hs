{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AttackPermission where

import qualified Parun.Codec.Affected as Affected
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AttackPermission as AttackPermission

-- | An object with one named key, Parun.Codec.CrewRestriction's shape and for its
-- reason: the type is a newtype over one field.
codec :: Codec.Codec AttackPermission.AttackPermission
codec = Fields.object $ do
  affected <- Fields.required "affected" Affected.codec AttackPermission.affected
  pure AttackPermission.MkAttackPermission {AttackPermission.affected = affected}
