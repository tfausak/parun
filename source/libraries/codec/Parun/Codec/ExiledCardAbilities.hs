{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ExiledCardAbilities where

import qualified Parun.Codec.ActivationRestriction as ActivationRestriction
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ExiledCardAbilities as ExiledCardAbilities

-- | A bare object keyed by the record's field names; `restrictions` defaults to
-- none.
codec :: Codec.Codec ExiledCardAbilities.ExiledCardAbilities
codec = Fields.object $ do
  cards <- Fields.required "cards" (Filter.codec Keyword.codec) ExiledCardAbilities.cards
  restrictions <- Fields.defaulted "restrictions" [] (Common.list ActivationRestriction.codec) ExiledCardAbilities.restrictions
  pure ExiledCardAbilities.MkExiledCardAbilities {ExiledCardAbilities.cards = cards, ExiledCardAbilities.restrictions = restrictions}
