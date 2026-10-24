{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Prototype where

import qualified Parun.Codec.ManaCost as ManaCost
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Prototype as Prototype

-- | A bare object keyed by the record's field names, Parun.Codec.Equip's shape.
-- No keyword parameter, unlike that one: CR 718.1's inset frame holds a mana
-- cost and a printed box, neither of which can name a Filter or a Cost.
codec :: Codec.Codec Prototype.Prototype
codec = Fields.object $ do
  cost <- Fields.required "cost" ManaCost.codec Prototype.cost
  power <- Fields.required "power" Common.integer Prototype.power
  toughness <- Fields.required "toughness" Common.integer Prototype.toughness
  pure Prototype.MkPrototype {Prototype.cost = cost, Prototype.power = power, Prototype.toughness = toughness}
