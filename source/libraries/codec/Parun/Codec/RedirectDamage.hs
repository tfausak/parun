{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.RedirectDamage where

import qualified Parun.Codec.DamageKind as DamageKind
import qualified Parun.Codec.Duration as Duration
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.Uses as Uses
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.RedirectDamage as RedirectDamage
import qualified Parun.Types.Uses as Uses.Type

-- | A bare object keyed by the record's field names. Naming them is the point:
-- 'RedirectDamage.from' and 'RedirectDamage.to' are both an ObjectRef, so a
-- positional payload let a card file redirect the damage backwards and still
-- decode.
--
-- CR 609.7a's chosen source is 'Fields.defaulted', as Parun.Codec.PreventAllDamage
-- writes the same field: a redirection naming no source (Turn the Tables) writes
-- exactly the keys it wrote before this field existed. So are CR 614.3's use
-- count and CR 609.7b's described source, for the same reason.
codec :: Codec.Codec RedirectDamage.RedirectDamage
codec = Fields.object $ do
  duration <- Fields.required "duration" Duration.codec RedirectDamage.duration
  kind <- Fields.defaulted "kind" Nothing (Common.maybe DamageKind.codec) RedirectDamage.kind
  amount <- Fields.defaulted "amount" Nothing (Common.maybe Quantity.codec) RedirectDamage.amount
  from <- Fields.defaulted "from" Nothing (Common.maybe ObjectRef.codec) RedirectDamage.from
  whatRecipient <- Fields.defaulted "whatRecipient" Nothing (Common.maybe (Filter.codec Keyword.codec)) RedirectDamage.whatRecipient
  whoRecipient <- Fields.defaulted "whoRecipient" Nothing (Common.maybe PlayerRelation.codec) RedirectDamage.whoRecipient
  to <- Fields.required "to" ObjectRef.codec RedirectDamage.to
  chosenSource <- Fields.defaulted "chosenSource" Nothing (Common.maybe (Filter.codec Keyword.codec)) RedirectDamage.chosenSource
  uses <- Fields.defaulted "uses" Uses.Type.Unlimited Uses.codec RedirectDamage.uses
  whatSource <- Fields.defaulted "whatSource" (Filter.And []) (Filter.codec Keyword.codec) RedirectDamage.whatSource
  pure
    RedirectDamage.MkRedirectDamage
      { RedirectDamage.duration = duration,
        RedirectDamage.kind = kind,
        RedirectDamage.amount = amount,
        RedirectDamage.from = from,
        RedirectDamage.whatRecipient = whatRecipient,
        RedirectDamage.whoRecipient = whoRecipient,
        RedirectDamage.to = to,
        RedirectDamage.chosenSource = chosenSource,
        RedirectDamage.uses = uses,
        RedirectDamage.whatSource = whatSource
      }
