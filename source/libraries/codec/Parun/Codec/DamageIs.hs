{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DamageIs where

import qualified Parun.Codec.Reference as Reference
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DamageIs as DamageIs

codec :: Codec.Codec DamageIs.DamageIs
codec = Fields.object $ do
  object <- Fields.required "object" Reference.codec DamageIs.object
  damage <- Fields.required "damage" Common.natural DamageIs.damage
  pure DamageIs.MkDamageIs {DamageIs.object = object, DamageIs.damage = damage}
