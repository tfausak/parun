{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.SpecialAction where

import qualified Parun.Codec.AbilityName as AbilityName
import qualified Parun.Codec.Cost as Cost
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AbilityName as AbilityName.Type
import qualified Parun.Types.Cost as Cost.Type
import qualified Parun.Types.Keyword as Keyword.Type
import qualified Parun.Types.SpecialAction as SpecialAction

codec :: Codec.Codec SpecialAction.SpecialAction
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "DiscardThisAnyTime" SpecialAction.DiscardThisAnyTime,
      Arm.payload "IgnoreThisUntilEndOfTurn" ignoreCodec (uncurry SpecialAction.IgnoreThisUntilEndOfTurn) (\x -> case x of SpecialAction.IgnoreThisUntilEndOfTurn n y -> Just (n, y); _ -> Nothing)
    ]

-- CR 116.2d's two payloads, keyed rather than positional: which ability the
-- payment ignores and what it costs.
ignoreCodec :: Codec.Codec (AbilityName.Type.AbilityName, Cost.Type.Cost Keyword.Type.Keyword)
ignoreCodec = Fields.object $ do
  ability <- Fields.required "ability" AbilityName.codec fst
  cost <- Fields.required "cost" (Cost.codec Keyword.codec) snd
  pure (ability, cost)

tagOf :: SpecialAction.SpecialAction -> String
tagOf x = case x of
  SpecialAction.DiscardThisAnyTime {} -> "DiscardThisAnyTime"
  SpecialAction.IgnoreThisUntilEndOfTurn {} -> "IgnoreThisUntilEndOfTurn"
