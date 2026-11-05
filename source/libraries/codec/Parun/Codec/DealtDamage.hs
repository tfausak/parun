{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DealtDamage where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.CardType as CardType
import qualified Parun.Codec.DamageKind as DamageKind
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DealtDamage as DealtDamage

-- | A bare object keyed by the record's field names, the recipient written with
-- whichever codec its parameter takes. `kind` and `by` are 'Fields.defaulted', so
-- a card watching any damage writes only `recipient`.
codec :: (Typeable.Typeable recipient) => Codec.Codec recipient -> Codec.Codec (DealtDamage.DealtDamage recipient)
codec recipientCodec = Fields.object $ do
  recipient <- Fields.required "recipient" recipientCodec DealtDamage.recipient
  kind <- Fields.defaulted "kind" Nothing (Common.maybe DamageKind.codec) DealtDamage.kind
  by <- Fields.defaulted "by" Nothing (Common.maybe CardType.codec) DealtDamage.by
  pure DealtDamage.MkDealtDamage {DealtDamage.recipient = recipient, DealtDamage.kind = kind, DealtDamage.by = by}
