{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.ExiledCardAbilities where

import qualified Pawl.Codec.ActivationRestriction as ActivationRestriction
import qualified Pawl.Codec.Filter as Filter
import qualified Pawl.Codec.Keyword as Keyword
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.ExiledCardAbilities as ExiledCardAbilities

-- | A bare object keyed by the record's field names; `restrictions` defaults to
-- none.
codec :: Codec.Codec ExiledCardAbilities.ExiledCardAbilities
codec = Fields.object $ do
  cards <- Fields.required "cards" (Filter.codec Keyword.codec) ExiledCardAbilities.cards
  restrictions <- Fields.defaulted "restrictions" [] (Common.list ActivationRestriction.codec) ExiledCardAbilities.restrictions
  pure ExiledCardAbilities.MkExiledCardAbilities {ExiledCardAbilities.cards = cards, ExiledCardAbilities.restrictions = restrictions}
