{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.IgnoredAbility where

import qualified Parun.Codec.AbilityName as AbilityName
import qualified Parun.Codec.Expiry as Expiry
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.IgnoredAbility as IgnoredAbility

codec :: Codec.Codec IgnoredAbility.IgnoredAbility
codec = Fields.object $ do
  player <- Fields.required "player" PlayerId.codec IgnoredAbility.player
  source <- Fields.required "source" ObjectId.codec IgnoredAbility.source
  ability <- Fields.required "ability" AbilityName.codec IgnoredAbility.ability
  expiry <- Fields.required "expiry" Expiry.codec IgnoredAbility.expiry
  pure
    IgnoredAbility.MkIgnoredAbility
      { IgnoredAbility.player = player,
        IgnoredAbility.source = source,
        IgnoredAbility.ability = ability,
        IgnoredAbility.expiry = expiry
      }
