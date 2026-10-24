{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PreventNextDamage where

import qualified Data.Sequence as Seq
import qualified Data.Typeable as Typeable
import qualified Parun.Codec.DamageKind as DamageKind
import qualified Parun.Codec.Duration as Duration
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PreventNextDamage as PreventNextDamage

-- | A bare object keyed by the record's field names, replacing the
-- three-or-four-element array this arm used to write.
--
-- The effect codec is a PARAMETER rather than an import, for the reason
-- Parun.Types.PreventNextDamage gives: the record is parametric in the effect so
-- that neither module has to name the other.
codec ::
  (Typeable.Typeable effect, Eq effect) =>
  Codec.Codec effect ->
  Codec.Codec (PreventNextDamage.PreventNextDamage effect)
codec effectCodec = Fields.object $ do
  duration <- Fields.required "duration" Duration.codec PreventNextDamage.duration
  kind <- Fields.defaulted "kind" Nothing (Common.maybe DamageKind.codec) PreventNextDamage.kind
  ref <- Fields.defaulted "ref" Nothing (Common.maybe ObjectRef.codec) PreventNextDamage.ref
  whatRecipient <- Fields.defaulted "whatRecipient" Nothing (Common.maybe (Filter.codec Keyword.codec)) PreventNextDamage.whatRecipient
  whoRecipient <- Fields.defaulted "whoRecipient" Nothing (Common.maybe PlayerRelation.codec) PreventNextDamage.whoRecipient
  chosenSource <- Fields.defaulted "chosenSource" Nothing (Common.maybe (Filter.codec Keyword.codec)) PreventNextDamage.chosenSource
  quantity <- Fields.required "quantity" Quantity.codec PreventNextDamage.quantity
  riders <- Fields.defaulted "riders" Seq.empty (Common.seq effectCodec) PreventNextDamage.riders
  pure
    PreventNextDamage.MkPreventNextDamage
      { PreventNextDamage.duration = duration,
        PreventNextDamage.kind = kind,
        PreventNextDamage.ref = ref,
        PreventNextDamage.whatRecipient = whatRecipient,
        PreventNextDamage.whoRecipient = whoRecipient,
        PreventNextDamage.chosenSource = chosenSource,
        PreventNextDamage.quantity = quantity,
        PreventNextDamage.riders = riders
      }
