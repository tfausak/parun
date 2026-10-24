{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.HandAction where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.Effect as Effect
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.HandAction as HandAction

-- | Parun.Codec.Clause's shape, minus the two riders a hand action has no room
-- for: CR 103.6 makes the whole window a "may", so there is no Optionality to
-- write, and no rule 103 action states a cost.
codec :: (Typeable.Typeable card, Eq card) => Codec.Codec card -> Codec.Codec (HandAction.HandAction card)
codec cardCodec = Fields.object $ do
  condition <- Fields.defaulted "condition" Nothing (Common.maybe Condition.codec) HandAction.condition
  effects <- Fields.defaulted "effects" [] (Common.list (Effect.codec cardCodec (GrantedAbility.codec cardCodec))) HandAction.effects
  pure
    HandAction.MkHandAction
      { HandAction.condition = condition,
        HandAction.effects = effects
      }
