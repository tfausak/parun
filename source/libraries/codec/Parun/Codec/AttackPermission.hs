{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AttackPermission where

import qualified Parun.Codec.Affected as Affected
import qualified Parun.Codec.AttackWaiver as AttackWaiver
import qualified Parun.Codec.Condition as Condition
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AttackPermission as AttackPermission
import qualified Parun.Types.AttackWaiver as AttackWaiver.Type

-- | An object with named keys, `while` omitted when Nothing, `waives` when
-- Defender.
codec :: Codec.Codec AttackPermission.AttackPermission
codec = Fields.object $ do
  affected <- Fields.required "affected" Affected.codec AttackPermission.affected
  while <- Fields.defaulted "while" Nothing (Common.maybe Condition.codec) AttackPermission.while
  waives <- Fields.defaulted "waives" AttackWaiver.Type.Defender AttackWaiver.codec AttackPermission.waives
  pure AttackPermission.MkAttackPermission {AttackPermission.affected = affected, AttackPermission.while = while, AttackPermission.waives = waives}
