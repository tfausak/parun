{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.SacrificeEffect where

import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.Sacrificer as Sacrificer
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.SacrificeEffect as SacrificeEffect
import qualified Parun.Types.Sacrificer as Sacrificer

-- | The sacrificer is ELIDED when it is CR 701.21a's ordinary "sacrifice it",
-- which is every card in the pool but Golgothian Sylex and City in a Bottle;
-- the other arm is otherwise written only by the emblem Parun.Engine.Ring mints,
-- and that is not card data. The count slot is elided when absent, as
-- Parun.Codec.Destroy's are.
codec :: Codec.Codec SacrificeEffect.SacrificeEffect
codec = Fields.object $ do
  ref <- Fields.required "ref" ObjectRef.codec SacrificeEffect.ref
  sacrificer <- Fields.defaulted "sacrificer" Sacrificer.EffectController Sacrificer.codec SacrificeEffect.sacrificer
  sacrificed <- Fields.defaulted "sacrificed" Nothing (Common.maybe SlotName.codec) SacrificeEffect.sacrificed
  pure
    SacrificeEffect.MkSacrificeEffect
      { SacrificeEffect.ref = ref,
        SacrificeEffect.sacrificer = sacrificer,
        SacrificeEffect.sacrificed = sacrificed
      }
