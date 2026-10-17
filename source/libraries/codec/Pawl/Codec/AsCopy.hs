{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.AsCopy where

import qualified Data.Sequence as Seq
import qualified Data.Typeable as Typeable
import qualified Pawl.Codec.CopyClause as CopyClause
import qualified Pawl.Codec.CopyRecipient as CopyRecipient
import qualified Pawl.Codec.Duration as Duration
import qualified Pawl.Codec.Filter as Filter
import qualified Pawl.Codec.Keyword as Keyword
import qualified Pawl.Codec.Zone as Zone
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.AsCopy as AsCopy
import qualified Pawl.Types.CopyRecipient as CopyRecipient.Type
import qualified Pawl.Types.Zone as Zone.Type

-- | A bare object keyed by the record's field names, Pawl.Codec.WithCounters'
-- shape. @clauses@ is defaulted rather than required: CR 707.9's "except ..."
-- clause is absent from most printings, so a plain Clone writes the eligible
-- filter alone. @tapped@ is defaulted for the same reason: only a land that
-- enters tapped as a copy (Vesuva) writes it. So is @whenYouDo@, CR 707.9g's
-- linked trigger (Wall of Stolen Identity). @zone@ is defaulted to the
-- battlefield, which is where every printing but Superior Spider-Man's looks.
-- @duration@ is defaulted to Nothing, the copy every printing but Vesuvan
-- Shapeshifter's makes. @recipient@ is defaulted to the entering object and
-- @optional@ to CR 707.5's "may", which every printing but Metamorphic
-- Alteration's writes.
codec :: (Typeable.Typeable ability, Eq ability, Typeable.Typeable effect, Eq effect) => Codec.Codec ability -> Codec.Codec effect -> Codec.Codec (AsCopy.AsCopy ability effect)
codec abilityCodec effectCodec = Fields.object $ do
  eligible <- Fields.required "eligible" (Filter.codec Keyword.codec) AsCopy.eligible
  clauses <- Fields.defaulted "clauses" [] (Common.list (CopyClause.codec abilityCodec)) AsCopy.clauses
  tapped <- Fields.defaulted "tapped" False Common.boolean AsCopy.tapped
  whenYouDo <- Fields.defaulted "whenYouDo" Seq.empty (Common.seq effectCodec) AsCopy.whenYouDo
  zone <- Fields.defaulted "zone" Zone.Type.Battlefield Zone.codec AsCopy.zone
  duration <- Fields.defaulted "duration" Nothing (Common.maybe Duration.codec) AsCopy.duration
  recipient <- Fields.defaulted "recipient" CopyRecipient.Type.ThisObject CopyRecipient.codec AsCopy.recipient
  optional <- Fields.defaulted "optional" True Common.boolean AsCopy.optional
  pure AsCopy.MkAsCopy {AsCopy.eligible = eligible, AsCopy.clauses = clauses, AsCopy.tapped = tapped, AsCopy.whenYouDo = whenYouDo, AsCopy.zone = zone, AsCopy.duration = duration, AsCopy.recipient = recipient, AsCopy.optional = optional}
