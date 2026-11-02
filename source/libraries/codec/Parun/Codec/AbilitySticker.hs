{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AbilitySticker where

import qualified Data.Map.Strict as Map
import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.CastingPermission as CastingPermission
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AbilitySticker as AbilitySticker

-- | A bare object keyed by the record's field names.
codec :: Codec.Codec AbilitySticker.AbilitySticker
codec = Fields.object $ do
  tickets <- Fields.required "tickets" Common.natural AbilitySticker.tickets
  keywords <- Fields.defaulted "keywords" Map.empty (Common.repeats Keyword.codec) AbilitySticker.keywords
  abilities <- Fields.defaulted "abilities" [] (Common.list (GrantedAbility.codec Card.codec)) AbilitySticker.abilities
  castingPermissions <- Fields.defaulted "castingPermissions" [] (Common.list CastingPermission.codec) AbilitySticker.castingPermissions
  pure
    AbilitySticker.MkAbilitySticker
      { AbilitySticker.tickets = tickets,
        AbilitySticker.keywords = keywords,
        AbilitySticker.abilities = abilities,
        AbilitySticker.castingPermissions = castingPermissions
      }
