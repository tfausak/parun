{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AbilityWasActivated where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AbilityWasActivated as AbilityWasActivated

-- | Parun.Codec.SpellWasCopied's shape. Runtime-only, GameEvent serialising
-- transcripts rather than card data.
codec :: Codec.Codec AbilityWasActivated.AbilityWasActivated
codec = Fields.object $ do
  player <- Fields.required "player" PlayerId.codec AbilityWasActivated.player
  ability <- Fields.required "ability" ObjectId.codec AbilityWasActivated.ability
  source <- Fields.required "source" ObjectId.codec AbilityWasActivated.source
  loyalty <- Fields.required "loyalty" Common.boolean AbilityWasActivated.loyalty
  pure
    AbilityWasActivated.MkAbilityWasActivated
      { AbilityWasActivated.player = player,
        AbilityWasActivated.ability = ability,
        AbilityWasActivated.source = source,
        AbilityWasActivated.loyalty = loyalty
      }
