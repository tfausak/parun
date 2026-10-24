{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.FaceDownCharacteristics where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Power as Power
import qualified Parun.Codec.Toughness as Toughness
import qualified Parun.Codec.TypeLine as TypeLine
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.FaceDownCharacteristics as FaceDownCharacteristics

-- | Every key is DEFAULTED to CR 708.2a's value, so a card lists only what its
-- own text lists: "a 2\/2 Cyberman artifact creature" writes a type line and
-- leaves the power and toughness out, and an effect that lists nothing at all
-- writes no object.
--
-- The KEYWORDS key is on the wire for the record's sake rather than for a card's:
-- the only listing that names one is a RULE's -- CR 702.168b's and CR 701.58a's
-- ward {2}, which Parun.Types.FaceDownCharacteristics.disguisedValue mints -- and
-- no printing in the pool lists a keyword for the object it turns face down. A
-- lossy codec would be the alternative, which is worse: the field would decode
-- back empty on a card that did name one.
codec :: (Typeable.Typeable ability, Eq ability) => Codec.Codec ability -> Codec.Codec (FaceDownCharacteristics.FaceDownCharacteristics ability)
codec abilityCodec = Fields.object $ do
  typeLine <- Fields.defaulted "typeLine" (FaceDownCharacteristics.typeLine FaceDownCharacteristics.defaultValue) TypeLine.codec FaceDownCharacteristics.typeLine
  power <- Fields.defaulted "power" (FaceDownCharacteristics.power FaceDownCharacteristics.defaultValue) (Common.maybe Power.codec) FaceDownCharacteristics.power
  toughness <- Fields.defaulted "toughness" (FaceDownCharacteristics.toughness FaceDownCharacteristics.defaultValue) (Common.maybe Toughness.codec) FaceDownCharacteristics.toughness
  keywords <- Fields.defaulted "keywords" (FaceDownCharacteristics.keywords FaceDownCharacteristics.defaultValue) (Common.set Keyword.codec) FaceDownCharacteristics.keywords
  abilities <- Fields.defaulted "abilities" [] (Common.list abilityCodec) FaceDownCharacteristics.abilities
  pure
    FaceDownCharacteristics.MkFaceDownCharacteristics
      { FaceDownCharacteristics.typeLine = typeLine,
        FaceDownCharacteristics.power = power,
        FaceDownCharacteristics.toughness = toughness,
        FaceDownCharacteristics.keywords = keywords,
        FaceDownCharacteristics.abilities = abilities
      }
