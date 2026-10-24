{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CharacteristicPT where

import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CharacteristicPT as CharacteristicPT

-- | A bare object keyed by the record's field names, replacing the
-- @[power, toughness]@ array this payload used to be. A card face's
-- characteristic-defining pair and a projection's alike.
codec :: Codec.Codec CharacteristicPT.CharacteristicPT
codec = Fields.object $ do
  power <- Fields.required "power" Quantity.codec CharacteristicPT.power
  toughness <- Fields.required "toughness" Quantity.codec CharacteristicPT.toughness
  pure
    CharacteristicPT.MkCharacteristicPT
      { CharacteristicPT.power = power,
        CharacteristicPT.toughness = toughness
      }
