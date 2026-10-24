{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PreventAllDamage where

import qualified Data.Sequence as Seq
import qualified Data.Typeable as Typeable
import qualified Parun.Codec.DamageDirection as DamageDirection
import qualified Parun.Codec.DamageKind as DamageKind
import qualified Parun.Codec.Duration as Duration
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DamageDirection as DamageDirection
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PreventAllDamage as PreventAllDamage

-- | A bare object keyed by the record's field names, as
-- Parun.Codec.PreventNextDamage writes the countdown shield's.
--
-- Every key but `duration` is 'Fields.defaulted': a card naming no kind,
-- shielding a recipient and carrying no CR 615.5 clause writes only `duration`
-- and `ref`.
--
-- The effect codec is a PARAMETER rather than an import, for the reason
-- Parun.Types.PreventAllDamage gives: the record is parametric in the effect so
-- that neither module has to name the other.
codec ::
  (Typeable.Typeable effect, Eq effect) =>
  Codec.Codec effect ->
  Codec.Codec (PreventAllDamage.PreventAllDamage effect)
codec effectCodec = Fields.object $ do
  duration <- Fields.required "duration" Duration.codec PreventAllDamage.duration
  kind <- Fields.defaulted "kind" Nothing (Common.maybe DamageKind.codec) PreventAllDamage.kind
  ref <- Fields.defaulted "ref" Nothing (Common.maybe ObjectRef.codec) PreventAllDamage.ref
  whatRecipient <- Fields.defaulted "whatRecipient" Nothing (Common.maybe (Filter.codec Keyword.codec)) PreventAllDamage.whatRecipient
  whoRecipient <- Fields.defaulted "whoRecipient" Nothing (Common.maybe PlayerRelation.codec) PreventAllDamage.whoRecipient
  direction <- Fields.defaulted "direction" DamageDirection.DealtTo DamageDirection.codec PreventAllDamage.direction
  chosenSource <- Fields.defaulted "chosenSource" Nothing (Common.maybe (Filter.codec Keyword.codec)) PreventAllDamage.chosenSource
  whatSource <- Fields.defaulted "whatSource" (Filter.And []) (Filter.codec Keyword.codec) PreventAllDamage.whatSource
  riders <- Fields.defaulted "riders" Seq.empty (Common.seq effectCodec) PreventAllDamage.riders
  pure
    PreventAllDamage.MkPreventAllDamage
      { PreventAllDamage.duration = duration,
        PreventAllDamage.kind = kind,
        PreventAllDamage.ref = ref,
        PreventAllDamage.whatRecipient = whatRecipient,
        PreventAllDamage.whoRecipient = whoRecipient,
        PreventAllDamage.direction = direction,
        PreventAllDamage.chosenSource = chosenSource,
        PreventAllDamage.whatSource = whatSource,
        PreventAllDamage.riders = riders
      }
