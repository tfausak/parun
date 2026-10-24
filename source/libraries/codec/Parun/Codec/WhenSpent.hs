{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.WhenSpent where

import qualified Parun.Codec.AbilityName as AbilityName
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.WhenSpent as WhenSpent

-- | Both keys required: every printing names the spells it watches, and the
-- ability is the whole point.
codec :: Codec.Codec WhenSpent.WhenSpent
codec = Fields.object $ do
  casts <- Fields.required "casts" (Filter.codec Keyword.codec) WhenSpent.casts
  ability <- Fields.required "ability" AbilityName.codec WhenSpent.ability
  pure WhenSpent.MkWhenSpent {WhenSpent.casts = casts, WhenSpent.ability = ability}
