{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CardAbilities where

import qualified Parun.Codec.ActivationRestriction as ActivationRestriction
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.LentCards as LentCards
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CardAbilities as CardAbilities
import qualified Parun.Types.LentCards as LentCards.Type

-- | A bare object keyed by the record's field names; `from` defaults to exile and
-- `restrictions` to none.
codec :: Codec.Codec CardAbilities.CardAbilities
codec = Fields.object $ do
  from <- Fields.defaulted "from" LentCards.Type.InExile LentCards.codec CardAbilities.from
  cards <- Fields.required "cards" (Filter.codec Keyword.codec) CardAbilities.cards
  restrictions <- Fields.defaulted "restrictions" [] (Common.list ActivationRestriction.codec) CardAbilities.restrictions
  pure CardAbilities.MkCardAbilities {CardAbilities.from = from, CardAbilities.cards = cards, CardAbilities.restrictions = restrictions}
