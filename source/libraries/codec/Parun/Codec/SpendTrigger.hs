{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.SpendTrigger where

import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.TriggeredAbility as TriggeredAbility
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.SpendTrigger as SpendTrigger

-- | Game state, so every key is required, Parun.Codec.ManaUnit's reason.
codec :: Codec.Codec SpendTrigger.SpendTrigger
codec = Fields.object $ do
  casts <- Fields.required "casts" (Filter.codec Keyword.codec) SpendTrigger.casts
  ability <- Fields.required "ability" (TriggeredAbility.codec Card.codec (GrantedAbility.codec Card.codec)) SpendTrigger.ability
  source <- Fields.required "source" ObjectId.codec SpendTrigger.source
  controller <- Fields.required "controller" PlayerId.codec SpendTrigger.controller
  pure
    SpendTrigger.MkSpendTrigger
      { SpendTrigger.casts = casts,
        SpendTrigger.ability = ability,
        SpendTrigger.source = source,
        SpendTrigger.controller = controller
      }
