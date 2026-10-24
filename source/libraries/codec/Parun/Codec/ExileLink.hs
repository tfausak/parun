{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ExileLink where

import qualified Parun.Codec.AbilityName as AbilityName
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ExileLink as ExileLink

-- | An object keyed by the record's field names; "ability" defaults to Nothing,
-- the unnamed exiling ability.
codec :: Codec.Codec ExileLink.ExileLink
codec = Fields.object $ do
  source <- Fields.required "source" ObjectId.codec ExileLink.source
  ability <- Fields.defaulted "ability" Nothing (Common.maybe AbilityName.codec) ExileLink.ability
  pure ExileLink.MkExileLink {ExileLink.source = source, ExileLink.ability = ability}
